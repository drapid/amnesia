object AddonsWnd: TAddonsWnd
  Left = 0
  Top = 0
  Caption = 'Available addons: '
  ClientHeight = 225
  ClientWidth = 408
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object addonsList: TCheckListBox
    Left = 0
    Top = 0
    Width = 408
    Height = 225
    OnClickCheck = addonsListClickCheck
    Align = alClient
    BorderStyle = bsNone
    DragMode = dmAutomatic
    ItemHeight = 13
    TabOrder = 0
    OnDragDrop = addonsListDragDrop
    OnDragOver = addonsListDragOver
  end
end
