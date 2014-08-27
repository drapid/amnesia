unit CreateNewAddonWndUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TCreateNewAddonWnd = class(TForm)
    addonName: TEdit;
    Button1: TButton;
    addonShortName: TEdit;
    addonVersion: TEdit;
    addonAuthor: TEdit;
    Label1: TLabel;
    addonComments: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CreateNewAddonWnd: TCreateNewAddonWnd;

implementation

{$R *.dfm}



end.
