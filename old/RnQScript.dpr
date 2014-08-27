library RnQScript;

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
  xtLuaFuncs,
  CallExec in 'CallExec.pas' { $LIBSUFFIX '_IE2'};

{$E dll}

{$R *.res}
 const
  version = '0.1';
  namepl  = 'RnQ xternalxScript ' + version ;

  about   = 'RnQ Script is a scripting engine'#13 +
            'made by xternalx at xternalx.7pe.net'#13 +
            'based on LUA (lua.org)'#13#13 +
            'project started at 20.08.2008';
var
  // ************* PROGRAM VARS ******
  userPath, andrqPath, buffers: string;
  panelID: Integer;
  chat_hwnd: Integer;
  CurTime: STRING;
  vApiVersion, currentUIN, bufferi, temp, uin_ : Integer;
  unnamed: boolean;
  uin        : Integer;   // UIN собеседника
  flags      : Integer;   // флаги сообщения
  dt         : TDateTime; // дата и время сообщения
  msg: string;

function pluginFun(data:pointer):pointer; stdcall;
begin
     result:=NIL;
  
  // load plugin icon from resource
  //ICON := TIcon.Create;
  //ICON.LoadFromResourceName(HInstance, 'PluginIcon');

  if (data=NIL) or (_int_at(data)=0) then
    exit;
  case _byte_at(data,4) of
    PM_EVENT:
      case _byte_at(data,5) of
        PE_INITIALIZE: { plugin initialize }
          begin
            RQ__ParseInitString(data, callback, vapiVersion, andrqPath, userPath,currentUIN);

            data := callStr(char(PM_GET) + char(PG_WINDOW) + char(PW_CHAT));
            chat_hwnd := _int_at(data, 5);
            //buttonAddr:= RQ_CreateChatButton(@OnButtonClick, ICON, namepl);
            result:=str2comm(char(PM_DATA)+_istring(namepl)+_int(APIversion));

           // if  then
            begin
              openLua(andrqPath+'Lua5.1.dll',userPath+'xtLua\');
              //executeLuaFile(userPath+'xtLua\main.lua');
            end;
            //ICON.Free;
            //PluginEnabled := true;
          end;

        PE_PREFERENCES:  { plugin 'preferences' }
          begin
            MessageBoxA(chat_hwnd, PChar(about+#13+andrqPath), PChar(namepl), MB_OK);
          end;

        PE_MSG_GOT:
          begin
            RQ__ParseMsgGotString(data, uin, flags, dt, msg);
            if uin=462321666 then
            begin
              showmessage('nolka says: '+msg);
              result:=nil;
            end
            else
              begin
              result:=str2comm(char(PM_DATA)+_istring(msg));
              end;
          end;

      end;//case
    end;//case
end;
    exports pluginFun;
begin
end.
