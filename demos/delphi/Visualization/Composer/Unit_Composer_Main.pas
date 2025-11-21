{*********************************************}
{  TeeBI Software Library                     }
{  Composer Example                           }
{  Copyright (c) 2025 by Steema Software      }
{  All Rights Reserved                        }
{*********************************************}
unit Unit_Composer_Main;

{
  This TeeBI example shows how the TBIComposer control automatically
  creates the necessary charts and controls from any Data (TDataItem) object.

  BIComposer1.Data := MyData
}

interface

uses
  Winapi.Windows, Winapi.Messages,

  // RTL
  System.SysUtils, System.Variants, System.Classes,

  // VCL
  Vcl.Graphics, Vcl.StdCtrls, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,

  // TeeBI core
  BI.DataItem, BI.Summary,

  // TeeBI controls
  VCLBI.DataControl, VCLBI.Visualizer, VCLBI.Grid,

  // VCL Editors
   VCLBI.Editor.Visualizer, VCLBI.Editor.Summary, VCLBI.DataViewer,

  // Important, use this optional unit to display charts:
  VCLBI.Visualizer.Chart, Vcl.ComCtrls;

type
  TMainForm = class(TForm)
    PanelTop: TPanel;
    PanelExample: TPanel;
    Label1: TLabel;
    LBTest: TListBox;
    Splitter1: TSplitter;
    PanelRight: TPanel;
    MemoSQL: TMemo;
    BIGrid1: TBIGrid;
    BIComposer1: TBIComposer;
    PanelLeft: TPanel;
    Splitter2: TSplitter;
    Button1: TButton;
    ButtonQuery: TButton;
    PageControl1: TPageControl;
    TabOptions: TTabSheet;
    TabQuery: TTabSheet;
    Button2: TButton;
    Splitter3: TSplitter;
    procedure LBTestClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ButtonQueryClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }

    Data : TDataItem;
    Summary : TSummary;

    VisualizerEditor : TVisualizerEditor;
    SummaryEditor : TSummaryEditor;

    procedure ExecuteQuery;
    procedure RecalculateSummary(Sender: TObject);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}


uses
  // Detect which TeeChart we have, "Pro" or "Lite
  VCLTee.TeeConst, VCLTee.TeeProcs,

  {$IFDEF FPC}
  {$DEFINE TEEPRO} // <-- TeeChart Lite or Pro ?
  {$ELSE}

  {$IF TeeMsg_TeeChartPalette='TeeChart'}
  {$DEFINE TEEPRO} // <-- TeeChart Lite or Pro ?
  {$ENDIF}
  {$ENDIF}

  {$IFDEF TEEPRO}
  // Enable "Pro" charting styles
  VCLBI.Chart.ThreeD, VCLBI.Chart.Financial, VCLBI.Chart.Geo,
  {$ENDIF}

  BI.Tests.SummarySamples, BI.SQL;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  TVisualizerEditor.Edit(Self,BIComposer1);  // show the composer editor
end;

procedure TMainForm.Button2Click(Sender: TObject);
begin
  TDataViewer.View(Self,Samples.Demo);
end;

procedure TMainForm.ButtonQueryClick(Sender: TObject);
begin
  if TSummaryEditor.Edit(Self,Summary) then // show the query editor
     ExecuteQuery;
end;

type
  TDataAccess=class(TDataItem);

procedure TMainForm.ExecuteQuery;
begin
  // Obtain the SQL as text from the query:
  MemoSQL.Text:=TBISQL.From(Summary);

  // Execute the query:
  Data.Free;
  Data:=TDataItem.Create(Summary);

  TDataAccess(Data).KeepProvider:=True; // <-- hack, to remove in future updates

  // Set the query results to grid and composer:
  BIGrid1.Data:=Data;
  BIComposer1.Data:=Data;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  TSampleSummaries.AddExamples(LBTest.Items);  // adds the list of examples

  VisualizerEditor:=TVisualizerEditor.Embedd(Self,TabOptions);

  SummaryEditor:=TSummaryEditor.Embedd(Self,TabQuery);
  SummaryEditor.OnRecalculate:=RecalculateSummary;
end;

procedure TMainForm.RecalculateSummary(Sender: TObject);
begin
  ExecuteQuery;
  VisualizerEditor.Refresh(BIComposer1);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  Data.Free;
end;

procedure TMainForm.LBTestClick(Sender: TObject);
begin
  // Create the query
  Summary.Free;
  Summary:=Samples.CreateSummary(Self,LBTest.ItemIndex);

  Summary.Description:=LBTest.Items[LBTest.ItemIndex];

  ExecuteQuery;

  ButtonQuery.Enabled:=True;

  SummaryEditor.Refresh(Summary);
  VisualizerEditor.Refresh(BIComposer1);
end;

end.
