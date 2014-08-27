unit xtAmnesiaFuncs;

interface

uses
  types,
  Classes,
  windows,
  Forms,  Contnrs,
  Messages,
  ShellApi,
  plugin,
  pluginutil,
  CallExec,
  mmsystem,
  dialogs,
  Graphics,
  sysUtils,
  masks,
  iniFiles,
  LogWndUnit,
  RegExpr,
  lua,
  xtAmnesiaAddon, xtTimer,
  JSON,
      EncdDecd,
  // Indy
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,IdMultipartFormData, IdCookieManager, Controls;

type
   TBooleanWordType =
      (bwTrue, bwYes, bwOn, bwEnabled, bwOne);

type
  AmnesiaPlugin = record
  author: string;
  name: string;
  version: string;
  code: string;
  enabled: boolean;
  end;


function BoolToStr (AValue: boolean;
                    ABooleanWordType: TBooleanWordType = bwTrue): string;

function LoadAddons(dllName, userPath: string): boolean;
function unLoadAddons: boolean;
//function deInitLua:boolean;
function reLoadAddons: boolean;
function executeString(id: integer; code: string): variant;
function getAddonScriptFileName(id: integer): string;
function callAddonFuncById(addonId: integer; functionName: string; params: array of variant): boolean;
function callAddonEventFunction(functionName: string; params: array of variant): boolean;
procedure saveOptions;
procedure ToggleAddon(id: integer);
procedure ToggleDebugMessages;
procedure SelectActiveAddonId(id: integer);
function GetActiveAddonId: integer;
function GetPluginVersion: string;
function changeAddonPos(curPos, newPos: Integer): boolean;
function getModifiedMessage: string;
procedure clearModifiedMessage;
function isDebugMessagesEnabled: boolean;
function luaStatusToSting(state: byte): string;

//procedure registerLuaFunc(funcName: string; func: lua_CFunction);
//function executeLuaFile(fileName: string): integer;
//function executeLuaString(scriptString: string): integer;
//function luaFunctionExists(MethodName: string): Boolean;
//function callLuaFunc(funcName: string; params: array of variant):boolean;


implementation

uses AddonsWndUnit;

const
  scriptDir = 'Amnesia';

const
   BooleanWord: array [boolean, TBooleanWordType] of string =
      (
       ('false', 'no',  'off', 'disabled', '0'),
       ('true',  'yes', 'on',  'enabled',  '1')
      );


var
  // ************* LUA VARS **********
  _lua :lua_State;
  mainScript:TStringList;

  PLUG_VERSION: string = '0.3.4';

  scriptEditor:string= 'notepad';
  writeLogToFile:boolean = false;
  logFileName:string = 'amnesiaLogFile.txt';

  luaScriptDirectory: string;
  luaLibrary: string;
  userDirectory: string;

  enableDebugMessages: boolean = false;
  eventInProgress: boolean = false;
  modifiedMessage: string;
  messageChanged: boolean;

  Regexpr: TRegExpr;
  cfg: TIniFile;

  AddonsList: TObjectList;
  TimersList: TObjectList;
  //  При обработке какого либо события этой переменной будет присвоен ID аддона,
  //  код которого сейчас будет выполнен
  currentAddonCalledId: integer = 0;


  httpClient:TIdHttp;
  httpCoockie:TIdCookieManager;
  httpParams:TIdMultiPartFormDataStream;

{$REGION 'helper functions'}

procedure DebugLog(msg: string);
begin
  if isDebugMessagesEnabled then
  LogWnd.LogIt('xtDBG: '+msg);
end;

procedure LogError(msg: string);
begin
  LogWnd.LogIt('xtDBG::ERROR: '+msg);
end;

function getModifiedMessage: string;
var
tempstr: string;
begin
  tempstr:=modifiedMessage;
  //modifiedMessage:='';
  DebugLog('sending messsage: "'+tempStr+'"');
  result:=tempStr;
end;

procedure clearModifiedMessage;
begin
  modifiedMessage:='';
end;

function checkIndyControls: boolean;
begin
  DebugLog('checking http controls...');
  try
  if httpClient=nil then
    begin
      httpClient:=TIdHTTP.Create(nil);
      DebugLog('http provider created');
      if httpCoockie=nil then
        begin
          httpCoockie:=TIdCookieManager.Create(httpClient);
          DebugLog('coockie manager created');
        end;
      httpClient.AllowCookies:=true;
      httpClient.CookieManager:=httpCoockie;
      httpClient.HandleRedirects:= true;
    end;
  if httpParams=nil then
  begin
    httpParams:=TIdMultiPartFormDataStream.Create;
    DebugLog('params provider created...');
  end;
  except  on E : Exception do
    begin
    DebugLog('***ERROR while checking/creating http controls: '+E.Message);
    result:=false;
    end;
  end;
  result:=true;
end;

function isDebugMessagesEnabled: boolean;
begin
  result:=enableDebugMessages;
end;

function lua_at_panic(luaVM: lua_State): integer;
begin
     ShowMessage('lua in the panic: '#13+lua_tostring(luaVM,-1)+#13'Application will be closed :(');
     result:=0;
end;

procedure Explode(var a: array of string; Border, S: string);
 var
    S2: string;
   i: Integer;
 begin
   i  := 0;
   S2 := S + Border;
   repeat
     a[i] := Copy(S2, 0,Pos(Border, S2) - 1);
     Delete(S2, 1,Length(a[i] + Border));
     Inc(i);
   until S2 = '';
 end;

function BoolToStr (AValue: boolean; ABooleanWordType: TBooleanWordType = bwTrue): string;
begin
   Result := BooleanWord [AValue, ABooleanWordType];
end;

procedure ReloadAmnesia;
begin
   DebugLog('reloading engine...');
   //deInitLua;
   //openLua(luaLibrary,luaScriptDirectory);
end;

procedure ProcMsgs;
begin
  Application.ProcessMessages;
end;

function writeToFile(fileToWrite: string; msg: string):bool;
var
tFile:TFileStream;
begin
  try
    result:=true;
    if FileExists(fileToWrite) then
      tFile:=TFileStream.Create(fileToWrite,fmOpenWrite)
    else
      tFile:=TFileStream.Create(fileToWrite,fmCreate);

    tFile.Seek(0,soFromEnd);
    tFile.WriteBuffer(Pointer(msg)^,length(msg));
    tFile.Free;
  except
    result:=false;
  end;
end;

function writeLineToFile(fileToWrite: string; msg: string):bool;
var
tFile:TFileStream;
begin
  try
    result:=true;
    if FileExists(fileToWrite) then
      tFile:=TFileStream.Create(fileToWrite,fmOpenWrite)
    else
      tFile:=TFileStream.Create(fileToWrite,fmCreate);

    msg:=msg+#13;
    tFile.Seek(0,soFromEnd);
    tFile.WriteBuffer(Pointer(msg)^,length(msg));
    tFile.Free;
  except
    result:=false;
  end;
end;

function RemoveFile(fileToBeDeleted: string): boolean;
begin
     result:=DeleteFile(fileToBeDeleted);
end;

function IsFileExists(fileName: string): boolean;
begin
     result:=FileExists(fileName);
end;

function getTime(mask: string): string;
begin
  result:=FormatDateTime(mask, Now)
end;


procedure FindFiles(StartFolder, Mask: string; List: TStrings; ScanSubFolders: Boolean = True);
var
  SearchRec: TSearchRec;
  FindResult: Integer;
begin
  List.BeginUpdate;
  try
    StartFolder := IncludeTrailingBackslash(StartFolder);
    FindResult := FindFirst(StartFolder + '*.*', faAnyFile, SearchRec);
    try
      while FindResult = 0 do
        with SearchRec do
        begin
          if (Attr and faDirectory) <> 0 then
          begin
            if ScanSubFolders and (Name <> '.') and (Name <> '..') then
                FindFiles(StartFolder + Name, Mask, List, ScanSubFolders);
          end
          else
          begin
            if MatchesMask(Name, Mask) then
              begin
              DebugLog('Found file: '+StartFolder + Name);
              List.Add(StartFolder + Name);
              ProcMsgs;
              end;
          end;
          FindResult := FindNext(SearchRec);
        end;
    finally
      FindClose(SearchRec);
    end;
  finally
    List.EndUpdate;
  end;
end;



procedure SelectActiveAddonId(id: integer);
begin
  currentAddonCalledId:=id;
end;

function GetActiveAddonId: integer;
begin
  result:=currentAddonCalledId;
end;

{$ENDREGION}

// ******************* EXPORT FUNCTIONS ******************

function l_print(luaVm:lua_State): integer;    cdecl;
begin
  LogWnd.LogIt('LUA: '+lua_tostring(luaVm, -1));
  result:=0;
end;

function l_sendmessage(luaVm:lua_State): integer;    cdecl;
begin
  modifiedMessage:= lua_tostring(luaVm,-1) ;
  messageChanged:=true;
  DebugLog('message to send: "'+modifiedMessage+'"');
  result:=0;
end;


{$REGION 'sys'}
function l_sys_new(luaVm:lua_State): integer;    cdecl;
begin
  lua_pushstring(luaVM,pchar(getTime(lua_tostring(luaVm, -1))));
  result:=1;
end;

function l_sys_gettime(luaVm:lua_State): integer;    cdecl;
begin
  lua_pushstring(luaVM,pchar(getTime(lua_tostring(luaVm, -1))));
  result:=1;
end;

function l_sys_getver(luaVm:lua_State): integer;    cdecl;
begin
  lua_pushstring(luaVm, PChar(PLUG_VERSION));
  result:=1;
end;

function l_sys_wait(luaVm:lua_State): integer;    cdecl;
var
  t: integer;
begin
  t:=lua_tointeger(luaVm,-1);
  DebugLog('going to sleep in '+IntToStr(t)+' seconds');
  Sleep(t);
  result:=0;
end;

function l_sys_doevents(luaVm:lua_State): integer;    cdecl;
begin
  ProcMsgs;
  result:=0;
end;

function l_sys_enabledbg(luaVm:lua_State): integer;    cdecl;
begin
  (addonsList[currentAddonCalledId] as TxtAmnesiaAddon).DebugMessagesEnabled(true);
  //enableDebugMessages := true;
  result:=0;
end;

function l_sys_disabledbg(luaVm:lua_State): integer;    cdecl;
begin
  (addonsList[currentAddonCalledId] as TxtAmnesiaAddon).DebugMessagesEnabled(false);
  //enableDebugMessages:=false;
  result:=0;
end;

function l_sys_isdbgmsgsenabled(luaVm:lua_State): integer;    cdecl;
begin
  lua_pushboolean(luaVm,enableDebugMessages);
  result:=1;
end;

function l_sys_setoption(luaVm: lua_State): integer;    cdecl;
var
option: string;
value: string;
begin
  option:=lua_tostring(luaVm,-2);
  value:=lua_tostring(luaVm,-1);
  DebugLog('sys_setoption: option='+option+', value='+value);
  if option='editor' then scriptEditor:=value;
  if option='logfile' then logFileName:=value;  
  if option='writelogtofile' then writeLogToFile:=StrToBool(value);

  result:=0;
end;

function l_sys_getcmdline(luaVm:lua_State): integer;    cdecl;
var
s: string;
i:integer;
begin
  i:=1;
  while ParamStr(i)<>'' do
  begin
    s:=s+ParamStr(i)+' ';
    inc(i);
  end;
  lua_pushstring(luaVM,PChar(s));
  result:=1;
end;

function l_sys_getcmdlinei(luaVm:lua_State): integer;    cdecl;
var
i:integer;
begin
  i:=lua_tointeger(luaVm,-1);
  lua_pushstring(luaVM,PChar(ParamStr(i)));
  result:=1;
end;

function l_sys_exec(luaVm:lua_State): integer;    cdecl;
var
fileName,params,dir,act:string;
mode:integer;
readstd:boolean;

  tRead, cWrite: cardinal;
  SA: TSecurityAttributes;
  PI: TProcessInformation;
  SI: TStartupInfo;
  sBuff: THandleStream;
  StringBuf: TStringList;
  ret : Cardinal;
  m : TMemoryStream;
  fla : boolean;
  Str: TStrings;
begin
  fileName:=lua_tostring(luaVM,-6);
  params:=lua_tostring(luaVM,-5);
  dir:=lua_tostring(luaVM,-4);
  act:=lua_tostring(luaVM,-3);
  mode:=lua_tointeger(luaVM,-2);
  readstd:=lua_toboolean(luaVM,-1);


  if readstd=true then
  begin
  //Инициализация
  Str:=TStringList.Create;
  SA.nLength:=SizeOf(SECURITY_ATTRIBUTES);
  SA.bInheritHandle:=True;
  SA.lpSecurityDescriptor:=nil;
  if not CreatePipe(tRead, cWrite, @SA, 0) then Exit;
  ZeroMemory(@SI, SizeOf(TStartupInfo));
  SI.cb:=SizeOf(TStartupInfo);
  SI.dwFlags:=STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
  SI.wShowWindow:=mode;
  SI.hStdOutput:=cWrite;
  //Стартуем процесс...
  if CreateProcess(nil, PChar(fileName), nil, nil, True, 0, nil, nil, SI, PI)
  then begin
      Str.Clear();
      sBuff := THandleStream.Create(tRead);
      StringBuf := TStringList.Create();
      m := TMemoryStream.Create;
      repeat
        //Ждем N-дцать минут
        Application.ProcessMessages;
        Ret := WaitForSingleObject(PI.hProcess, 100);
        StringBuf.Clear();
        if sBuff.Size > 0 then
        begin
          fla := (m.Size > 0) and not (PByteArray(m.Memory)^[m.Size - 1] in [13, 10]);
          m.Size := 0;
          m.LoadFromStream(sBuff);
          m.Position := 0;
          StringBuf.LoadFromStream(m); //Помещаем блок в буфер
          if StringBuf.Count > 0 then
          begin
            //Склеиваем разорванную строку
            if (Str.Count > 0) and fla then
            begin
              StringBuf.Strings[0] := Str.Strings[Str.Count-1]+StringBuf.Strings[0];
              Str.Delete(Str.Count-1);
            end;
          end;
          //Добавляем блок из буфера
          Str.AddStrings(StringBuf);
        end;
        //не пуст ли pipe ?
        //PeekNamedPipe(tRead, nil, 0, nil, @dwAvail, nil);
      until (Ret <> WAIT_TIMEOUT);
      m.Free;
      CloseHandle(PI.hProcess);
      CloseHandle(PI.hThread);
  end;       // if CreateProcess
  CloseHandle(tRead);
  CloseHandle(cWrite);
  lua_pushstring(luaVM,PChar(Str.Text));
  result:=1;
  exit;
  end;

ShellExecute(0,PChar(act),PChar(fileName),PChar(params),PChar(dir),mode);
result:=0;
end;
{$ENDREGION}
{$REGION 'file'}
function l_file_append(luaVm:lua_State): integer;    cdecl;
var
r:boolean;
begin
  r:=writeToFile(lua_tostring(luaVm,1),lua_tostring(luaVm,2)) ;
  //showmessage(lua_tostring(_lua,1)+' - '+lua_tostring(_lua,2));
  lua_pushboolean(luaVm,r);
  result:=1;
end;

function l_file_appendln(luaVm:lua_State): integer;    cdecl;
var
r:boolean;
begin
  r:=writeLineToFile(lua_tostring(luaVm,1),lua_tostring(luaVm,2)) ;
  //showmessage(lua_tostring(_lua,1)+' - '+lua_tostring(_lua,2));
  lua_pushboolean(luaVm,r);
  result:=1;
end;

function l_file_exists(luaVm:lua_State): integer;    cdecl;
begin
  lua_pushboolean(luaVm,FileExists(lua_tostring(luaVm,1)));
  result:=1;
end;

function l_file_copy(luaVm:lua_State): integer;    cdecl;
begin
  lua_pushboolean(luaVm,CopyFile(lua_tostring(luaVm,1),lua_tostring(luaVm,2),false));
  result:=0;
end;

function l_file_delete(luaVm:lua_State): integer;    cdecl;
begin
  lua_pushboolean(luaVm,DeleteFile(lua_tostring(luaVm,1)));
  result:=1;
end;

function l_file_run(luaVm:lua_State): integer;    cdecl;
begin
  lua_pushboolean(luaVm,RemoveFile(lua_tostring(luaVm,1)));
  result:=1;
end;

function l_file_find(luaVm:lua_State): integer;    cdecl;
var
  dir: string;
  mask: string;
  filesFound: TStringList;
  fileList: array of string;
  recursive: boolean;
  i: integer;
begin
  dir:=lua_tostring(luaVm,1);
  mask:=lua_tostring(luaVm,2);
  recursive:=lua_toboolean(luaVm,3);

  filesFound:=TStringList.Create;
  FindFiles(dir,mask,filesFound,recursive);

  setLength(fileList,filesFound.Count+1);
  Explode(fileList,#13#10,filesFound.GetText);

  lua_newtable(luaVm);

  for i:=0 to length(fileList)-2 do
  begin
    lua_pushnumber(luaVm,i);
    lua_pushstring(luaVm,PChar(fileList[i]));
    lua_settable(luaVm,-3);
  end;

  setLength(fileList,0);
  filesFound.Destroy;

  result:=1;
end;


{$ENDREGION}
{$REGION 'log'}
function l_log_show(luaVm:lua_State): integer;    cdecl;
begin
  LogWnd.Show;
  result:=0;
end;

function l_log_hide(luaVm:lua_State): integer;    cdecl;
begin
  LogWnd.Hide;
  result:=0;
end;

function l_log_gettext(luaVm:lua_State): integer;    cdecl;
begin
  lua_pushstring(luaVm,PChar(LogWnd.LogText.Text));
  result:=0;
end;

function l_log_clear(luaVm:lua_State): integer;    cdecl;
begin
  LogWnd.LogText.Lines.Clear;
  result:=0;
end;

function l_log_saveto(luaVm:lua_State): integer;    cdecl;
begin
  LogWnd.LogText.Lines.SaveToFile(lua_tostring(luaVm,-1));
  result:=0;
end;
{$ENDREGION}
{$REGION 'rnq'}
function l_icq_sendmsg(luaVm:lua_State): integer;    cdecl;
begin
  DebugLog('icq_sendmsg: '+lua_tostring(luaVm,-2)+': '+lua_tostring(luaVm,-1));
  RQ_SendMsg(lua_tointeger(luaVm,-2),0,lua_tostring(luaVm,-1));
  result:=0;
end;

function l_icq_senaddedyou(luaVm:lua_State): integer;    cdecl;
begin
  DebugLog('icq_senaddedyou: '+lua_tostring(luaVm,-1));
  RQ_SendAddedYou(lua_tointeger(luaVm,-1));
  result:=0;
end;

function l_icq_setstatus(luaVm:lua_State): integer;    cdecl;
var
state: string;
begin
  state:=lua_tostring(luaVm,-1);
  DebugLog('icq_setstatus: '+state);
  if state=LowerCase('online') then RQ_SetStatus(PS_ONLINE);
  if state=LowerCase('occupied') then RQ_SetStatus(PS_OCCUPIED);
  if state=LowerCase('dnd') then RQ_SetStatus(PS_DND);
  if state=LowerCase('na') then RQ_SetStatus(PS_NA);
  if state=LowerCase('away') then RQ_SetStatus(PS_AWAY);
  if state=LowerCase('freeforchat') then RQ_SetStatus(PS_F4C);
  if state=LowerCase('offline') then RQ_SetStatus(PS_OFFLINE);
  if state=LowerCase('unknown') then RQ_SetStatus(PS_UNKNOWN);
  if state=LowerCase('evil') then RQ_SetStatus(PS_EVIL);
  if state=LowerCase('depression') then RQ_SetStatus(PS_DEPRESSION);
  result:=0;
end;

function l_icq_setvisibility(luaVm:lua_State): integer;    cdecl;
var
state: string;
begin
  state:=lua_tostring(luaVm,-1);
  DebugLog('icq_setvisibility: '+state);
  if state=LowerCase('invisible') then RQ_SetVisibility(PV_INVISIBLE);
  if state=LowerCase('privacy') then RQ_SetVisibility(PV_PRIVACY);
  if state=LowerCase('normal') then RQ_SetVisibility(PV_NORMAL);
  if state=LowerCase('all') then RQ_SetVisibility(PV_ALL);
  if state=LowerCase('contacts') then RQ_SetVisibility(PV_CL);
  result:=0;
end;

function l_icq_quit(luaVm:lua_State): integer;    cdecl;
begin
  DebugLog('icq_quit');
  RQ_Quit;
  result:=0;
end;

function l_icq_connect(luaVm:lua_State): integer;    cdecl;
begin
  DebugLog('icq_connect');
  RQ_Connect;
  result:=0;
end;

function l_icq_disconnect(luaVm:lua_State): integer;    cdecl;
begin
  DebugLog('icq_disconnect');
  RQ_Disconnect;
  result:=0;
end;

function l_icq_getconnectionstate(luaVm:lua_State): integer;    cdecl;
var
state:byte;
begin
  state:=RQ_GetConnectionState;
  DebugLog('icq_getconnectionstate:  '+IntToStr(state));
  if state=PCS_DISCONNECTED then lua_pushstring(luaVm,'disconnected');
  if state=PCS_CONNECTED then lua_pushstring(luaVm,'connected');
  if state=PCS_CONNECTING then lua_pushstring(luaVm,'connecting');
  result:=1;
end;

function l_icq_setautomsg(luaVm:lua_State): integer;    cdecl;
var
state:string;
begin
  state:=lua_tostring(luaVm,-1);
  DebugLog('icq_setautomsg:  '+state);
  RQ_SetAutoMessage(state);
  result:=0;
end;

function l_icq_sendautomsgreq(luaVm:lua_State): integer;    cdecl;
var
uin:integer;
begin
  uin:=lua_tointeger(luaVm,-1);
  DebugLog('icq_sendautomsgreq: to '+IntToStr(uin));
  RQ_SendAutoMessageRequest(uin);
  result:=0;
end;

function l_icq_getdisplayednamefor(luaVm:lua_State): integer;    cdecl;
var
uin:integer;
name:string;
begin
  uin:=lua_tointeger(luaVm,-1);
  name:=RQ_GetDisplayedName(uin);
  DebugLog('icq_getdisplayednamefor: '+IntToStr(uin)+' is '+name);
  lua_pushstring(luaVm,PChar(name));
  result:=1;
end;

function l_icq_getuserpath(luaVm:lua_State): integer;    cdecl;
begin
  DebugLog('icq_getuserpath: '+RQ_GetUserPath);
  lua_pushstring(luaVm,PChar(RQ_GetUserPath));
  result:=1;
end;

function l_icq_getrnqpath(luaVm:lua_State): integer;    cdecl;
begin
  DebugLog('icq_getrnqpath: '+RQ_GetAndrqPath);
  lua_pushstring(luaVm,PChar(RQ_GetAndrqPath));
  result:=1;
end;

function l_icq_getautomsg(luaVm:lua_State): integer;    cdecl;
begin
  DebugLog('icq_getautomsg: '+RQ_GetAutoMessage);
  lua_pushstring(luaVm,PChar(RQ_GetAutoMessage));
  result:=1;
end;

function l_icq_getchatuin(luaVm:lua_State): integer;    cdecl;
begin
  DebugLog('icq_getchatuin: '+IntToStr(RQ_GetChatUIN));
  lua_pushinteger(luaVm,RQ_GetChatUIN);
  result:=1;
end;

function luaStatusToSting(state: byte): string;
var
strState:string;
begin
  if state=PS_ONLINE  then strState:='online';
  if state=PS_OCCUPIED  then strState:='occupied';
  if state=PS_DND  then strState:='dnd';
  if state=PS_NA  then strState:='na';
  if state=PS_AWAY  then strState:='away';
  if state=PS_F4C  then strState:='freeforchat';
  if state=PS_OFFLINE  then strState:='offline';
  if state=PS_UNKNOWN  then strState:='unknown';
  if state=PS_EVIL  then strState:='evil';
  if state=PS_DEPRESSION  then strState:='depression';
  DebugLog('resuesting state ['+intToStr(state)+'] as string - '+strState);
  if Length(strState)=0 then
    result:='undefined'
  else
  result:=strState;
end;

function l_icq_getstatus(luaVm:lua_State): integer;    cdecl;
var
state:integer;
begin
  state:=RQ_GetStatus;
  DebugLog('icq_getstatus: '+IntToStr(state));
  lua_pushstring(luaVm,PChar(luaStatusToSting(state)));
  result:=1;
end;

function luaFillContactsTable(luaVm:lua_state; arr:TIntegerDynArray): integer; cdecl;
var
i:integer;
begin
  if Length(arr)<=0 then
  begin
  result:=0;
  exit;
  end;

  DebugLog('fill table...');
  lua_newtable(luaVm);
  for i:=0 to length(arr)-1 do
  begin
    lua_pushnumber(luaVm,i);
    lua_pushinteger(luaVm,arr[i]);
    lua_settable(luaVm,-3);
    DebugLog('added ['+intToStr(i)+'] - '+IntToStr(arr[i])+' is '+RQ_GetDisplayedName(arr[i]));
  end;
  result:=1;
end;

function l_icq_getcontacts(luaVm:lua_State): integer;    cdecl;
var
mode: string;
begin
  mode:=lua_tostring(luaVm,-1);
  DebugLog('icq_getcontacts: mode='+mode);
  {
  PL_ROASTER, PL_VISIBLELIST, PL_INVISIBLELIST, PL_TEMPVISIBLELIST,
  PL_IGNORELIST, PL_DB, PL_NIL.
}
  if mode='all'  then  luaFillContactsTable(luaVm, RQ_GetList(PL_ROASTER));
  if mode='visible'  then  luaFillContactsTable(luaVm, RQ_GetList(PL_VISIBLELIST));
  if mode='invisible'  then  luaFillContactsTable(luaVm, RQ_GetList(PL_INVISIBLELIST));
  if mode='tempvisible'  then  luaFillContactsTable(luaVm, RQ_GetList(PL_TEMPVISIBLELIST));
  if mode='ignored'  then  luaFillContactsTable(luaVm, RQ_GetList(PL_IGNORELIST));
  if mode='db'  then  luaFillContactsTable(luaVm, RQ_GetList(PL_DB));

  result:=1;
end;

function l_icq_getcontactinfo(luaVm:lua_State): integer;    cdecl;
var
ci: ContactInfo;
uin: integer;
begin
  uin:=lua_tointeger(luaVm,-1);
  DebugLog('icq_getcontactinfo: uin='+intToStr(uin));
  ci:=RQ_GetContactInfo(uin);
  {
   UIN:integer;
   Status:byte;
   Invisible:boolean;
   DisplayedName, First, Last:string
   }
  lua_newtable(luaVm);
  begin
    lua_pushstring(luaVm,PChar('uin'));
    lua_pushinteger(luaVm,ci.UIN);
    lua_settable(luaVm,-3);
    DebugLog('uin: '+IntTOStr(ci.uin));

    lua_pushstring(luaVm,PChar('status'));
    lua_pushstring(luaVm,PChar(luaStatusToSting(ci.Status)));
    lua_settable(luaVm,-3);
    DebugLog('status: '+IntTOStr(ci.Status));

    lua_pushstring(luaVm,PChar('invisible'));
    lua_pushboolean(luaVm,ci.Invisible);
    lua_settable(luaVm,-3);
    DebugLog('invisible: '+BoolToStr(ci.Invisible));

    lua_pushstring(luaVm,PChar('name'));
    lua_pushstring(luaVm,PChar(ci.DisplayedName));
    lua_settable(luaVm,-3);
    DebugLog('name: '+ci.DisplayedName);

    lua_pushstring(luaVm,PChar('firstname'));
    lua_pushstring(luaVm,PChar(ci.First));
    lua_settable(luaVm,-3);
    DebugLog('first: '+ci.first);

    lua_pushstring(luaVm,PChar('lastname'));
    lua_pushstring(luaVm,PChar(ci.Last));
    lua_settable(luaVm,-3);
    DebugLog('last: '+ci.last);
  end;
   DebugLog('--- end ---');
  result:=1;
end;
{$ENDREGION}
{$REGION 'ini'}
function l_ini_get(luaVm:lua_State): integer;    cdecl;
var
cfg:TIniFile;
fileName,section,key,value: string;
begin
  fileName:=lua_tostring(luaVm,-3);
  section:=lua_tostring(luaVm,-2);
  key:=lua_tostring(luaVm,-1);
  DebugLog('ini_get: file: '+fileName+', section: '+section+', key: '+key);
  cfg:=TIniFile.Create(fileName);
  value:=cfg.ReadString(section,key,'');
  cfg.Free;
  lua_pushstring(luaVm,PChar(value));
  result:=1;
end;

function l_ini_set(luaVm:lua_State): integer;    cdecl;
var
cfg:TIniFile;
fileName,section,key,value: string;
begin
  fileName:=lua_tostring(luaVm,-4);
  section:=lua_tostring(luaVm,-3);
  key:=lua_tostring(luaVm,-2);
  value:=lua_tostring(luaVm,-1);
  DebugLog('ini_set: file: '+fileName+', section: '+section+', key: '+key+', value: '+value);
  cfg:=TIniFile.Create(fileName);
  cfg.WriteString(section,key,value);
  cfg.UpdateFile;
  cfg.Free;
  result:=0;
end;
{$ENDREGION}
{$REGION 'regex'}
function l_regex_match(luaVm:lua_State): integer;    cdecl;
begin
  DebugLog('regex_match: expression='+lua_tostring(luaVm, -1)+', string='+lua_tostring(luaVm, -2));
  if Regexpr=nil then
  Regexpr:=TRegExpr.Create;
  RegExpr.Expression:=lua_tostring(luaVm, -1);
  if Regexpr.Exec(lua_tostring(luaVm, -2)) then
    begin
      DebugLog('expression MATCH');
      lua_pushboolean(luaVm,true);
    end
    else
    begin
      DebugLog('expression NOT MATCH');
      lua_pushboolean(luaVm,true);
    end;

  result:=1;
end;

function l_regex_replace(luaVm:lua_State): integer;    cdecl;
var
expression, str, replace: string;
begin
  expression:=lua_tostring(luaVm, -1);
  replace:=lua_tostring(luaVm, -2);
  str:=lua_tostring(luaVm, -3);
  DebugLog('regex_replace: expression='+expression+', string='+str+', replace with='+replace);

  if Regexpr=nil then
  Regexpr:=TRegExpr.Create;
  RegExpr.Expression:=expression;
  str:=Regexpr.Replace(str,replace,false);
  DebugLog('replace expression result='+str);
  lua_pushstring(luaVm,pchar(str));

  result:=1;
end;

function l_regex_get(luaVm:lua_State): integer;    cdecl;
var
expression, str: string;
i: integer;
begin
  expression:=lua_tostring(luaVm, -1);
  str:=lua_tostring(luaVm, -2);
  i:=0;
  DebugLog('regex_get: expression='+expression+', string='+str);

  if Regexpr=nil then
  Regexpr:=TRegExpr.Create;
  RegExpr.Expression:=expression;

  lua_newtable(luaVm);

  if RegExpr.Exec(str) then
  begin
    REPEAT
      lua_pushinteger(luaVm,i);
      lua_pushstring(luaVm,PChar(RegExpr.Match [0]));
      lua_settable(luaVm,-3);
      inc(i);
    UNTIL not RegExpr.ExecNext;
  end;
  DebugLog('regex get items='+IntToStr(i));

  result:=1;
end;

function l_regex_setmode(luaVm:lua_State): integer;    cdecl;
var
mode: string;
begin
  try
  mode:=lua_tostring(luaVm, -1);
  if Regexpr=nil then
  Regexpr:=TRegExpr.Create;

  DebugLog('regex_setmode: mode='+mode);
  RegExpr.ModifierStr:=mode;
  except on E : Exception do
  DebugLog('regex_setmode: ERROR: '+E.Message);
  end;

  result:=0;
end;

function l_regex_getmode(luaVm:lua_State): integer;    cdecl;
var
mode: string;
begin
  try
  if Regexpr=nil then
  Regexpr:=TRegExpr.Create;

  mode:=Regexpr.ModifierStr;
  DebugLog('regex_getmode: mode='+mode);
  except on E : Exception do
  DebugLog('regex_setmode: ERROR: '+E.Message);
  end;
  lua_pushstring(luaVm,PChar(mode));

  result:=1;
end;
{$ENDREGION}
{$REGION 'http'}
function l_http_get(luaVm:lua_State): integer;    cdecl;
var
url,res: string;
begin
  if not checkIndyControls then
    begin
      DebugLog('Some error occurred while checking http controls');
      result:=0;
    end;
  url:=lua_tostring(luaVm,-1);
  DebugLog('http_get: url='+url);
  res:=httpClient.Get(url);
  lua_pushstring(luaVm,PChar(res));
  result:=1;
end;

function l_http_post(luaVm:lua_State): integer;    cdecl;
var
url,res: string;
begin
  if not checkIndyControls then
    begin
      DebugLog('Some error occurred while checking http controls');
      result:=0;
    end;
  url:=lua_tostring(luaVm,-1);
  DebugLog('http_post: url='+url);
  res:=httpClient.Post(url,httpParams);
  lua_pushstring(luaVm,PChar(res));
  result:=1;
end;

function l_http_addparam(luaVm:lua_State): integer;    cdecl;
var
param,value: string;
begin
  if not checkIndyControls then
    begin
      DebugLog('Some error occurred while checking http controls');
      result:=0;
    end;
  param:=lua_tostring(luaVm,-2);
  value:=lua_tostring(luaVm,-1);
  DebugLog('http_addparam: parameter='+param+', value='+value);
  lua_pushinteger(luaVm,httpParams.Size);
  result:=1;
end;

function l_http_clear(luaVm:lua_State): integer;    cdecl;
begin
  DebugLog('http_clear');
  httpCoockie.Free;
  httpClient.Free;
  httpParams.Free;
  result:=0;
end;

{$ENDREGION}
{$REGION 'base64'}
function l_base64_enc(luaVm:lua_State): integer;    cdecl;
var
text: string;
begin
  text:=lua_tostring(luaVm,-1);
  DebugLog('base64_enc: url='+text);
  lua_pushstring(luaVm,PChar(EncodeString(text)));
  result:=1;
end;

function l_base64_dec(luaVm:lua_State): integer;    cdecl;
var
text64: string;
begin
  text64:=lua_tostring(luaVm,-1);
  DebugLog('base64_dec: url='+text64);
  lua_pushstring(luaVm,PChar(DecodeString(text64)));
  result:=1;
end;
 {$ENDREGION}
{$REGION 'timers'}
function l_timers_new(luaVm:lua_State): integer;    cdecl;
var
  newTimer: TxtTimer;
  i: integer;
begin
  DebugLog('new timer with name '+lua_tostring(luaVm,-3));
  for i:=0 to TimersList.Count - 1 do
  begin
    if (TimersList[i] as TxtTimer).Name = lua_tostring(luaVm,-3) then
    begin
      DebugLog('  new timer with name '+lua_tostring(luaVm,-3)+' already exists!');
      result:=0;
      exit;
    end;
  end;
  newTimer := TxtTimer.Create(lua_tostring(luaVm,-3), lua_tostring(luaVm,-2),lua_tointeger(luaVm, -1), GetActiveAddonId);
  DebugLog('new_timer: '+newTimer.Name+', '+newTimer.FunctionName+', '+intToStr(lua_tointeger(luaVm, -1))+' > ('+IntToStr(GetActiveAddonId)+') '+(addonsList[GetActiveAddonId] as TxtAmnesiaAddon).addonName);
  newTimer.TakeAddon((addonsList[GetActiveAddonId] as TxtAmnesiaAddon));
  newTimer.Start;
  TimersList.Add(newTimer);
  lua_pushinteger(luaVm, TimersList.Count-1);
  result:=1;
end;

function l_timers_kill(luaVm:lua_State): integer; cdecl;
var
i:integer;
timerName: string;
begin
  timerName := lua_tostring(luaVm, -1);
  lua_pushinteger(luaVm, -1);
  result:=0;
  DebugLog('kill timer name '+timerName);
  for i:=TimersList.Count -1 downto 0  do
  if (TimersList[i] as TxtTimer).Name = timerName then
  begin
     (TimersList[i] as TxtTimer).Kill;
     TimersList.Delete(i);
     lua_pushinteger(luaVm, i);
     result:=1
  end;

end;

function l_timers_start(luaVm:lua_State): integer; cdecl;
var
i:integer;
timerName: string;
begin
  timerName := lua_tostring(luaVm, -1);
  DebugLog('start timer name '+timerName);
  lua_pushinteger(luaVm, -1);
  result:=0;

  for i:=TimersList.Count -1 downto 0  do
  if (TimersList[i] as TxtTimer).Name = timerName then
  begin
     (TimersList[i] as TxtTimer).Start;
     lua_pushinteger(luaVm, i);
     result:=1
  end;
end;

function l_timers_setinterval(luaVm:lua_State): integer; cdecl;
var
i:integer;
timerName: string;
interval: integer;
begin
  timerName := lua_tostring(luaVm, -2);
  interval := lua_tointeger(luaVm, -1);
  DebugLog('start timer name '+timerName);
  lua_pushinteger(luaVm, -1);
  result:=0;

  for i:=TimersList.Count -1 downto 0  do
  if (TimersList[i] as TxtTimer).Name = timerName then
  begin
     (TimersList[i] as TxtTimer).Start(interval);
     lua_pushinteger(luaVm, i);
     result:=1
  end;
end;

function l_timers_stop(luaVm:lua_State): integer; cdecl;
var
i:integer;
timerName: string;
begin
  timerName := lua_tostring(luaVm, -1);
  DebugLog('stop timer name '+timerName);
  lua_pushinteger(luaVm, -1);
  for i:=TimersList.Count -1 downto 0  do
  if (TimersList[i] as TxtTimer).Name = timerName then
  begin
     (TimersList[i] as TxtTimer).Stop;
     lua_pushinteger(luaVm, i);
     result:=0
  end;

result:=1;
end;

function l_timers_getname(luaVm:lua_State): integer; cdecl;
var
timerId: integer;
begin
  timerId := lua_tointeger(luaVm, -1);
  if (timerId < TimersList.Count) and (timerId >=0) then
  lua_pushstring(luaVm, pchar((TimersList[timerId] as TxtTimer).Name))
  else
  lua_pushstring(luaVm, 'undefined');
result:=1;
end;

function l_timers_getcount(luaVm:lua_State): integer; cdecl;
begin
  lua_pushinteger(luaVm, TimersList.Count);
result:=1;
end;
{$ENDREGION}
// ******************* EXPORT STRUCTURES *****************
{$REGION 'syslib'}
const
  syslib: array [0..12] of lual_reg = (
   (name:'new';func:l_sys_new),
   (name:'exec';func:l_sys_exec),
   (name:'gettime';func:l_sys_gettime),
   (name:'getversion';func:l_sys_getver),
   (name:'getcmdline';func:l_sys_getcmdline),
   (name:'getcmdlinei';func:l_sys_getcmdlinei),
   (name:'wait';func:l_sys_wait),
   (name:'doevents';func:l_sys_doevents),
   (name:'enabledebugmessages';func:l_sys_enabledbg),
   (name:'disabledebugmessages';func:l_sys_disabledbg),
   (name:'isdebugmessagesenabled';func:l_sys_isdbgmsgsenabled),
   (name:'setoption';func:l_sys_setoption),
   (name:nil;func:nil)
   );
{$ENDREGION}
{$REGION 'filesys'}
const
  filesys: array [0..7] of lual_reg = (
   (name:'append';func:l_file_append),
   (name:'appendln';func:l_file_appendln),
   (name:'exists';func:l_file_exists),
   (name:'copy';func:l_file_copy),
   (name:'delete';func:l_file_delete),
   (name:'run';func:l_file_run),
   (name:'find';func:l_file_find),
   (name:nil;func:nil)
   );
{$ENDREGION}
{$REGION 'logsys'}
const
  logsys: array [0..5] of lual_reg = (
   (name:'show';func:l_log_show),
   (name:'hide';func:l_log_hide),
   (name:'gettext';func:l_log_gettext),
   (name:'clear';func:l_log_clear),
   (name:'saveto';func:l_log_saveto),
   (name:nil;func:nil)
   );
{$ENDREGION}
{$REGION 'rnqsys'}
const
  rnqsys: array [0..18] of lual_reg = (
   (name:'sendmsg';func:l_icq_sendmsg),
   (name:'sendaddedyou';func:l_icq_senaddedyou),
   (name:'setstatus';func:l_icq_setstatus),
   (name:'setvisibility';func:l_icq_setvisibility),
   (name:'quit';func:l_icq_quit),
   (name:'connect';func:l_icq_connect),
   (name:'disconnect';func:l_icq_disconnect),
   (name:'getconnectionstate';func:l_icq_getconnectionstate),
   (name:'setautomsg';func:l_icq_setautomsg),
   (name:'sendautomsgreq';func:l_icq_sendautomsgreq),
   (name:'getdisplayednamefor';func:l_icq_getdisplayednamefor),
   (name:'getuserpath';func:l_icq_getuserpath),
   (name:'getrnqpath';func:l_icq_getrnqpath),
   (name:'getautomsg';func:l_icq_getautomsg),
   (name:'getchatuin';func:l_icq_getchatuin),
   (name:'getstatus';func:l_icq_getstatus),
   (name:'getcontacts';func:l_icq_getcontacts),
   (name:'getcontactinfo';func:l_icq_getcontactinfo),
   (name:nil;func:nil)
   );
{$ENDREGION}
{$REGION 'inisys'}
const
  inisys: array [0..2] of lual_reg = (
   (name:'get';func:l_ini_get),
   (name:'set';func:l_ini_set),
   (name:nil;func:nil)
   );
{$ENDREGION}
{$REGION 'regexsys'}
const
  regexsys: array [0..5] of lual_reg = (
   (name:'match';func:l_regex_match),
   (name:'replace';func:l_regex_replace),
   (name:'get';func:l_regex_get),
   (name:'setmode';func:l_regex_setmode),
   (name:'getmode';func:l_regex_getmode),
   (name:nil;func:nil)
   );
{$ENDREGION}
{$REGION 'httpsys'}
const
  httpsys: array [0..4] of lual_reg = (
   (name:'get';func:l_http_get),
   (name:'post';func:l_http_post),
   (name:'addparam';func:l_http_addparam),
   (name:'clear';func:l_http_clear),
   (name:nil;func:nil)
   );
{$ENDREGION}
{$REGION 'base64sys'}
const
  base64sys: array [0..2] of lual_reg = (
   (name:'enc';func:l_base64_enc),
   (name:'dec';func:l_base64_dec),
   (name:nil;func:nil)
   );
{$ENDREGION}
{$REGION 'timerssys'}
const
  timersys: array [0..6] of lual_reg = (
   (name:'new';func:l_timers_new),
   (name:'kill';func:l_timers_kill),
   (name:'start';func:l_timers_start),
   (name:'stop';func:l_timers_stop),
   (name:'getcount';func:l_timers_getcount),
   (name:'getname';func:l_timers_getname),
   (name:nil;func:nil)
   );
{$ENDREGION}
function registerSysToLua(luaVm: lua_state): boolean;
begin
  luaL_register(luaVm, 'sys', @syslib);
  luaL_newmetatable(luaVm,'sys');
  luaL_register(luaVm, 'file', @filesys);
  luaL_newmetatable(luaVm,'file');
  luaL_register(luaVm, 'log', @logsys);
  luaL_newmetatable(luaVm,'log');
  luaL_register(luaVm, 'rnq', @rnqsys);
  luaL_newmetatable(luaVm,'rnq');
  luaL_register(luaVm, 'ini', @inisys);
  luaL_newmetatable(luaVm,'ini');
  luaL_register(luaVm, 'regex', @regexsys);
  luaL_newmetatable(luaVm,'regex');
  luaL_register(luaVm, 'http', @httpsys);
  luaL_newmetatable(luaVm,'http');
  luaL_register(luaVm, 'base64', @base64sys);
  luaL_newmetatable(luaVm,'base64');
  luaL_register(luaVm, 'timers', @timersys);
  luaL_newmetatable(luaVm,'timers');
  result:=true;
end;

function changeAddonPos(curPos, newPos: Integer): boolean;
var
  i:integer;
begin
  addonsList.Move(curPos, newPos);
  saveOptions;
end;

procedure saveOptions;
var
  i:integer;
begin
  try
    cfg:=TIniFile.Create(userDirectory+'Amnesia\config.inf');
    for I := 0 to addonsList.Count - 1 do
    begin
      DebugLog('Saving '+(addonsList[i] as TxtAmnesiaAddon).addonName+', pos: '+IntToStr(i));
      cfg.WriteInteger('order',(addonsList[i] as TxtAmnesiaAddon).addonShortName,i);
      cfg.WriteBool('enabled',(addonsList[i] as TxtAmnesiaAddon).addonShortName,(addonsList[i] as TxtAmnesiaAddon).enabled);
    end;
    cfg.Destroy;
  except
    LogError('Can''t save addons order!');
  end;
end;

function getAddonId(Name: string): integer;
var
  i: integer;
begin
  for I := 0 to addonsList.Count - 1 do
  begin
    if (addonsList[i] as TxtAmnesiaAddon).addonName = Name then
      result:= i;
  end;
  result:= -1;
end;

procedure ToggleAddon(id: integer);
begin
  try
   (addonsList[id] as TxtAmnesiaAddon).enabled := not (addonsList[id] as TxtAmnesiaAddon).enabled;
    cfg:=TIniFile.Create(userDirectory+'Amnesia\config.inf');
    cfg.WriteBool('enabled',(addonsList[id] as TxtAmnesiaAddon).addonShortName,(addonsList[id] as TxtAmnesiaAddon).enabled);
    cfg.Destroy;
  except
    LogError('Can''t save addons mode! :(');
  end;
end;

procedure ToggleDebugMessages;
begin
  enableDebugMessages := not enableDebugMessages;
end;


function GetPluginVersion: string;
begin
  result:=PLUG_VERSION;
end;

function LoadAddons(dllName, userPath: string): boolean;
var
  addon, tmpAddon: TxtAmnesiaAddon;
  tmpLuaState: lua_State;
  sl:TStringList;
  i,x,z:integer;
  enabled:boolean;
  tmpList: TObjectList;
begin
  try
  luaLibrary:=dllName;
  userDirectory:=userPath;
  sl:=TStringList.Create;
  sl.Clear;

  TimersList:= TObjectList.Create;
  TimersList.Clear;

  addonsList:=TObjectList.Create;
  addonsList.Clear;

  tmpList := TObjectList.Create;
  tmpList.Clear;

  cfg:=TIniFile.Create(userDirectory+'Amnesia\config.inf');
  DebugLog('Searching addons in: '+userPath+'Amnesia\');
  FindFiles(userPath+'Amnesia\','amnesia.inf',sl,true);
  if sl.Count=0 then
    begin
    DebugLog('No addons found...');
    exit;
    end;
  for i:=0 to sl.Count-1 do
  begin

    DebugLog('Loading addon ['+IntToStr(i)+'/'+IntToStr(sl.Count-1)+'] from: '+ExtractFileDir(sl[i])+'\');
    addon:=TxtAmnesiaAddon.Create(dllName,userPath,ExtractFileDir(sl[i])+'\',i);
    registerSysToLua(addon.LuaState);
    addon.RegisterAddonFunction('print',l_print);
    addon.RegisterAddonFunction('echo',l_print);
    addon.RegisterAddonFunction('gettime',l_sys_gettime);
    addon.RegisterAddonFunction('sendmessage',l_sendmessage);
    addon.enabled:=cfg.ReadBool('enabled',addon.addonShortName,true);
    addon.addonId := cfg.ReadInteger('order',addon.addonShortName,0);
    addon.Start;
    tmpList.Add(addon);
    DebugLog('.. Addon '+addon.addonShortName+' loaded with order num '+IntToStr(addon.addonId));
  end;

  // sorting
  for i := 0 to tmpList.Count - 1 do
  begin
    for z  := 0 to tmpList.Count - 1 do
    begin
      if (tmpList[z] as TxtAmnesiaAddon).addonId = i then
      begin
        tmpAddon := (tmpList[z] as TxtAmnesiaAddon);
        AddonsList.Add(tmpAddon);
        LogWnd.addonList.AddItem(tmpAddon.addonName,nil);
        AddonsWnd.AddonAdd(tmpAddon.addonName);
        if tmpAddon.enabled then
        begin
          AddonsWnd.addonsList.Checked[AddonsWnd.addonsList.Count-1]:=true;
        end;
        DebugLog('.. Added '+tmpAddon.addonShortName+' as '+IntToStr(i));
        //tmpList.Delete(z);
      end;
    end;
  end;

  //
  tmpList.OwnsObjects := false;
  tmpList.Free;


    SelectActiveAddonId(0);

  except on E:Exception do
    LogError('Error while loading addon: '+E.Message);
  end;
end;

function unLoadAddons: boolean;
var
  i:integer;
begin
  try
  DebugLog('Killing exist addons...');
  addonsList.Destroy;
  AddonsWnd.addonsList.Clear;
  for i:= TimersList.Count - 1 downto 0  do
  begin
      (TimersList[i] as TxtTimer).Kill;
      //(TimersList[i] as TxtTimer).Free;
  end;
  TimersList.Clear;
  LogWnd.addonList.Clear;
  except on E:Exception do
    DebugLog('Error while killing addons: '+E.Message);
  end;
end;

function reLoadAddons: boolean;
begin
  try
  DebugLog('Reloading addons...');
  unLoadAddons;
  LoadAddons(luaLibrary,userDirectory);
  LogWnd.addonList.ItemIndex := 0;
  except on E: Exception do
  begin
    LogError('An error occurred while reloading addons! :D '+E.Message+' '+E.MethodName(E.MethodAddress('unloadAddons')));
  end;
  end;
end;

function executeString(id: integer; code: string): variant;
begin
  DebugLog('code will be executed on id='+intToStr(id));
  (addonsList[id] as TxtAmnesiaAddon).ExecuteString(code);
end;

function callAddonFuncById(addonId: integer; functionName: string; params: array of variant): boolean;
begin
    result:=(addonsList[addonId] as TxtAmnesiaAddon).Execute(functionName,params);
end;

function callAddonEventFunction(functionName: string; params: array of variant): boolean;
var
  i,tmpAddonId:integer;
  res:boolean;
  startt: integer;
begin
  eventInProgress := true;
  if AddonsList.Count = 0 then
  begin
      result:= true;
      exit;
  end;
  tmpAddonId := GetActiveAddonId;
  startt:=GetTickCount;
  for i := 0 to addonsList.Count - 1 do
  begin
    SelectActiveAddonId(i); // Глобально знаем, какой аддон сейчас будет работать
    res:=(addonsList[i] as TxtAmnesiaAddon).Execute(functionName,params);
    if res then
      begin
      //DebugLog('script result from '+(addonsList[i] as TxtAmnesiaAddon).addonName+' is: TRUE');
      if messageChanged then
        begin
        params[2]:=getModifiedMessage;
        messageChanged:=false;
        end;
      end
    else
      //DebugLog('script result from '+(addonsList[i] as TxtAmnesiaAddon).addonName+' is: FALSE');
  end;
  eventInProgress := false;
  SelectActiveAddonId(tmpAddonId);

  DebugLog('Event has done in '+IntToStr(GetTickCount-startt)+' msec');
  result:=res;
end;

function getAddonScriptFileName(id: integer): string;
begin
  result:=(addonsList[id] as TxtAmnesiaAddon).scriptFileName;
end;


// ******************* LUA FUNCTIONS *********************

{function initLua(luadir: string): boolean;
var
fl: string;
begin
  if not DirectoryExists(luadir) then
    begin
      ForceDirectories(luadir);
    end;
  fl:=luadir+'\main.lua' ;
  if not FileExists(fl) then
      begin
        writeLineToFile(fl,'-- Amnesia by xternalx. this file is autogenerated at '+getTime('d.mm.yyyy hh-nn-ss'));
        writeLineToFile(fl,'-- PLEASE!!! DO NOT EDIT THIS FILE!!!'#13);
        writeLineToFile(fl,'-- section:global');
        writeLineToFile(fl,'-- end:global'#13);
        writeLineToFile(fl,'-- section:custom');
        writeLineToFile(fl,'-- end:custom'#13);
        writeLineToFile(fl,'-- section:events');
        writeLineToFile(fl,'-- end:events');
      end;
  result:=true;
end;

function xtDoLuaFile(luaVm: lua_state; filename: string):integer;
var
r:integer;
begin
  DebugLog('doing file: '+filename);
  r:=luaL_loadfile(luaVm,PChar(filename));
  DebugLog('file loaded with result: '+intToStr(r));
  if r<>0 then
    begin
      LogWnd.LogIt('***ERROR LOADING FILE: '+lua_tostring(luaVm,-1));
    end;
  r:=lua_pcall(luaVm, 0, LUA_MULTRET ,0);
  if r<>0 then
    begin
      LogWnd.LogIt('***ERROR EXECUTING FILE: '+lua_tostring(luaVm,-1));
    end;
  result:=r;
end;

function openLua(libname: string; userPath: string): boolean;
var
loadLuaDllResult: integer;
scriptResult: integer;
begin
  enableDebugMessages:=false;
  luaScriptDirectory:=userPath;
  luaLibrary:=libname;

  initLua(userPath);
  // check for lua dll exists
  if FileExists(libname) then
    loadLuaDllResult:=LoadLuaLib(libname)
  else
    begin
    LogWnd.LogIt('*** ERROR: Lua library not found, The Amnesia cannot continue:('#13'File Path: '+libname);
    result:=false;
    end;
  // check for correct load library
  if (loadLuaDllResult=-1) or (loadLuaDllResult=-2) then
  begin
    LogWnd.LogIt('*** ERROR: Loading Lua library failed :( ');
    result:=false;
  end;
  LoadLuaLib(libname);
  _lua:=lua_open;
  if (_lua=nil) then
  begin
    LogWnd.logIt('*** Error Initializing lua');
    LogWnd.Show;
  end;

  lua_atpanic(_lua,@lua_at_panic);

  registerSysToLua(_lua);
  luaL_openlibs(_lua);
   //lua_hook;
  lua_register(_lua,'print',l_print);
  lua_register(_lua,'echo',l_print);
  lua_register(_lua,'gettime',l_sys_gettime);
  lua_register(_lua,'sendmessage',l_sendmessage);

  Regexpr:=TRegExpr.Create;

  scriptResult:=xtDoLuaFile(_lua,userPath+'main.lua');

  result:=true;
end;

function deInitLua:boolean;
begin
  lua_close(_lua);
  FreeLuaLib;
  result:=true;
end;

procedure registerLuaFunc(funcName: string; func: lua_CFunction);
begin
  lua_register(_lua,pchar(funcName),func);
end;

function executeLuaFile(fileName: string): integer;
begin
  if FileExists(fileName) then
  begin
    result:=luaL_dofile(_lua,pchar(fileName));
  end
  else
  result:=-1;
end;

function getLuaResultType(luaVm: lua_State; index: integer):string;
begin
  if lua_isnumber(luaVm,index) then result:='number';
  if lua_isstring(luaVm,index) then result:='string';
  if lua_istable(luaVm,index) then result:='table';
  if lua_isfunction(luaVm,index) then result:='function';
  if lua_iscfunction(luaVm,index) then result:='cfunction';
  if lua_isuserdata(luaVm,index) then result:='userdata';
  if lua_isboolean(luaVm,index) then result:='bool';
  if lua_isthread(luaVm,index) then result:='thread';
  result:='undefined';
end;

function executeLuaString(scriptString: string): integer;
begin
  result:=luaL_dostring(_lua,pchar(scriptString));
end;


function errmsg(luaVM: lua_state):integer;
begin
    showmessage(lua_tostring(luaVM,-1));
end;

function luaFunctionExists(MethodName: string): Boolean;
begin
  lua_pushstring(_lua, PChar(MethodName));
  lua_rawget(_lua, LUA_GLOBALSINDEX);
  result := lua_isfunction(_lua, -1);
  lua_pop(_lua, 1);
end;

function callLuaFunc(funcName: string; params: array of variant):boolean;
var
i:integer;
res: integer;
rr:boolean;
argsNum:integer;

begin
  if (_lua=nil) then
  begin
    LogWnd.LogIt('*** Error Initializing lua');
    LogWnd.Show;
  end;

  if not luaFunctionExists('RnQSendMessage') then
  begin
    DebugLog('function "'+funcName+'" not defined');
    result:=true;
    //exit;
  end;

  argsNum:=length(params);
  DebugLog('param count: '+IntToStr(argsNum));
    lua_getglobal(_lua,PChar(funcName));
    for i:=0 to argsNum-1 do
      begin
        DebugLog(inttoStr(i+1)+'> '+string(params[i]));
        lua_pushstring(_lua,PChar(string(params[i])));
      end;
    res:=lua_pcall(_lua,argsNum,LUA_MULTRET, 0);

    if res<>0  then
    begin
      LogWnd.LogIt('***ERROR CALL FUNC: '+funcName+' - '+lua_tostring(_lua,-1));
      rr:=true;
    end
      else
      rr:=lua_toboolean(_lua,-1);

   if rr=true then
    DebugLog('script called with result='+inttostr(res)+' function result TRUE')
    else
    DebugLog('script called with result='+inttostr(res)+' function result FALSE');

    result := rr;
end;     }

end.
