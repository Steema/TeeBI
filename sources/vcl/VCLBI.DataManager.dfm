object DataManager: TDataManager
  Left = 320
  Top = 203
  ActiveControl = ESearch
  Caption = 'Data Manager'
  ClientHeight = 555
  ClientWidth = 789
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = True
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 224
    Top = 41
    Height = 473
    ExplicitHeight = 386
  end
  object PanelButtons: TPanel
    Left = 0
    Top = 514
    Width = 789
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitTop = 451
    ExplicitWidth = 633
    object PanelOk: TPanel
      Left = 600
      Top = 0
      Width = 189
      Height = 41
      Align = alRight
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitLeft = 444
      object BOk: TButton
        Left = 14
        Top = 8
        Width = 75
        Height = 25
        Caption = 'Select'
        Default = True
        Enabled = False
        ModalResult = 1
        TabOrder = 0
      end
      object BCancel: TButton
        Left = 102
        Top = 8
        Width = 75
        Height = 25
        Cancel = True
        Caption = 'Cancel'
        ModalResult = 2
        TabOrder = 1
      end
    end
    object BAdd: TButton
      Left = 9
      Top = 6
      Width = 75
      Height = 25
      Caption = '&Add...'
      Enabled = False
      TabOrder = 1
      OnClick = BAddClick
    end
    object BDelete: TButton
      Left = 102
      Top = 6
      Width = 75
      Height = 25
      Caption = '&Remove...'
      Enabled = False
      TabOrder = 2
      OnClick = BDeleteClick
    end
    object BRename: TButton
      Left = 198
      Top = 6
      Width = 75
      Height = 25
      Caption = 'Re&name...'
      Enabled = False
      TabOrder = 3
      OnClick = BRenameClick
    end
  end
  object PanelSearch: TPanel
    Left = 0
    Top = 0
    Width = 789
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    OnResize = PanelSearchResize
    ExplicitWidth = 633
    object PanelSearchCombo: TPanel
      Left = 0
      Top = 0
      Width = 516
      Height = 41
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 0
      OnResize = PanelSearchComboResize
      ExplicitWidth = 360
      object LSearch: TLabel
        Left = 9
        Top = 14
        Width = 37
        Height = 13
        Caption = '&Search:'
        FocusControl = ESearch
      end
      object LabelCloseStore: TLabel
        Left = 308
        Top = 17
        Width = 45
        Height = 13
        Caption = 'Store >>'
        OnClick = LabelCloseStoreClick
      end
      object ESearch: TEdit
        Left = 52
        Top = 14
        Width = 172
        Height = 21
        TabOrder = 0
        OnChange = ESearchChange
      end
    end
    object PanelStores: TPanel
      Left = 516
      Top = 0
      Width = 273
      Height = 41
      Align = alRight
      BevelOuter = bvNone
      TabOrder = 1
      Visible = False
      OnClick = PanelStoresClick
      ExplicitLeft = 360
      ExplicitTop = -6
      object BManageStores: TButton
        Left = 197
        Top = 10
        Width = 69
        Height = 25
        Caption = '&Manage...'
        TabOrder = 0
        OnClick = BManageStoresClick
      end
      object CBStores: TComboBox
        Left = 6
        Top = 14
        Width = 179
        Height = 21
        Style = csDropDownList
        DropDownCount = 25
        TabOrder = 1
        OnChange = CBStoresChange
      end
    end
  end
  object Tree: TTreeView
    Left = 0
    Top = 41
    Width = 224
    Height = 473
    Align = alLeft
    HideSelection = False
    HotTrack = True
    Indent = 19
    PopupMenu = DataMenu
    ReadOnly = True
    TabOrder = 2
    OnChange = TreeChange
    OnDblClick = TreeDblClick
    OnExpanding = TreeExpanding
  end
  object PageControl1: TPageControl
    Left = 227
    Top = 41
    Width = 562
    Height = 473
    ActivePage = TabData
    Align = alClient
    TabOrder = 3
    OnChange = PageControl1Change
    ExplicitLeft = 230
    ExplicitTop = 43
    ExplicitWidth = 932
    ExplicitHeight = 768
    object TabViewData: TTabSheet
      Caption = 'Data'
      ImageIndex = 3
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object BIGrid1: TBIGrid
        Left = 0
        Top = 0
        Width = 554
        Height = 445
        Align = alClient
        UseDockManager = False
        ParentBackground = False
        ParentColor = False
        TabOrder = 0
        ExplicitLeft = 40
        ExplicitTop = 128
        ExplicitWidth = 320
        ExplicitHeight = 120
      end
    end
    object TabSettings: TTabSheet
      Caption = 'Settings'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
    end
    object TabData: TTabSheet
      Caption = 'Import'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object MemoImportLog: TMemo
        Left = 0
        Top = 273
        Width = 554
        Height = 172
        Align = alClient
        ScrollBars = ssBoth
        TabOrder = 0
        Visible = False
        WordWrap = False
        ExplicitWidth = 398
        ExplicitHeight = 109
      end
      object PanelDataTop: TPanel
        Left = 0
        Top = 0
        Width = 554
        Height = 273
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        ExplicitLeft = -1
        ExplicitWidth = 924
        object MemoDataInfo: TMemo
          Left = 0
          Top = 164
          Width = 554
          Height = 109
          Align = alClient
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
          ExplicitLeft = 11
          ExplicitTop = 178
          ExplicitWidth = 254
          ExplicitHeight = 89
        end
        object Panel1: TPanel
          Left = 0
          Top = 0
          Width = 554
          Height = 164
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 1
          ExplicitWidth = 924
          object Label2: TLabel
            Left = 11
            Top = 44
            Width = 57
            Height = 13
            Caption = 'Last import:'
          end
          object LLastImport: TLabel
            Left = 11
            Top = 63
            Width = 5
            Height = 13
            Caption = '?'
          end
          object BViewData: TButton
            Left = 129
            Top = 10
            Width = 102
            Height = 25
            Caption = '&View Data...'
            Enabled = False
            TabOrder = 0
            OnClick = BViewDataClick
          end
          object BImportNow: TButton
            Left = 11
            Top = 10
            Width = 75
            Height = 25
            Caption = 'Import &Now'
            TabOrder = 1
            OnClick = BImportNowClick
          end
          object CBParallel: TCheckBox
            Left = 11
            Top = 112
            Width = 190
            Height = 17
            Caption = 'Use multiple CPU'
            TabOrder = 2
            OnClick = CBParallelClick
          end
          object CBStoponerrors: TCheckBox
            Left = 11
            Top = 135
            Width = 182
            Height = 17
            Caption = 'Stop on errors'
            TabOrder = 3
          end
          object ImportProgress: TProgressBar
            Left = 11
            Top = 82
            Width = 254
            Height = 17
            TabOrder = 4
            Visible = False
          end
        end
      end
    end
    object TabLinks: TTabSheet
      Caption = 'Links'
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 96
    Top = 256
    object Files1: TMenuItem
      Caption = '&Files or folders'
      OnClick = Files1Click
    end
    object DatabaseServer1: TMenuItem
      Caption = '&Database Server'
      OnClick = DatabaseServer1Click
    end
    object BIWeb1: TMenuItem
      Caption = '&BI Web'
      OnClick = BIWeb1Click
    end
    object Custommanual1: TMenuItem
      Caption = '&Custom (manual)'
      OnClick = Custommanual1Click
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object NewQuery1: TMenuItem
      Caption = 'New &Query...'
      OnClick = NewQuery1Click
    end
  end
  object DataMenu: TPopupMenu
    Left = 88
    Top = 120
    object ViewData1: TMenuItem
      Caption = '&View Data...'
      OnClick = ViewData1Click
    end
  end
end
