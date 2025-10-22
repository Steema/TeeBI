object FormDateTimeConvert: TFormDateTimeConvert
  Left = 0
  Top = 0
  Caption = 'TDateTimeConvert example, from / to single column to a structure'
  ClientHeight = 587
  ClientWidth = 1088
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object BIGrid1: TBIGrid
    Left = 0
    Top = 0
    Width = 201
    Height = 587
    Align = alLeft
    UseDockManager = False
    ParentBackground = False
    ParentColor = False
    TabOrder = 0
    ExplicitHeight = 441
  end
  object Panel1: TPanel
    Left = 201
    Top = 0
    Width = 89
    Height = 587
    Align = alLeft
    TabOrder = 1
    ExplicitLeft = 176
    ExplicitTop = 80
    ExplicitHeight = 169
    object Button1: TButton
      Left = 6
      Top = 24
      Width = 75
      Height = 25
      Caption = '-->>'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 6
      Top = 88
      Width = 75
      Height = 25
      Caption = '<<--'
      Enabled = False
      TabOrder = 1
      OnClick = Button2Click
    end
  end
  object BIGrid2: TBIGrid
    Left = 290
    Top = 0
    Width = 798
    Height = 587
    Align = alClient
    UseDockManager = False
    ParentBackground = False
    ParentColor = False
    TabOrder = 2
    ExplicitLeft = 248
    ExplicitTop = 120
    ExplicitWidth = 320
    ExplicitHeight = 120
  end
end
