unit LogWndUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Menus, ExtCtrls, SynEdit, SynMemo, SynEditHighlighter,
  SynHighlighterLua, SynCompletionProposal, Buttons, AboutBoxUnit;

type
  TLogWnd = class(TForm)
    LogText: TMemo;
    MainMenu1: TMainMenu;
    Amnesia1: TMenuItem;
    Reload1: TMenuItem;
    Log1: TMenuItem;
    Reload2: TMenuItem;
    Showeditor1: TMenuItem;
    Splitter1: TSplitter;
    Panel1: TPanel;
    Panel2: TPanel;
    addonList: TComboBox;
    Button1: TButton;
    About1: TMenuItem;
    Addons1: TMenuItem;
    SynLuaSyn1: TSynLuaSyn;
    CmdLine: TSynMemo;
    SynCompletionProposal1: TSynCompletionProposal;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    dbgMessagesToggler: TMenuItem;
    SpeedButton3: TSpeedButton;
    procedure Reload1Click(Sender: TObject);
    procedure Reload2Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure CmdLineKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Showeditor1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure addonListChange(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure dbgMessagesTogglerClick(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
  private
    { Private declarations }

  public
    { Public declarations }
    LogFile: string;
    procedure LogIt(msg: string);
    procedure LogAppend(msg: string);
    procedure AssignLogFile(fileName: string);
    procedure RunScript;
  end;


var
  LogWnd: TLogWnd;
  AboutBox: TAboutBox;
  CallForm: THandle;
  // Переключатель, позволяющий запретить перезапись имеющегося скрипта тем,
  // Что находится в редакторе кода ДО загрузки самого скрипта
  ScriptLoaded: boolean = false;

  lf : TextFile;

implementation

uses xtAmnesiaFuncs, AddonsWndUnit;

{$R *.dfm}

procedure TLogWnd.RunScript;
begin
if addonList.ItemIndex<0 then
  begin
    LogIt('You must select addon to continue...');
    exit;
  end;
  executeString(addonList.ItemIndex,cmdLine.Lines.Text);
end;

procedure TLogWnd.Showeditor1Click(Sender: TObject);
begin
if assigned(AddonsWnd) then
  AddonsWnd.ShowModal;
end;

procedure TLogWnd.SpeedButton1Click(Sender: TObject);
begin
  try
    LogIt('Loading script from '+getAddonScriptFileName(addonList.ItemIndex));
    CmdLine.Lines.LoadFromFile(getAddonScriptFileName(addonList.ItemIndex));
    ScriptLoaded := true;
  except on E: Exception do
    LogIt('Error while loading script: '+E.Message);
  end;

end;

procedure TLogWnd.SpeedButton2Click(Sender: TObject);
begin
  try
    if ScriptLoaded = true then
    begin
      LogIt('Saving script to '+getAddonScriptFileName(addonList.ItemIndex));
      CmdLine.Lines.SaveToFile(getAddonScriptFileName(addonList.ItemIndex));
    end
    else
    LogIt('There are no scripts loaded!');
  except on E: Exception do
    LogIt('Error while saving script: '+E.Message);
  end;
end;


procedure TLogWnd.SpeedButton3Click(Sender: TObject);
begin
  try
  callAddonFuncById(addonList.ItemIndex,'OnShowOptions',[]);
  except

  end;
end;

procedure TLogWnd.Button1Click(Sender: TObject);
begin
  RunScript;
end;



procedure TLogWnd.CmdLineKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
  var
  lnum,cnum: integer;
begin
  if Key=VK_F9 then
  RunScript;
  {if Key=VK_TAB then
    begin
    lnum:=SendMessage(cmdLine.Handle, EM_LINEFROMCHAR, word(-1), 0);
    cnum:=sendmessage(cmdLine.handle, em_lineindex, sendmessage(cmdLine.handle,
em_linefromchar, cmdLine.selstart, 0), 0);
    showMessage(intTOStr(lnum)+' - '+IntToStr(cnum));
    end; }
end;


procedure TLogWnd.FormDestroy(Sender: TObject);
begin
  //CloseFile(lf);
end;

procedure TLogWnd.FormShow(Sender: TObject);
begin
if addonList.Items.Count>0 then
  addonList.ItemIndex := 0;
end;

procedure TLogWnd.About1Click(Sender: TObject);
begin
  AboutBox := TAboutBox.Create(self);
  AboutBox.ShowModal;
end;

procedure TLogWnd.addonListChange(Sender: TObject);
begin
  ScriptLoaded := false;
  SelectActiveAddonId(addonList.Itemindex);
  CmdLine.Text := '-- insert your code here and press F9 to run in selected addon';
end;

procedure TLogWnd.AssignLogFile(fileName: string);
begin
  //LogFile:=fileName;
  //AssignFile(lf,LogFile);
  //Rewrite(lf);
end;

procedure TLogWnd.LogIt(msg: string);
begin
  LogText.Lines.Add(msg);
  //WriteLn(lf,msg);
  //flush(lf);
end;

procedure TLogWnd.dbgMessagesTogglerClick(Sender: TObject);
begin
dbgMessagesToggler.Checked := not dbgMessagesToggler.Checked;
ToggleDebugMessages;
end;

procedure TLogWnd.LogAppend(msg: string);
begin
  LogText.Lines[LogText.Lines.Count-1]:=LogText.Lines[LogText.Lines.Count-1]+msg;
  //Write(lf,msg);
  //flush(lf);
end;

procedure TLogWnd.Reload1Click(Sender: TObject);
begin
  reLoadAddons;
end;

procedure TLogWnd.Reload2Click(Sender: TObject);
begin
LogText.Lines.Clear;
end;


end.
