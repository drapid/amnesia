library rqAmnesia;

uses
  types,
  Classes,
  windows,
  Messages,
  ShellApi,
  plugin,
  pluginutil,
  mmsystem,
  dialogs,
  Graphics,
  sysUtils,
  lua,
  xtAmnesiaFuncs in 'xtAmnesiaFuncs.pas',
  CallExec in 'CallExec.pas' { $LIBSUFFIX '_IE2'},
  LogWndUnit in 'LogWndUnit.pas' {LogWnd},
  AddonsWndUnit in 'AddonsWndUnit.pas' {AddonWnd},
  xtAmnesiaAddon in 'xtAmnesiaAddon.pas',
  AboutBoxUnit in 'AboutBoxUnit.pas' {AboutBox},
  xtTimer in 'xtTimer.pas';

{$E dll}

{$R rqAmnesia.res}

const
  PLUG_VERSION = '0.3.4';
  scriptDir = 'Amnesia';
  namepl  = 'RnQ aMNeSia ' + PLUG_VERSION ;

  about   = 'RnQ aMNeSia is a scripting engine'#13 +
            'made by xternalx at http://xternalx.com'#13 +
            'based on LUA 5.1 (lua.org)'#13#13 +
            'project started at 20.08.2008'#13#13;

var
  // ************* PROGRAM VARS ******
  userPath, andrqPath: string;
  chat_hwnd: Integer;
  vApiVersion, currentUIN: Integer;
  uin        : Integer;   // UIN собеседника
  flags      : Integer;   // флаги сообщения
  dt         : TDateTime; // дата и время сообщения
  msg: string;
  Icon: TIcon;
  buttonAddr: Integer;

  newStatus, oldStatus: byte;
  newVisibility, oldVisibility: boolean;




procedure DebugLog(msg: string);
begin
  if isDebugMessagesEnabled then
  LogWnd.LogIt('DBG: '+msg);
end;

procedure DebugLog2(const msg, Filename: string;  LineNumber: Integer; ErrorAddr: Pointer);
begin
  if isDebugMessagesEnabled then
  LogWnd.LogIt('asDBG: '+msg+'; File: '+FileName+': Line: '+IntToStr(LineNumber));
end;

procedure OnButtonCLick;
begin
  LogWnd.Show;
end;

function pluginFun(data:pointer):pointer; stdcall;
var
lres: boolean;
modMsg: string;
begin
     result:=NIL;

  if (data=NIL) or (_int_at(data)=0) then
    exit;
  case _byte_at(data,4) of
    PM_EVENT:
      case _byte_at(data,5) of
        PE_INITIALIZE: { plugin initialize }
          begin
          AssertErrorProc:=DebugLog2;
            RQ__ParseInitString(data, callback, vapiVersion, andrqPath, userPath,currentUIN);
            if not DirectoryExists(userPath+'Amnesia\') then
                ForceDirectories(userPath+'Amnesia');
            if not assigned(LogWnd) then
					    LogWnd := TLogWnd.create(NIL);
              LogWnd.AssignLogFile(userPath+'Amnesia\log.txt');
            if not assigned(AddonsWnd) then
              AddonsWnd:=TAddonsWnd.Create(NIL);
            

            DebugLog('*** Initialize');
            data := callStr(char(PM_GET) + char(PG_WINDOW) + char(PW_CHAT));
            chat_hwnd := _int_at(data, 5);
            ICON := TIcon.Create;
            ICON.LoadFromResourceName(HInstance,'AMNESIALOGO');
            buttonAddr:= RQ_CreateChatButton(@OnButtonClick, ICON, namepl);
            result:=str2comm(char(PM_DATA)+_istring(namepl)+_int(APIversion));


            //LogWnd.Show;
            LogWnd.LogIt('Plugin initialization');
            LogWnd.LogIt('*** WELCOME TO THE AMNESIA '+PLUG_VERSION+'! ***');
            //begin
            try
              DebugLog('loading lua: '+andrqPath+'Lua5.1.dll');
              LoadAddons(andrqPath+'Lua5.1.dll',userPath);
              lres:=callAddonEventFunction('RnQInitialize',[vapiVersion,andrqPath,userPath,currentUIN]);
              if lres=false then
              result:=str2comm(char(PM_ABORT));
            except on E: Exception do
              LogWnd.LogIt('*** INIT ERROR: '+E.Message);
            end;
            //end;

            ICON.Free;
            result:=str2comm( char(PM_DATA)+_istring(namepl)+_int(APIversion));
          end;

        PE_FINALIZE: { plugin initialize }
          begin
            DebugLog('*** Finalize');
            lres:=callAddonEventFunction('RnQFinalize',[vapiVersion,andrqPath,userPath,currentUIN]);
            unLoadAddons;
            RQ_DeleteChatButton(buttonAddr);
            LogWnd.Close;
            LogWnd.Free;
            AddonsWnd.Close;
            AddonsWnd.Free;
          end;

        PE_PREFERENCES:  { plugin 'preferences' }
          begin
            AddonsWnd.ShowModal;
          end;

        PE_MSG_GOT:
          begin
            RQ__ParseMsgGotString(data, uin, flags, dt, msg);
            DebugLog('*** Incoming Message');
            lres:=callAddonEventFunction('RnQIncomingMessage',[uin,flags,msg,dt]);
            if lres=true then
            begin
            //DebugLog('RnQIncomingMessage return true');
              modMsg:=getModifiedMessage;
              clearModifiedMessage;
              if modMsg<>'' then
              begin
                //DebugLog('incoming msg MODIFIED - '+modMsg) ;
                result:=str2comm(char(PM_DATA)+_istring(modMsg));
              end else
              begin
                //DebugLog('incoming msg NOT MODIFIED') ;
                result:=str2comm(char(PM_DATA)+_istring(msg));
              end;
            end
                else
            begin
                DebugLog('RnQIncomingMessage return false');
                result:=str2comm(char(PM_ABORT));
            end;
          end;

        PE_MSG_SENT:
          begin
            RQ__ParseMsgSentString(data, uin, flags, msg);
            DebugLog('*** Send Message');
            lres:=callAddonEventFunction('RnQSendMessage',[uin,flags,msg]);
            if lres=true then
            begin
            //DebugLog('RnQSendMessage return true');
             modMsg:=getModifiedMessage;
             clearModifiedMessage;
              if modMsg<>'' then
              begin
                //DebugLog('outgoing msg MODIFIED - '+modMsg) ;
                result:=str2comm(char(PM_DATA)+_istring(modMsg)+_istring(modMsg));
              end else
              begin
              //DebugLog('outgoing msg NOT MODIFIED') ;
                result:=str2comm(char(PM_DATA)+_istring(msg)+_istring(msg));
              end;
              //result:=str2comm(char(PM_DATA)+_istring(msg));
            end
              else
            begin
              //DebugLog('RnQSendMessage return false');
              result:=str2comm(char(PM_ABORT));
            end;
          end;

          PE_CONNECTED:
          begin
            DebugLog('*** Connected');
            callAddonEventFunction('RnQConnected',[])
          end;

          PE_DISCONNECTED:
          begin
            DebugLog('*** Disconnected');
            callAddonEventFunction('RnQDisconnected',[])
          end;

          PE_CONTACTS_GOT:
          begin

          end;

          PE_URL_SENT:
          begin

          end;

          PE_ADDEDYOU_GOT:
          begin
            RQ__ParseAddedYouGotString(data, uin, flags, dt);

          end;

          PE_ADDEDYOU_SENT:
          begin
            RQ__ParseAddedYouSentString(data, uin);
          end;

          PE_AUTHREQ_GOT:
          begin
            RQ__ParseAuthRequestGotString(data,uin, flags, dt, msg);
            DebugLog('*** Authorization requested');
            lres:=callAddonEventFunction('RnQAuthorizationRequested',[uin,flags,msg,dt]);
            if lres=true then
            begin
             modMsg:=getModifiedMessage;
             clearModifiedMessage;
             //DebugLog('message data: '+modMsg);
              if modMsg<>'' then
              begin
                result:=str2comm(char(PM_DATA)+_istring(modMsg));
              end else
              begin
                result:=str2comm(char(PM_DATA)+_istring(msg));
              end;
            end
              else
            begin
              result:=str2comm(char(PM_ABORT));
            end;
          end;

          PE_AUTHREQ_SENT:
          begin

          end;

          PE_AUTH_GOT:
          begin

          end;

          PE_AUTH_SENT:
          begin
            RQ__ParseAuthSentString(data, uin);
          end;

          PE_AUTHDENIED_GOT:
          begin

          end;

          PE_AUTHDENIED_SENT:
          begin

          end;

          PE_GCARD_GOT:
          begin

          end;

          PE_GCARD_SENT:
          begin

          end;

          PE_AUTOMSG_GOT:
          begin

          end;

          PE_AUTOMSG_SENT:
          begin

          end;

          PE_AUTOMSG_REQ_GOT:
          begin

          end;

          PE_AUTOMSG_REQ_SENT:
          begin

          end;

          PE_EMAILEXP_GOT:
          begin

          end;

          PE_EMAILEXP_SENT:
          begin

          end;

          PE_LIST_ADD:
          begin

          end;

          PE_LIST_REMOVE:
          begin

          end;

          PE_STATUS_CHANGED:
          begin
              RQ__ParseStatusChanged(data,uin,newStatus,oldStatus,newVisibility,oldVisibility);
              lres:= callAddonEventFunction('RnQStatusChanged',[uin, luaStatusToSting(newStatus), luaStatusToSting(oldStatus), newVisibility, oldVisibility]);
          end;

          PE_USERINFO_CHANGED:
          begin

          end;

          PE_VISIBILITY_CHANGED:
          begin

          end;

          PE_WEBPAGER_GOT:
          begin

          end;

          PE_WEBPAGER_SENT:
          begin

          end;

          PE_FROM_MIRABILIS:
          begin

          end;

          PE_UPDATE_INFO:
          begin

          end;

          PE_XSTATUSMSG_SENT:
          begin

          end;

          PE_XSTATUS_REQ_GOT:
          begin

          end;


      end;//case
    end;//case
end;
    exports
    pluginFun;
begin
end.
