unit xtTimersManager;

interface

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
  ExtCtrls,
  lua,
  //xtTimers in 'xtTimers.pas',
  xtAmnesiaFuncs;


implementation


type
  PTimer = class(TTimer)
  public
    funcName: string;
  end;

type
    TEventHandlers = class
    procedure TimerTick(Sender: TObject) ;
  end;

var
  timersList: TList;
  EvHandler:TEventHandlers;
  _lua: lua_State;

function init: integer;
begin
  timersList:=TList.Create;
  timersList.Clear;
end;

procedure TEventHandlers.TimerTick(Sender: TObject) ;
var
  args: array of variant;
begin
   callAddonFunction((Sender as PTimer).funcName,[]);
end;


procedure createTimer(name: string; funcName: string; interval: integer);
var
  timer: PTimer;
begin
  timer:=PTimer.Create(nil);
  timer.Name:=name;
  timer.funcName:=funcName;
  timer.Interval:=interval;

  EvHandler:=TEventHandlers.Create;
  timer.OnTimer:=EvHandler.TimerTick;

  timer.Enabled:=true;
  timersList.Add(timer);
end;

function findTimer(name: string): integer;
var
  i:integer;
begin
  for i := 0 to timersList.Count - 1 do
  begin
    //if timersList.Items[i].Name=name then

  end;
    
end;

function killTimer(name: string): integer;
begin

end;

procedure setInterval(name: string; interval: integer);
begin

end;

end.



