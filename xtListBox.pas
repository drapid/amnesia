unit xtListBox;

interface

uses
  SysUtils, Classes, Controls, StdCtrls, ExtCtrls;

type
  TxtListBox = class(TCustomListBox)
  private
    { Private declarations }
  protected
    { Protected declarations }
  public
    Items: TPanel;
    { Public declarations }
  published
    { Published declarations }
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TxtListBox]);
end;

end.
