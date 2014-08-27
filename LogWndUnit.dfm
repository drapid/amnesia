object LogWnd: TLogWnd
  Left = 180
  Top = 197
  Caption = 'Amnesia debug'
  ClientHeight = 536
  ClientWidth = 688
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poDesigned
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 196
    Width = 688
    Height = 3
    Cursor = crVSplit
    Align = alTop
    ExplicitLeft = 8
    ExplicitTop = 88
  end
  object LogText: TMemo
    Left = 0
    Top = 0
    Width = 688
    Height = 196
    TabStop = False
    Align = alTop
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 199
    Width = 688
    Height = 337
    Align = alClient
    Caption = 'Panel1'
    Ctl3D = False
    ParentCtl3D = False
    TabOrder = 1
    object Panel2: TPanel
      Left = 1
      Top = 1
      Width = 686
      Height = 24
      Align = alTop
      Ctl3D = False
      ParentCtl3D = False
      TabOrder = 0
      object SpeedButton1: TSpeedButton
        Left = 406
        Top = 1
        Width = 59
        Height = 22
        Caption = 'Load'
        OnClick = SpeedButton1Click
      end
      object SpeedButton2: TSpeedButton
        Left = 471
        Top = 1
        Width = 59
        Height = 22
        Caption = 'Save'
        OnClick = SpeedButton2Click
      end
      object SpeedButton3: TSpeedButton
        Left = 334
        Top = 1
        Width = 59
        Height = 22
        Caption = 'Options'
        OnClick = SpeedButton3Click
      end
      object Button1: TButton
        Left = 0
        Top = 2
        Width = 65
        Height = 22
        Caption = '[F9] Run in:'
        Default = True
        TabOrder = 0
        TabStop = False
        OnClick = Button1Click
      end
    end
    object addonList: TComboBox
      Left = 64
      Top = 1
      Width = 265
      Height = 22
      BevelEdges = []
      BevelInner = bvNone
      BevelOuter = bvNone
      Style = csOwnerDrawFixed
      ItemHeight = 16
      TabOrder = 1
      TabStop = False
      OnChange = addonListChange
    end
    object CmdLine: TSynMemo
      Left = 1
      Top = 25
      Width = 686
      Height = 311
      Align = alClient
      Color = clWhite
      Ctl3D = False
      ParentCtl3D = False
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Lucida Console'
      Font.Style = []
      TabOrder = 2
      OnKeyDown = CmdLineKeyDown
      Gutter.Font.Charset = DEFAULT_CHARSET
      Gutter.Font.Color = clWindowText
      Gutter.Font.Height = -11
      Gutter.Font.Name = 'Courier New'
      Gutter.Font.Style = []
      Gutter.ShowLineNumbers = True
      Highlighter = SynLuaSyn1
      Lines.Strings = (
        '-- insert your code here and press F9 to run in selected addon')
      Options = [eoAutoIndent, eoDragDropEditing, eoDropFiles, eoEnhanceEndKey, eoGroupUndo, eoScrollPastEol, eoShowScrollHint, eoSmartTabDelete, eoTabIndent, eoTabsToSpaces]
      TabWidth = 4
      WantTabs = True
    end
  end
  object MainMenu1: TMainMenu
    Left = 72
    Top = 32
    object Amnesia1: TMenuItem
      Caption = 'Amnesia'
      object Reload1: TMenuItem
        Caption = 'Reload'
        ShortCut = 16504
        OnClick = Reload1Click
      end
      object About1: TMenuItem
        Caption = 'About...'
        ShortCut = 112
        OnClick = About1Click
      end
    end
    object Addons1: TMenuItem
      Caption = 'Addons'
      object Showeditor1: TMenuItem
        Caption = 'Change Addons Order'
        ShortCut = 114
        OnClick = Showeditor1Click
      end
    end
    object Log1: TMenuItem
      Caption = 'Logging'
      object Reload2: TMenuItem
        Caption = 'Clear log'
        ShortCut = 123
        OnClick = Reload2Click
      end
      object dbgMessagesToggler: TMenuItem
        Caption = 'Toggle degug messages'
        RadioItem = True
        ShortCut = 113
        OnClick = dbgMessagesTogglerClick
      end
    end
  end
  object SynLuaSyn1: TSynLuaSyn
    DefaultFilter = 'LUA Files (*.lua)|*.lua'
    FunctionAttri.Style = [fsBold]
    IdentifierAttri.Foreground = clBlack
    KeyAttri.Style = [fsBold]
    Left = 264
    Top = 104
  end
  object SynCompletionProposal1: TSynCompletionProposal
    Options = [scoLimitToMatchedText, scoUseInsertList, scoUsePrettyText, scoUseBuiltInTimer, scoEndCharCompletion, scoCompleteWithTab, scoCompleteWithEnter]
    ItemList.Strings = (
      
        'method \column{}\style{+B}base64.enc\style{-B}(string message) \' +
        'style{+I}string\style{-I}'
      
        'method \column{}\style{+B}base64.dec\style{-B}(string encodedmes' +
        'sage) \style{+I}string\style{-I}'
      ''
      
        'method \column{}\style{+B}rnq.sendmsg\style{-B}(string uin,strin' +
        'g message) \style{+I}void\style{-I}'
      
        'method \column{}\style{+B}rnq.sendaddedyou\style{-B}(int uin) \s' +
        'tyle{+I}void\style{-I}'
      
        'method \column{}\style{+B}rnq.setstatus\style{-B}(string status)' +
        ' \style{+I}void\style{-I}'
      
        'method \column{}\style{+B}rnq.setvisibility\style{-B}(string vis' +
        'ibility) \style{+I}void\style{-I}'
      
        'method \column{}\style{+B}rnq.quit\style{-B}() \style{+I}void\st' +
        'yle{-I}'
      
        'method \column{}\style{+B}rnq.connect\style{-B}() \style{+I}void' +
        '\style{-I}'
      
        'method \column{}\style{+B}rnq.disconnect\style{-B}() \style{+I}v' +
        'oid\style{-I}'
      
        'method \column{}\style{+B}rnq.setautomsg\style{-B}(string messag' +
        'e) \style{+I}void\style{-I}'
      
        'method \column{}\style{+B}rnq.getconnectionstate\style{-B}}() \s' +
        'tyle{+I}string\style{-I}'
      
        'method \column{}\style{+B}rnq.getdisplayednamefor\style{-B}(int ' +
        'uin) \style{+I}string\style{-I}'
      
        'method \column{}\style{+B}rnq.getuserpath\style{-B}() \style{+I}' +
        'string\style{-I}'
      
        'method \column{}\style{+B}rnq.getrnqpath\style{-B}() \style{+I}s' +
        'tring\style{-I}'
      
        'method \column{}\style{+B}rnq.getautomsg\style{-B}() \style{+I}s' +
        'tring\style{-I}'
      
        'method \column{}\style{+B}rnq.getstatus\style{-B}() \style{+I}st' +
        'ring\style{-I}'
      
        'method \column{}\style{+B}rnq.getcontacts\style{-B}(string mode)' +
        ' \style{+I}table\style{-I}'
      ''
      
        'method \column{}\style{+B}rnq.getcontactinfo\style{-B}(int uin) ' +
        '\style{+I}contactinfo\style{-I}'
      ''
      
        'method \column{}\style{+B}regex.setmode\style{-B}(string mode) \' +
        'style{+I}void\style{-I}'
      
        'method \column{}\style{+B}regex.getmode\style{-B}() \style{+I}st' +
        'ring\style{-I}'
      
        'method \column{}\style{+B}regex.replace\style{-B}(string text, s' +
        'tring replacement, string expression) \style{+I}string\style{-I}'
      
        'method \column{}\style{+B}regex.match\style{-B}(string text, str' +
        'ing expression) \style{+I}bool\style{-I}'
      
        'method \column{}\style{+B}regex.get\style{-B}(string text, strin' +
        'g expression) \style{+I}table\style{-I}'
      ''
      
        'method \column{}\style{+B}sys.wait\style{-B}(int msec) \style{+I' +
        '}void\style{-I}'
      
        'method \column{}\style{+B}sys.doevents\style{-B}() \style{+I}voi' +
        'd\style{-I}'
      
        'method \column{}\style{+B}sys.exec\style{-B}(string exename, str' +
        'ing command_line, string work_dir, string action, int mode, bool' +
        ' read_stdout) \style{+I}void\style{-I}'
      
        'method \column{}\style{+B}sys.getcmdline\style{-B}() \style{+I}v' +
        'oid\style{-I}'
      
        'method \column{}\style{+B}sys.getcmdlinei\style{-B}(int id) \sty' +
        'le{+I}void\style{-I}'
      
        'method \column{}\style{+B}sys.getversion\style{-B}() \style{+I}s' +
        'tring\style{-I}'
      
        'method \column{}\style{+B}sys.gettime\style{-B}(string mask) \st' +
        'yle{+I}string\style{-I}'
      
        'method \column{}\style{+B}sys.enabledebugmessages\style{-B}() \s' +
        'tyle{+I}void\style{-I}'
      
        'method \column{}\style{+B}sys.disabledebugmessages\style{-B}() \' +
        'style{+I}void\style{-I}'
      
        'method \column{}\style{+B}sys.isdebugmessagesenabled\style{-B}()' +
        ' \style{+I}bool\style{-I}'
      ''
      
        'method \column{}\style{+B}timers.new\style{-B}(string name, stri' +
        'ng funcname, int interval) \style{+I}int\style{-I}'
      
        'method \column{}\style{+B}timers.setinterva\style{-B}l(string na' +
        'me, int interval) \style{+I}int\style{-I}'
      
        'method \column{}\style{+B}timers.start\style{-B}(string name) \s' +
        'tyle{+I}int\style{-I}'
      
        'method \column{}\style{+B}timers.stop\style{-B}(string.name) \st' +
        'yle{+I}int\style{-I}'
      
        'method \column{}\style{+B}timers.kill\style{-B}(string name) \st' +
        'yle{+I}int\style{-I}'
      
        'method \column{}\style{+B}timers.getcount\style{-B}() \style{+I}' +
        'int\style{-I}'
      
        'method \column{}\style{+B}timers.getname\style{-B}(int timerId) ' +
        '\style{+I}string\style{-I}'
      ''
      
        'method \column{}\style{+B}file.append\style{-B}(string message) ' +
        '\style{+I}bool\style{-I}'
      
        'method \column{}\style{+B}file.appendln\style{-B}(string message' +
        ') \style{+I}bool\style{-I}'
      
        'method \column{}\style{+B}file.exists\style{-B}(string file) \st' +
        'yle{+I}bool\style{-I}'
      
        'method \column{}\style{+B}file.copy\style{-B}(string sourcefile,' +
        ' string destfile) \style{+I}bool\style{-I}'
      
        'method \column{}\style{+B}file.delete\style{-B}(string file) \st' +
        'yle{+I}bool\style{-I}'
      
        'method \column{}\style{+B}file.find\style{-B}(string dir, string' +
        ' mask, bool resursive) \style{+I}table\style{-I}'
      ''
      
        'method \column{}\style{+B}ini.get\style{-B}(string file, string ' +
        'section, string key) \style{+I}string\style{-I}'
      
        'method \column{}\style{+B}ini.set\style{-B}(string file, string ' +
        'section, string key, string value) \style{+I}void\style{-I}'
      ''
      
        'method \column{}\style{+B}print\style{-B}(string message) \style' +
        '{+I}void\style{-I}'
      
        'method \column{}\style{+B}echo\style{-B}(string message) \style{' +
        '+I}void\style{-I}'
      ''
      
        'event \column{}\style{+B}RnQInitialize\style{-B}(rnqVapiVer,rnqP' +
        'ath,rnqUserPath,rnqCurrentUIN) \style{+I}bool\style{-I}'
      
        'event \column{}\style{+B}RnQIncomingMessage\style{-B}(uin,flags,' +
        'msg,datetime) \style{+I}bool\style{-I}'
      
        'event \column{}\style{+B}RnQSendMessage\style{-B}(uin,flags,msg)' +
        ' \style{+I}bool\style{-I}'
      
        'event \column{}\style{+B}RnQAuthorizationRequested\style{-B}(uin' +
        ',flags,datetime,msg) \style{+I}bool\style{-I}'
      
        'event \column{}\style{+B}RnQConnected\style{-B} \style{+I}void\s' +
        'tyle{-I}'
      
        'event \column{}\style{+B}RnQDisconnected\style{-B} \style{+I}voi' +
        'd\style{-I}'
      
        'event \column{}\style{+B}OnShowOptions\style{-B} \style{+I}void\' +
        'style{-I}'
      ''
      'property \column{}sys.scriptroot \style{+I}string\style{-I}'
      'property \column{}addon.name \style{+I}string\style{-I}'
      'property \column{}addon.shortname \style{+I}string\style{-I}'
      'property \column{}addon.version \style{+I}string\style{-I}'
      'property \column{}addon.author \style{+I}string\style{-I}'
      'property \column{}addon.comments \style{+I}string\style{-I}'#13)
    InsertList.Strings = (
      'base64.enc()'
      'base64.dec()'
      ''
      'rnq.sendmsg(,)'
      'rnq.sendaddedyou()'
      'rnq.setstatus()'
      'rnq.setvisibility()'
      'rnq.quit()'
      'rnq.connect()'
      'rnq.disconnect()'
      'rnq.setautomsg()'
      'rnq.getconnectionstate()'
      'rnq.getdisplayednamefor()'
      'rnq.getuserpath()'
      'rnq.getrnqpath()'
      'rnq.getautomsg()'
      'rnq.getstatus()'
      'rnq.getcontacts()'
      ''
      'rnq.getcontactinfo()'
      ''
      'regex.setmode()'
      'regex.getmode()'
      'regex.replace(,,)'
      'regex.match(,)'
      'regex.get(,)'
      ''
      'sys.wait(int msec)'
      'sys.doevents()'
      'sys.exec()'
      'sys.getversion()'
      'sys.getcmdline()'
      'sys.getcmdlinei()'
      'sys.gettime()'
      'sys.enabledebugmessages()'
      'sys.disabledebugmessages()'
      'sys.isdebugmessagesenabled()'
      ''
      'timers.new(,l)'
      'timers.setinterval(,)'
      'timers.start()'
      'timers.stop()'
      'timers.kill()'
      'timers.getcount()'
      'timers.getname()'
      ''
      'file.append()'
      'file.appendln()'
      'file.exists()'
      'file.copy(,)'
      'file.delete()'
      'file.find(,,)'
      ''
      'ini.get(,,)'
      'ini.set(,,,) '
      ''
      'print()'
      'echo()'
      ''
      'RnQInitialize(rnqVapiVer,rnqPath,rnqUserPath,rnqCurrentUIN)'
      'RnQIncomingMessage(uin,flags,msg,datetime)'
      'RnQSendMessage(uin,flags,msg)'
      'RnQAuthorizationRequested(uin,flags,datetime,msg)'
      'RnQConnected'
      'RnQDisconnected'
      'OnShowOptions'
      ''
      'sys.scriptroot'
      'addon.name'
      'addon.shortname'
      'addon.version'
      'addon.author'
      'addon.comments')
    Width = 360
    EndOfTokenChr = '()[]'
    TriggerChars = '(['
    Title = 'Functions list'
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Lucida Console'
    Font.Style = []
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clBtnText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = [fsBold]
    Columns = <>
    ShortCut = 16416
    Editor = CmdLine
    TimerInterval = 400
    Left = 376
    Top = 152
  end
end
