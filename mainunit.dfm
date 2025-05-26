object MainForm: TMainForm
  Left = 364
  Top = 282
  Width = 668
  Height = 615
  Caption = 'Zoom Player language rebuilder v1.00'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnClose = FormClose
  OnKeyPress = FormKeyPress
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object LabelEnglishDialog: TTntLabel
    Left = 18
    Top = 22
    Width = 87
    Height = 13
    Caption = 'English dialog file :'
  end
  object LabelTransDialog: TTntLabel
    Left = 18
    Top = 56
    Width = 94
    Height = 13
    Caption = 'Previous dialog file :'
  end
  object LabelOutputDialog: TTntLabel
    Left = 18
    Top = 90
    Width = 85
    Height = 13
    Caption = 'Output dialog file :'
  end
  object InEnglishEdit: TTntEdit
    Left = 120
    Top = 18
    Width = 400
    Height = 21
    TabOrder = 0
  end
  object InTransEdit: TTntEdit
    Left = 120
    Top = 52
    Width = 400
    Height = 21
    TabOrder = 1
  end
  object OutTransEdit: TTntEdit
    Left = 120
    Top = 86
    Width = 400
    Height = 21
    TabOrder = 2
  end
  object ButtonRebuild: TTntButton
    Left = 528
    Top = 18
    Width = 105
    Height = 89
    Caption = 'Rebuild'
    TabOrder = 3
    OnClick = ButtonRebuildClick
  end
  object ListBoxDebug: TTntListBox
    Left = 18
    Top = 128
    Width = 615
    Height = 429
    ItemHeight = 13
    TabOrder = 4
  end
end
