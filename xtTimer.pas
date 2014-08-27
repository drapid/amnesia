unit xtTimer;

interface

uses
      SysUtils, IniFiles,  dialogs, Windows, ExtCtrls,
      lua,
      RegExpr,
      LogWndUnit,
      xtAmnesiaAddon;

type
  TxtTimer = class(Tobject)
    public
      Id: dword;
      AddonId: integer;
      Name: string;
      FunctionName: string;
      Interval: integer;
      constructor Create(timerName, funcName: string; interval, addonId: integer);
      procedure Start;      overload;
      procedure Start(interval: integer);  overload;
      procedure Stop;
      procedure Kill;
      procedure TakeAddon(addon: TxtAmnesiaAddon);
    private
      addon: TxtAmnesiaAddon;
      timer: TTimer;
      procedure OnTimer(Sender: TObject);  // use stdcall when declare callback functions;
  end;

implementation

constructor TxtTimer.Create(timerName, funcName: string; interval, addonId: integer);
begin
  self.Name := timerName;
  self.FunctionName := funcName;
  self.Interval := interval;
  self.AddonId := addonId;
  self.timer:= TTimer.Create(nil);
  self.timer.Interval := self.Interval;
  self.timer.OnTimer:= self.OnTimer;
end;

procedure TxtTimer.OnTimer(Sender: TObject);
begin
   addon.ExecuteString(self.FunctionName);
end;

procedure TxtTimer.Start;
begin
  self.timer.Enabled := true;
end;

procedure TxtTimer.Start(interval: integer);
begin
  self.timer.Interval:=interval;
  self.timer.Enabled := true;
end;

procedure TxtTimer.Stop;
begin
  self.timer.Enabled := false;
end;

procedure TxtTimer.Kill;
begin
  self.timer.Enabled := false;
  self.timer.Free;
end;

procedure TxtTimer.TakeAddon(addon: TxtAmnesiaAddon);
begin
  self.addon := addon;
end;



end.
