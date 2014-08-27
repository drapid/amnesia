unit xtAmnesiaAddon;

interface

uses
      SysUtils, IniFiles,  dialogs, Windows,
      lua,
      RegExpr,
      LogWndUnit;


type
TxtAmnesiaAddon = class(TObject)
    private
      _lua: lua_State;
      //scriptFileName: string;
      scriptText: string;
      addonScriptDirectory: string;
      luaLibrary: string;
      isDebugMessagesEnabled: boolean;
      regexpr: TRegExpr;
      modifiedMessage: string;
//      function initLua(luadir: string): boolean;
      function getModifiedMessage: string;
      function openLua(libname: string): boolean;
      function closeLua:boolean;
      procedure registerLuaFunc(funcName: string; func: lua_CFunction);
      function executeLuaFile(fileName: string): integer;
      function getLuaResultType(luaVm: lua_State; index: integer):string;
      function luaToVariant(id: integer): variant;
      function luaFunctionExists(MethodName: string): Boolean;
      function callLuaFunc(tableName: string;funcName: string; params: array of variant):boolean;
      function getLuaState: lua_state;
      procedure setLuaState(luaVM:lua_state);
      procedure LogError(msg: string);
    public
      addonName: string;
      addonShortName: string;
      addonVersion: string;
      addonAuthor: string;
      addonComments: string;
      configFile: string;
      addonId: integer;
      scriptDirectory: string;
      scriptFileName: string;
      enabled: boolean;
      constructor Create(dllName, userDirectory, scriptRoot: string; Id: integer);
      destructor Destroy; override;
      function Start:integer;
      function GetInfo:boolean;
      function GetVariableValue(ValueName: String): Variant;
      function SetVariableValue(TableName, VariableName: String; value: Variant): boolean;
      function Execute(action: string; params: array of variant): boolean;
      function ExecuteString(scriptString: string): integer;
      function BindScript(scriptFileName: string): integer;
      function RegisterAddonFunction(funcName: string; func: lua_CFunction): integer;
      procedure DebugMessagesEnabled(state: boolean);
      procedure DebugLog(msg: string);
      procedure DebugLogA(msg: string);
      Property LuaState: lua_State read GetLuaState write SetLuaState;
    end;

implementation

constructor TxtAmnesiaAddon.Create(dllName, userDirectory, scriptRoot: string; Id: integer);
begin
  self.configFile:=scriptRoot+'amnesia.inf';
  self.scriptDirectory:=scriptRoot;
  self.GetInfo;
  self.enabled:=true;
  self.isDebugMessagesEnabled := false;
  self.addonId:= Id;
  self.DebugLog('Creating lua state...');
  if self.openLua(dllName) then
  begin
    self.DebugLog('...lua state created');
  end;
end;

destructor TxtAmnesiaAddon.Destroy;
begin
  self.closeLua;
end;

procedure TxtAmnesiaAddon.LogError(msg: string);
begin
  LogWnd.LogIt('A-'+intToStr(self.addonId)+'-['+self.addonShortName+']::ERROR: '+msg);
end;

procedure TxtAmnesiaAddon.DebugLog(msg: string);
begin
  if self.isDebugMessagesEnabled then
  LogWnd.LogIt('A-'+intToStr(self.addonId)+'-['+self.addonShortName+']: '+msg);
end;

procedure TxtAmnesiaAddon.DebugLogA(msg: string);
begin
  if self.isDebugMessagesEnabled then
  LogWnd.LogAppend(msg);
end;

procedure TxtAmnesiaAddon.DebugMessagesEnabled(state: boolean);
begin
  self.isDebugMessagesEnabled := state;
end;

function TxtAmnesiaAddon.getLuaState: lua_state;
begin
  result:=self._lua;
end;

procedure TxtAmnesiaAddon.setLuaState(luaVm: lua_state);
begin
  self._lua:=luaVm;
end;

function TxtAmnesiaAddon.Execute(action: string; params: array of variant): boolean;
begin
  if self.enabled then
    result:=self.callLuaFunc('',action, params)
  else
    result:=true;
end;

function TxtAmnesiaAddon.BindScript(scriptFileName: string): integer;
begin

end;

function TxtAmnesiaAddon.RegisterAddonFunction(funcName: string; func: lua_CFunction): integer;
begin
  self.registerLuaFunc(funcName, func);
end;

function TxtAmnesiaAddon.getModifiedMessage: string;
var
tempstr: string;
begin
  tempstr:=modifiedMessage;
  modifiedMessage:='';
  DebugLog('Sending messsage: "'+tempStr+'"');
  result:=tempStr;
end;


function TxtAmnesiaAddon.Start:integer;
var
r:integer;
begin
  try
  DebugLog('...running script: '+self.scriptFileName);

  self.SetVariableValue('sys','scriptroot',self.scriptDirectory);

  self.SetVariableValue('addon','name',self.addonName);
  self.SetVariableValue('addon','shortname',self.addonShortName);
  self.SetVariableValue('addon','version',self.addonVersion);
  self.SetVariableValue('addon','author',self.addonAuthor);
  self.SetVariableValue('addon','comments',self.addonComments);
  self.SetVariableValue('addon','root',self.scriptDirectory);

  r:=luaL_loadfile(self._lua,PChar(self.scriptFileName));
  if r<>0 then
    begin
      self.LogError('LOADING FILE: '+lua_tostring(self._lua,-1));
      result:=r;
      exit;
    end;

  r:=lua_pcall(self._lua, 0, LUA_MULTRET ,0);
  if r<>0 then
    begin
      self.LogError('EXECUTING FILE: '+lua_tostring(self._lua,-1));
    end;

  DebugLog('File loaded and executed result: '+intToStr(r));
  result:=r;
  except 

  end;
end;

function TxtAmnesiaAddon.GetInfo:boolean;
var
cfg:TIniFile;
begin
    cfg:=TIniFile.Create(self.configFile);
    self.addonName:=cfg.ReadString('parameters','addonName','');
    self.addonShortName:=cfg.ReadString('parameters','addonShortName','');
    self.addonVersion:=cfg.ReadString('parameters','addonVersion','');
    self.addonAuthor:=cfg.ReadString('parameters','addonAuthor','');
    self.addonComments:=cfg.ReadString('parameters','addonComments','');
    self.scriptFileName:=self.scriptDirectory+cfg.ReadString('parameters','script','amnesia.lua');
    cfg.Destroy;
end;

function TxtAmnesiaAddon.openLua(libname: string): boolean;
var
loadLuaDllResult: integer;
scriptResult: integer;
begin

  luaLibrary:=libname;
  DebugLog('...from library: '+libname);
  // check for lua dll exists
  if FileExists(libname) then
    loadLuaDllResult:=LoadLuaLib(libname)
  else
    begin
    self.LogError('Lua library not found, The Amnesia cannot continue:('#13'File Path: '+libname);
    result:=false;
    end;
  // check for correct load library
  if (loadLuaDllResult=-1) or (loadLuaDllResult=-2) then
  begin
    self.LogError('Loading Lua library failed :( ');
    result:=false;
  end;
  LoadLuaLib(libname);
  self._lua:=lua_open;
  if (self._lua=nil) then
  begin
    self.LogError('Initializing lua');
    LogWnd.Show;
  end;

  luaL_openlibs(self._lua);

  regexpr:=TRegExpr.Create;
  DebugLog('...OK');

  result:=true;
end;

function TxtAmnesiaAddon.closeLua:boolean;
begin
  try
    //lua_close(self._lua);
    FreeLuaLib;
    DebugLog('Goodbye...');
    inherited;
  except
    showmessage('’уево чета...');
  end;
end;

procedure TxtAmnesiaAddon.registerLuaFunc(funcName: string; func: lua_CFunction);
begin
  lua_register(self._lua,pchar(funcName),func);
end;

function TxtAmnesiaAddon.executeLuaFile(fileName: string): integer;
begin
  if FileExists(fileName) then
  begin
    result:=luaL_dofile(self._lua,pchar(fileName));
  end
  else
  result:=-1;
end;

function TxtAmnesiaAddon.getLuaResultType(luaVm: lua_State; index: integer):string;
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

function TxtAmnesiaAddon.executeString(scriptString: string): integer;
var
r:integer;
startt,endt: integer;

begin
  DebugLog('====================');
  DebugLog('executing script...');
  startt:=GetTickCount;
  r:=luaL_dostring(self._lua,pchar(scriptString));
  endt:=GetTickCount-startt;
  DebugLog('executed with result: '+IntToStr(r)+' in '+IntToStr(endt)+' msec');
  if r<>0 then
    begin
      self.LogError('while execute from user input: '+lua_tostring(self._lua,-1));
    end;
  result:=r;
end;

function TxtAmnesiaAddon.luaToVariant(id: integer): variant;
begin
  if lua_isstring(self._lua,id) then
    result:=string(PChar(lua_tostring(self._lua,id)));
  if lua_isnumber(self._lua,id) then
    result:=lua_tonumber(self._lua,id);
  if lua_isboolean(self._lua,id) then
    result:=lua_toboolean(self._lua,id);
  if lua_isnoneornil(self._lua,id) then
    result:=0;
end;

function TxtAmnesiaAddon.luaFunctionExists(MethodName: string): Boolean;
begin
  lua_pushstring(self._lua, PChar(MethodName));
  lua_rawget(self._lua, LUA_GLOBALSINDEX);
  result := lua_isfunction(self._lua, -1);
  lua_pop(self._lua, 1);
end;

function TxtAmnesiaAddon.GetVariableValue(ValueName: String): Variant;
begin
  lua_pushstring(self._lua, PChar(ValueName));
  lua_rawget(self._lua, LUA_GLOBALSINDEX);
  result := self.luaToVariant(-1);
  lua_pop(self._lua, 1);
end;

function TxtAmnesiaAddon.SetVariableValue(TableName, VariableName: String; value: Variant): boolean;
var
tableExists:boolean;
begin
  if (TableName<>'')then
  begin
    lua_pushstring(self._lua, PChar(TableName));
    lua_rawget(self._lua, LUA_GLOBALSINDEX);
    if not lua_istable(self._lua,-1) then
    begin
      lua_newtable(self._lua);
      lua_pushstring(self._lua, PChar(VariableName));
      lua_pushstring(self._lua, PChar(string(Value)));
      lua_rawset(self._lua, -3);
      lua_setglobal(self._lua,PChar(TableName));
      exit;
    end;

    lua_pushstring(self._lua, PChar(VariableName));
    lua_pushstring(self._lua, PChar(string(Value)));

    lua_rawset(self._lua,-3);
    lua_pop(self._lua,1);
    exit;
  end;
  begin
    lua_pushstring(self._lua,PChar(string(Value)));
    lua_setglobal(self._lua,PChar(string(VariableName)));
    lua_pop(self._lua,1);
  end;
end;

function TxtAmnesiaAddon.callLuaFunc(tableName: string;funcName: string; params: array of variant):boolean;
var
i:integer;
res: integer;
rr:boolean;
argsNum:integer;
startt: integer;

begin
  startt:=GetTickCount;
  if (self._lua=nil) then
  begin
    self.LogError('lua not initialized');
    LogWnd.Show;
    result:=false;
  end;

  if not luaFunctionExists(funcName) then
  begin
    self.DebugLog('function "'+funcName+'" not defined');
    result:=true;
    exit;
  end;

  if tableName<>'' then
  begin
    lua_pushstring(self._lua, PChar(string(tableName)));
     lua_gettable(self._lua, LUA_GLOBALSINDEX);
     lua_pushstring(self._lua, PChar(string(funcName)));
     lua_rawget(self._lua, -2);
  end
    else
  begin
    lua_getglobal(self._lua,PChar(funcName));
  end;
  argsNum:=length(params);
  DebugLog('param count: '+IntToStr(argsNum)+': ');

    for i:=0 to argsNum-1 do
      begin
        DebugLogA(inttoStr(i+1)+'='+string(params[i])+'; ');
        lua_pushstring(self._lua,PChar(string(params[i])));
      end;

    res:=lua_pcall(self._lua,argsNum,LUA_MULTRET, 0);

    if res<>0  then
    begin
      self.LogError('CALL FUNC: '+funcName+' - '+lua_tostring(self._lua,-1));
      rr:=true;
    end
      else
      rr:=lua_toboolean(self._lua,-1);

   if rr=true then
      DebugLog('script called with result='+inttostr(res)+' function result TRUE in '+IntToStr(GetTickCount-startt)+' msec')
    else
      DebugLog('script called with result='+inttostr(res)+' function result FALSE in '+IntToStr(GetTickCount-startt)+' msec');

    result := rr;

end;


end.
