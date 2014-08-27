unit editorWndUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, SynEdit, SynMemo, ExtCtrls, ComCtrls, ToolWin, StdCtrls, Menus, xtListBox;

type
  TEditorWnd = class(TForm)
    MainMenu1: TMainMenu;
    Scripts1: TMenuItem;
    NewPackage1: TMenuItem;
    ExportSelectedPackage1: TMenuItem;
    RemoveSelectedPackage1: TMenuItem;
    N1: TMenuItem;
    CloseManager1: TMenuItem;
    Help1: TMenuItem;
    Contents1: TMenuItem;
    N2: TMenuItem;
    InstallNewPackage1: TMenuItem;
    ScrollBox1: TScrollBox;
    Panel1: TPanel;
    CheckBox1: TCheckBox;
    Panel2: TPanel;
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EditorWnd: TEditorWnd;
  pluginList: TxtListBox;

implementation

{$R *.dfm}



procedure TEditorWnd.FormCreate(Sender: TObject);
begin
  pluginList:=TxtListBox.Create(EditorWnd);
  pluginList.Align:=alClient;
  pluginList.Name:='AddonList';
  pluginList.Items[0].Caption:='bu';
end;

end.
