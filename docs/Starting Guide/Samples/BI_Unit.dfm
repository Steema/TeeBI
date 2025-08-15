object FormTests: TFormTests
  Left = 0
  Top = 0
  Caption = 'TeeBI Unit Tests'
  ClientHeight = 617
  ClientWidth = 934
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 934
    Height = 41
    Align = alTop
    TabOrder = 0
    object Button1: TButton
      Left = 8
      Top = 9
      Width = 75
      Height = 25
      Caption = 'Test &All'
      TabOrder = 0
      OnClick = Button1Click
    end
  end
  object Tree: TTreeView
    Left = 0
    Top = 41
    Width = 265
    Height = 503
    Align = alLeft
    Indent = 19
    ReadOnly = True
    TabOrder = 1
    OnChange = TreeChange
  end
  object Memo1: TMemo
    Left = 0
    Top = 544
    Width = 934
    Height = 73
    Align = alBottom
    ScrollBars = ssBoth
    TabOrder = 2
    Visible = False
    WordWrap = False
  end
  object BIGrid1: TBIGrid
    Left = 265
    Top = 41
    Width = 669
    Height = 503
    Align = alClient
    UseDockManager = False
    ParentBackground = False
    ParentColor = False
    TabOrder = 3
  end
end
