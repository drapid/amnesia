unit AddonsWndUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, CheckLst, LogWndUnit, xtAmnesiaFuncs;

type
  TAddonsWnd = class(TForm)
    addonsList: TCheckListBox;
    procedure addonsListDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure addonsListDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure addonsListClickCheck(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure AddonAdd(name: string);
  end;

var
  AddonsWnd: TAddonsWnd;
  newId, dragId: integer;
  p: TPoint;

implementation

{$R *.dfm}

procedure TAddonsWnd.AddonAdd(name: string);
begin
  AddonsList.Items.Add(name);
end;

procedure TAddonsWnd.addonsListClickCheck(Sender: TObject);
begin
  ToggleAddon(addonslist.ItemIndex);
end;

procedure TAddonsWnd.addonsListDragDrop(Sender, Source: TObject; X, Y: Integer);
begin

  if newId >-1 then
    begin
      AddonsList.Items.Move(dragId,newId);
      changeAddonPos(dragId,newId);
    end;

end;

procedure TAddonsWnd.addonsListDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
var
  j: integer;
  s: integer;
begin
    Accept := (Source = AddonsList);
    dragId := AddonsList.ItemIndex;
    p.X:=X;
    p.Y:=Y;
    newId:=addonsList.ItemAtPos(p,true);

end;

end.
