object EditorWnd: TEditorWnd
  Left = 0
  Top = 0
  Caption = 'Script Manager'
  ClientHeight = 400
  ClientWidth = 434
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object ScrollBox1: TScrollBox
    Left = 0
    Top = 0
    Width = 434
    Height = 373
    Align = alClient
    TabOrder = 0
    ExplicitLeft = 192
    ExplicitTop = 176
    ExplicitWidth = 185
    ExplicitHeight = 41
    object Panel1: TPanel
      Left = 5
      Top = 5
      Width = 404
      Height = 76
      Ctl3D = True
      ParentCtl3D = False
      TabOrder = 0
      TabStop = True
      object Label1: TLabel
        Left = 4
        Top = 24
        Width = 395
        Height = 48
        AutoSize = False
        Caption = 'Description'
      end
      object CheckBox1: TCheckBox
        Left = 4
        Top = 4
        Width = 97
        Height = 17
        Caption = 'Plugin name'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
    end
  end
  object Panel2: TPanel
    Left = 0
    Top = 373
    Width = 434
    Height = 27
    Align = alBottom
    AutoSize = True
    TabOrder = 1
    ExplicitTop = 368
    object Button1: TButton
      Left = 353
      Top = 1
      Width = 75
      Height = 25
      Caption = 'Ok'
      TabOrder = 0
    end
    object Button2: TButton
      Left = 272
      Top = 1
      Width = 75
      Height = 25
      Caption = 'Cancel'
      TabOrder = 1
    end
  end
  object MainMenu1: TMainMenu
    Top = 384
    object Scripts1: TMenuItem
      Caption = 'Scripts'
      object NewPackage1: TMenuItem
        Caption = 'Create New Package'
      end
      object InstallNewPackage1: TMenuItem
        Caption = 'Install New Package'
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object ExportSelectedPackage1: TMenuItem
        Caption = 'Export Selected Package'
      end
      object RemoveSelectedPackage1: TMenuItem
        Caption = 'Remove Selected Package'
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object CloseManager1: TMenuItem
        Caption = 'Close Manager'
      end
    end
    object Help1: TMenuItem
      Caption = 'Help'
      object Contents1: TMenuItem
        Caption = 'Contents'
      end
    end
  end
end
