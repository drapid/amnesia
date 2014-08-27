unit xtAmnesiaTimers;

interface

uses
  classes,
  ExtCtrls,
  lua;

implementation


type TTimerList = class (TObjectList)
    private
        function _GetItem(Index: Integer): TTimer;
        procedure _SetItem(Index: Integer; Value: TTimer);
    public
        function Add(ATimer: TTimer): Integer; overload;
        property Items[Index: Integer]: TTimer read _GetItem write _SetItem; default;
    end;

function TTimerList.Add(ATimer: TTimer): Integer;
begin
    Result := Self.Add(TObject(ATimer));
end;

function TTimerList._GetItem(Index: Integer): TTimer;
begin
    Result := TTimer(inherited Items[Index]);
end;

procedure TTimerList._SetItem(Index: Integer; Value: TTimer);
begin
    inherited Items[Index] := Value;
end;

end.
