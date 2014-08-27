unit AboutBoxUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ShellAPI;

type
  TAboutBox = class(TForm)
    Image1: TImage;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    Button2: TButton;
    PluginVersionLabel: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation


uses xtAmnesiaFuncs;
{$R *.dfm}

procedure TAboutBox.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TAboutBox.Button2Click(Sender: TObject);
begin
  ShellExecute(handle,'open','http://xternalx.com','','',SW_SHOWNORMAL);
end;

procedure TAboutBox.FormShow(Sender: TObject);
begin
PluginVersionLabel.Caption := GetPluginVersion;
end;

end.
