object CreateNewAddonWnd: TCreateNewAddonWnd
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Create new addon...'
  ClientHeight = 184
  ClientWidth = 336
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 16
    Width = 65
    Height = 13
    Caption = 'Addon Name:'
  end
  object Label2: TLabel
    Left = 8
    Top = 46
    Width = 94
    Height = 13
    Caption = 'Addon Short Name:'
  end
  object Label3: TLabel
    Left = 8
    Top = 75
    Width = 39
    Height = 13
    Caption = 'Version:'
  end
  object Label4: TLabel
    Left = 8
    Top = 102
    Width = 37
    Height = 13
    Caption = 'Author:'
  end
  object Label5: TLabel
    Left = 8
    Top = 129
    Width = 54
    Height = 13
    Caption = 'Comments:'
  end
  object addonName: TEdit
    Left = 120
    Top = 16
    Width = 209
    Height = 21
    TabOrder = 0
  end
  object Button1: TButton
    Left = 240
    Top = 153
    Width = 89
    Height = 25
    Caption = 'Create'
    TabOrder = 1
  end
  object addonShortName: TEdit
    Left = 120
    Top = 43
    Width = 209
    Height = 21
    TabOrder = 2
  end
  object addonVersion: TEdit
    Left = 120
    Top = 72
    Width = 209
    Height = 21
    TabOrder = 3
  end
  object addonAuthor: TEdit
    Left = 120
    Top = 99
    Width = 209
    Height = 21
    TabOrder = 4
  end
  object addonComments: TEdit
    Left = 120
    Top = 126
    Width = 209
    Height = 21
    TabOrder = 5
  end
end
