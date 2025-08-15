{*********************************************}
{  TeeBI Software Library                     }
{  Unit Tests                                 }
{  Copyright (c) 2015-2025 by Steema Software }
{  All Rights Reserved                        }
{*********************************************}
unit BI_Unit;

// TeeBI Unit Tests

{
  This demo tests a list of TeeBI features
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.IOUtils,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,

  BI.DataItem, BI.Arrays, BI.Info, BI.Expressions,
  BI.Persist, BI.DataSource, BI.DataSet, BI.Summary, BI.Expression,
  BI.Web,

  BI.Excel, BI.CSV, BI.JSON, BI.XMLData, BI.HTML,

  {.$DEFINE TEST_TMS}   // <-- Use TMS FlexCel components to export to Excel

  {$IFDEF TEST_TMS}
  BI.Excel.TMSFlexCel,
  {$ENDIF}

  {$IFDEF TEEGRID}
  VCLBI.Grid.TeeGrid,
  {$ENDIF}

  BI_Demo_Data, VCLBI.DataControl, VCLBI.Grid;

type
  TFormTests = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Tree: TTreeView;
    Memo1: TMemo;
    BIGrid1: TBIGrid;
    procedure FormCreate(Sender: TObject);
    procedure TreeChange(Sender: TObject; Node: TTreeNode);
    procedure Button1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    Last : TDataItem;

    procedure FillNodes(const Items:TTreeNodes);
    procedure Test(const Node: TTreeNode);
    procedure TryDestroyPreviousData;
  public
    { Public declarations }
  end;

var
  FormTests: TFormTests;

implementation

{$R *.dfm}

{$IFDEF MSWINDOWS}
uses
  ShellApi;
{$ENDIF}

type
  TTest=function:TDataItem;
  TStringTest=function:String;
  TProcedureTest=procedure;
  TDataSetTest=procedure(const ADataSet:TBIDataSet);

const
  Samples=1000;

// Simple column:
function SimpleColumn:TDataItem;
var t : TInteger;
begin
  result:=TDataItem.Create(TDataKind.dkInt32);

  result.Name:='Simple Column';
  result.Resize(Samples);

  for t:=0 to Samples-1 do
      result.Int32Data[t]:=t;
end;

// Simple table with just one column:
function SimpleTable:TDataItem;
var Col1,
    Col2 : TDataItem;
    t : TInteger;
begin
  result:=TDataItem.Create(True);

  result.Name:='Simple Table';

  // Add two columns to table
  Col1:=result.Items.Add('Int32',TDataKind.dkInt32);
  Col2:=result.Items.Add('Int64',TDataKind.dkInt64);

  result.Resize(Samples);

  // Just sample values
  for t:=0 to Samples-1 do
  begin
    Col1.Int32Data[t]:=t;
    Col2.Int64Data[t]:=Samples-t-1;
  end;
end;

// Simple table with two columns:
function TwoColumns:TDataItem;
var A,B : TDataItem;
    t : TInteger;
begin
  result:=TDataItem.Create(True);

  result.Name:='Two Columns';

  A:=result.Items.Add('Text',TDataKind.dkText);
  B:=result.Items.Add('Int32',TDataKind.dkInt32);

  result.Resize(Samples);

  for t:=0 to Samples-1 do
  begin
    A.TextData[t]:='abc '+IntToStr(t);
    B.Int32Data[t]:=t;
  end;
end;

// Simple data item with several tables:
function SeveralTables:TDataItem;
begin
  result:=TDataItem.Create;

  result.Name:='Several Tables';

  result.Items.Add(SimpleTable);
  result.Items.Add(SimpleColumn);
  result.Items.Add(TwoColumns);
end;

// Returns the "information" of a given data item:
function DataInfo:TDataItem;
var C : TDataItem;
begin
  C:=TwoColumns;
  try
    result:=TDataInfo.Create(C);
  finally
    C.Free;
  end;
end;

// Returns the extended "information + stats" of a given data item:
function DataInfoStats:TDataItem;
var C : TDataItem;
begin
  C:=TwoColumns;
  try
    result:=TDataItemsInfo.ItemsOf(C);
  finally
    C.Free;
  end;
end;

// Add a new column to a table, using an expression;
function CalculatedData:TDataItem;
begin
  // Use previous example:
  result:=TwoColumns;
  result.Items.Add(TExpressionColumn.From(result,'Int32 + Int32',True,'Twice Number'));
end;

// Just a helper function to build a table with three columns,
// filled with random data:
function CreateRandomTable:TDataItem;

  function RandomString:String;
  const
    Colors:Array[0..5] of String=('Red','Blue','Green','Yellow','Black','White');
  begin
    result:=Colors[Random(6)];
  end;

var A,B,C,D : TDataItem;
    t : TInteger;
begin
  result:=TDataItem.Create(True);

  A:=result.Items.Add('Color',TDataKind.dkText);
  B:=result.Items.Add('Int32',TDataKind.dkInt32);
  C:=result.Items.Add('Single',TDataKind.dkSingle);
  D:=result.Items.Add('Date',TDataKind.dkDateTime);

  result.Resize(Samples);

  for t:=0 to Samples-1 do
  begin
    A.TextData[t]:=RandomString;
    B.Int32Data[t]:=Random(Samples);
    C.SingleData[t]:=1+Random(Samples)*0.01;

    // Use last date value to increment a random day:
    if t=0 then
       D.DateTimeData[t]:=Round(Now)
    else
       D.DateTimeData[t]:=D.DateTimeData[t-1]+Random(10);
  end;
end;

// Global data "demo" to use at tests:
var
  _RandomTable : TDataItem;

function RandomTable:TDataItem;
begin
  if _RandomTable=nil then
     _RandomTable:=CreateRandomTable;

  result:=_RandomTable;
end;

// Simple sorting by just one column:
function SortByColumn:TDataItem;
begin
  result:=RandomTable;
  result.SortBy(result['Single']);
end;

// Simple descending sorting by just one column:
function SortByColumnDescending:TDataItem;
begin
  result:=RandomTable;
  result.SortBy(result['Single'],False);
end;

// Global data "demo" to use at tests:
var
  _Demo : TDataItem;

function Demo:TDataItem;
begin
  if _Demo=nil then
     _Demo:=CreateDemoData;

  result:=_Demo;
end;

// Simple sorting by just one column that contains text,
// in case-insensitive mode:
function SortByCaseInsentitiveText:TDataItem;
begin
  result:=Demo['Customers'];
  result.SortBy(result['Name'],True,True);
end;

// Sort table using an expression as sort order:
function SortByExpression:TDataItem;
begin
  // Use previous example:
  result:=RandomTable;

  // Sort descending using the expression:
  TDataItemSort.By(result,'Int32 / Single', False);
end;

// Sort a table cursor using an expression as sort order:
procedure FilterByExpression(const ADataSet:TBIDataSet);
begin
  // Use previous example:
  ADataSet.Data:=RandomTable;

  // Parse expression to use as filter:
  ADataSet.Cursor.Filter:=TDataExpression.FromString(ADataSet.Data,'(Single>5) and (Single<=8)');

  // Open dataset to refresh grid:
  ADataSet.Open;
end;

procedure TFormTests.Button1Click(Sender: TObject);
var t : Integer;
begin
  for t:=0 to Tree.Items.Count-1 do
      Test(Tree.Items[t]);
end;

// Persist a data item to a disk file
function SaveColumn:TDataItem;
begin
  result:=SimpleColumn;
  TDataItemPersistence.Save(result,TStore.FullPath('SimpleColumn'));
end;

// Persist a data item to a disk file
function SaveTable:TDataItem;
begin
  result:=SimpleTable;
  TDataItemPersistence.Save(result,TStore.FullPath('SimpleTable'));
end;

// Load a data item from a disk file
function LoadColumn:TDataItem;
begin
  result:=TDataItemPersistence.Load(TStore.FullPath('SimpleColumn'));
end;

// Load a data item from a disk file
function LoadTable:TDataItem;
begin
  result:=TDataItemPersistence.Load(TStore.FullPath('SimpleTable'));
end;

// Simple summary, returns the sum of values of a single column:
function SimpleSummarySum:TDataItem;
var S : TSummary;
begin
  S:=TSummary.Create(nil);
  try
    S.AddMeasure(RandomTable['Single'],TAggregate.Sum);

    result:=S.Calculate;
  finally
    S.Free;
  end;
end;

// Simple summary, returning two measures:
function TwoMeasureSummary:TDataItem;
var S : TSummary;
    Data : TDataItem;
begin
  Data:=RandomTable;

  S:=TSummary.Create(nil);
  try
    S.AddMeasure(Data['Single'],TAggregate.Sum);
    S.AddMeasure(Data['Int32'],TAggregate.Average);

    result:=S.Calculate;
  finally
    S.Free;
  end;
end;

// Return the sum of a column by another column:
function SumByColorSummary:TDataItem;
var S : TSummary;
    Data : TDataItem;
begin
  Data:=RandomTable;

  S:=TSummary.Create(nil);
  try
    S.AddMeasure(Data['Single'],TAggregate.Sum);
    S.AddGroupBy(Data['Color']);

    result:=S.Calculate;
  finally
    S.Free;
  end;
end;

// Return the sum of a column by another column:
function SumByColorSummaryHaving:TDataItem;
var S : TSummary;
    Data : TDataItem;
    Sum : TSummaryItem;
begin
  Data:=RandomTable;

  S:=TSummary.Create(nil);
  try
    Sum:=S.AddMeasure(Data['Single'],TAggregate.Sum);
    S.AddGroupBy(Data['Color']);

    S.Having.Add(Sum,'>1000');

    result:=S.Calculate;
  finally
    S.Free;
  end;
end;

// Return the average of a column by two groups:
function AverageByColor_and_YearOfDate:TDataItem;
var S : TSummary;
    Data : TDataItem;
begin
  // Use previous RandomTable example as source data:
  Data:=RandomTable;

  S:=TSummary.Create(nil);
  try
    S.AddMeasure(Data['Single'],TAggregate.Average);
    S.AddGroupBy(Data['Color']);
    S.AddGroupBy(Data['Date']).DatePart:=TDateTimePart.Year;

    result:=S.Calculate;

    result.Name:='Average Single by Color and Year of Date';
  finally
    S.Free;
  end;
end;

// Return the count of a column by two groups:
function Do_SumByColor_and_YearOfDate(const APercentage:TCalculationPercentage):TDataItem;
var S : TSummary;
    Data : TDataItem;
begin
  // Use previous RandomTable example as source data:
  Data:=RandomTable;

  S:=TSummary.Create(nil);
  try
    S.AddMeasure(Data['Single'],TAggregate.Sum).Calculation.Percentage:=APercentage;
    S.AddGroupBy(Data['Color']);
    S.AddGroupBy(Data['Date']).DatePart:=TDateTimePart.Year;

    result:=S.Calculate;
  finally
    S.Free;
  end;
end;

function SumByColor_and_YearOfDate:TDataItem;
begin
  result:=Do_SumByColor_and_YearOfDate(TCalculationPercentage.None);
end;

function PercentSumByColor_and_YearOfDate:TDataItem;
begin
  result:=Do_SumByColor_and_YearOfDate(TCalculationPercentage.Column);
end;

// Return the Cumulative sum of a column by another column:
function CumulativeSumByColorSummary:TDataItem;
var S : TSummary;
    Data : TDataItem;
    Sum : TMeasure;
begin
  Data:=RandomTable;

  S:=TSummary.Create(nil);
  try
    Sum:=S.AddMeasure(Data['Single'],TAggregate.Sum);
    Sum.Calculation.Running:=TCalculationRunning.Cumulative;

    S.AddGroupBy(Data['Color']);

    result:=S.Calculate;
  finally
    S.Free;
  end;
end;

// Queries

function SelectCustomers:TDataItem;
var Query : TDataSelect;
begin
  Query:=TDataSelect.Create(nil);
  try
    Query.Add(Demo['Customers']);
    result:=Query.Calculate;
  finally
    Query.Free;
  end;
end;

function SelectOrdersDateCustomerName:TDataItem;
var Query : TDataSelect;
begin
  Query:=TDataSelect.Create(nil);
  try
    Query.Add(Demo['Orders']['Date']);
    Query.Add(Demo['Customers']['Name']);
    result:=Query.Calculate;
  finally
    Query.Free;
  end;
end;

function SelectOrdersDate_SortedCustomerName:TDataItem;
var Query : TDataSelect;
begin
  Query:=TDataSelect.Create(nil);
  try
    Query.Add(Demo['Customers']['Name']);
    Query.SortBy.Add(Demo['Customers']['Name'],True,True); // case-insensitive

    Query.Add(Demo['Orders']['Date']);

    result:=Query.Calculate;
  finally
    Query.Free;
  end;
end;

function SelectOrdersDateCustomerNameIntel:TDataItem;
var Query : TDataSelect;
begin
  Query:=TDataSelect.Create(nil);
  Query.Add(Demo['Orders']['Date']);
  Query.Add(Demo['Customers']['Name']);
  Query.Filter:=TDataFilter.FromString(Demo,'Customers.Name="intel"');

  result:=TDataItem.Create(Query);  // <-- Set Query as Provider for result
end;

function SelectApacheAB:TDataItem;
var
  Item, A, B: TDataItem;
  Query: TDataSelect;

begin
     Item:=TDataItem.Create(True);
     A:=Item.Items.Add('a', TDataKind.dkText);
     B:=Item.Items.Add('b', TDataKind.dkInt32);

     Item.Resize(4);

     A.TextData[0]:='a';
     A.TextData[1]:='b';
     A.TextData[2]:='c';
     A.TextData[3]:='d';

     B.Int32Data[0]:=1;
     B.Int32Data[1]:=10;
     B.Int32Data[2]:=10;
     B.Int32Data[3]:=100;

     Query:=TDataSelect.Create(nil);
     try
       Query.Add(Item['a']);
       Query.Add(Item['b']);
       Query.Filter:=TDataFilter.FromString(Item,'b=10');
       result:=Query.Calculate;
     finally
       Query.Free;
       Item.Free;
     end;
end;


function SelectOrdersNotIsNullDateCustomerIntel:TDataItem;
var Query : TDataSelect;
begin
  Query:=TDataSelect.Create(nil);
  Query.Add(Demo['Orders']);
  Query.Filter:=TDataFilter.FromString(Demo,'(not IsNull(Orders.Date)) and (Customers.Name="intel")');

  result:=TDataItem.Create(Query);  // <-- Set Query as Provider for result
end;

function DistinctOrdersQuantity:TDataItem;
var Query : TDataSelect;
begin
  Query:=TDataSelect.Create(nil);
  try
    Query.Add(Demo['Orders']['Quantity']);
    Query.Distinct:=True;
    Query.SortBy.Add(Query.Items[0].Data);

    result:=Query.Calculate;
  finally
    Query.Free;
  end;
end;

function OrdersPriceByQuantity:TDataItem;
var Query : TDataSelect;
begin
  Query:=TDataSelect.Create(nil);
  try
    Query.Add(Demo['Orders'],'Price * Quantity');
    result:=Query.Calculate;
  finally
    Query.Free;
  end;
end;

function Top10_OrdersPrice:TDataItem;
var Query : TDataSelect;
begin
  Query:=TDataSelect.Create(nil);
  try
    Query.Add(Demo['Orders']['Price']);
    Query.Distinct:=True;
    Query.SortBy.Add(Demo['Orders']['Price'],False); // descending order

    Query.Max:=10;

    result:=Query.Calculate;
  finally
    Query.Free;
  end;
end;

// Add a new column to a table, using an expression that refers to a column
// in a "master" table (the Customer Name for each Order)
function ColumnFromMaster:TDataItem;
const
  TheCustomerLookup='The Customer';
begin
  result:=Demo['Orders'];

  // Add a new column to Orders, (if it does not already exists)
  // with the Customers table field: "Name" values:
  if not result.Items.Exists(TheCustomerLookup) then
     result.Items.Add(TExpressionColumn.From(result,'Customers.Name',True,TheCustomerLookup));
end;

// Just make sure www.steema.cat web is configured as "Steema" TStore
procedure CheckSteemaWeb;
begin
  if not TStores.Exists('Steema') then
     TStores.Add('Steema','web:steema.cat');
end;

// Called when a TStore.Load fails
function WebError(const Sender:TObject; const Error:String):Boolean;
begin
  ShowMessage(Error);

  // Return True to skip raising an exception
  result:=True;
end;

// Load SQLite_Demo Products table from remote www.steema.cat BIWeb server
function SampleFromSteemaWeb:TDataItem;
begin
  CheckSteemaWeb;

  // Load a data item (single web request). "WebError" is optional.
  result:=TStore.Load('Steema','SQLite_Demo|Products',WebError);

  // Another example: issue two web server requests, one for
  // the SQLite_Demo database catalog information, and another one
  // asking the "Products" table

  // result:=TStore.Load('Steema','SQLite_Demo',WebError)['Products'];
end;

// Execute an SQL query remotely at www.steema.cat and return the result
function RemoteQueryFromSteemaWeb:TDataItem;
begin
  CheckSteemaWeb;

  result:=TBIWebClient.Query('Steema','SQLite_Demo','select * from Customers where City="Madrid"');
end;

// Export any TDataItem to JSON
function ExportToJSON:String;
var tmp : TDataItem;
begin
  tmp:=SumByColorSummary;
  try
    result:=TBIJSONExport.AsString(tmp);
  finally
    tmp.Free;
  end;
end;

// Export any TDataItem to XML
function ExportToXML:String;
var tmp : TDataItem;
begin
  tmp:=SumByColorSummary;
  try
    result:=TBIXMLExport.AsString(tmp);
  finally
    tmp.Free;
  end;
end;

// Export any TDataItem to CSV
function ExportToCSV:String;
var tmp : TDataItem;
begin
  tmp:=SumByColorSummary;
  try
    result:=TBICSVExport.AsString(tmp);
  finally
    tmp.Free;
  end;
end;

// Export any TDataItem to HTML
function ExportToHTML:String;
var tmp : TDataItem;
begin
  tmp:=SumByColorSummary;
  try
    result:=TBIHTMLExport.AsString(tmp);
  finally
    tmp.Free;
  end;
end;

// Export any TDataItem to Microsoft Excel
procedure ExportToExcel;
var tmp : TDataItem;
    tmpFile : String;
begin
  tmp:=AverageByColor_and_YearOfDate; // SumByColorSummary;
  try
    tmpFile:=TPath.Combine(TPath.GetTempPath,'test.xlsx');

    // Test: Use TMS FlexCel engine:

    {$IFDEF TEST_TMS}
    TBIExcelExport.Engine:=TBITMSFlexCel;
    {$ENDIF}

    if TFile.Exists(tmpFile) then
       TFile.Delete(tmpFile);

    TBIExcelExport.SaveToFile(tmp,tmpFile);

    // Show exported Excel file:
    {$IFDEF MSWINDOWS}
    ShellExecute(0,'open',PChar(tmpFile),nil,nil,SW_SHOWNORMAL);
    {$ENDIF}
  finally
    tmp.Free;
  end;
end;

procedure TFormTests.FillNodes(const Items:TTreeNodes);
var tmp : TTreeNode;
begin
  tmp:=Items.AddChild(nil,'Basic');
    Items.AddChildObject(tmp,'Simple Column',@SimpleColumn);
    Items.AddChildObject(tmp,'Simple Table',@SimpleTable);
    Items.AddChildObject(tmp,'Two Columns',@TwoColumns);
    Items.AddChildObject(tmp,'Two Tables',@SeveralTables);

  tmp:=Items.AddChild(nil,'Info');
    Items.AddChildObject(tmp,'Data Info',@DataInfo);
    Items.AddChildObject(tmp,'Data Info and Stats',@DataInfoStats);

  tmp:=Items.AddChild(nil,'Persist');
    Items.AddChildObject(tmp,'Save Column',@SaveColumn);
    Items.AddChildObject(tmp,'Load Column',@LoadColumn);
    Items.AddChildObject(tmp,'Save Table',@SaveTable);
    Items.AddChildObject(tmp,'Load Table',@LoadTable);

  tmp:=Items.AddChild(nil,'Sorting');
    Items.AddChildObject(tmp,'By Column "Single"',@SortByColumn);
    Items.AddChildObject(tmp,'By Column "Single", descending',@SortByColumnDescending);
    Items.AddChildObject(tmp,'By Text, case-insensitive',@SortByCaseInsentitiveText);

  tmp:=Items.AddChild(nil,'Expressions');
    Items.AddChildObject(tmp,'Calculated Column',@CalculatedData);
    Items.AddChildObject(tmp,'Column from Master',@ColumnFromMaster);
    Items.AddChildObject(tmp,'Sort by Expression "Int32 / Single"',@SortByExpression);

  tmp:=Items.AddChild(nil,'Filtering');
    Items.AddChildObject(tmp,'(Single>5) and (Single<=8)',@FilterByExpression);

  tmp:=Items.AddChild(nil,'Queries');
    Items.AddChildObject(tmp,'* from Customers',@SelectCustomers);
    Items.AddChildObject(tmp,'Orders.Date, Customers.Name',@SelectOrdersDateCustomerName);
    Items.AddChildObject(tmp,'Orders.Date, sorted by Customers.Name',@SelectOrdersDate_SortedCustomerName);
    Items.AddChildObject(tmp,'Distinct Orders Quantity',@DistinctOrdersQuantity);
    Items.AddChildObject(tmp,'Orders Price * Quantity',@OrdersPriceByQuantity);
    Items.AddChildObject(tmp,'Orders.Date, Customers.Name = "intel"',@SelectOrdersDateCustomerNameIntel);
    Items.AddChildObject(tmp,'Top 10 Orders.Price',@Top10_OrdersPrice);
    Items.AddChildObject(tmp,'not IsNull(Orders.Date)',@SelectOrdersNotIsNullDateCustomerIntel);

  tmp:=Items.AddChild(nil,'Summaries');
    Items.AddChildObject(tmp,'Simple sum of a column',@SimpleSummarySum);
    Items.AddChildObject(tmp,'Two measures',@TwoMeasureSummary);
    Items.AddChildObject(tmp,'Sum by Color',@SumByColorSummary);
    Items.AddChildObject(tmp,'Average by Color and Year of Date',@AverageByColor_and_YearOfDate);
    Items.AddChildObject(tmp,'Sum by Color and Year of Date',@SumByColor_and_YearOfDate);
    Items.AddChildObject(tmp,'Percents of Sum by Color and Year of Date',@PercentSumByColor_and_YearOfDate);
    Items.AddChildObject(tmp,'Sum by Color, having Sum>1000',@SumByColorSummaryHaving);
    Items.AddChildObject(tmp,'Cumulative Sum by Color',@CumulativeSumByColorSummary);

  tmp:=Items.AddChild(nil,'Web Store');
  {
    No server is currently running at steema web !!
    Items.AddChildObject(tmp,'Load sample from Steema web',@SampleFromSteemaWeb);
    Items.AddChildObject(tmp,'Remote Query from Steema web',@RemoteQueryFromSteemaWeb);
  }

  tmp:=Items.AddChild(nil,'Exporting');
    Items.AddChildObject(tmp,'JSON',@ExportToJSON);
    Items.AddChildObject(tmp,'XML',@ExportToXML);
    Items.AddChildObject(tmp,'CSV',@ExportToCSV);
    Items.AddChildObject(tmp,'HTML',@ExportToHTML);

    if (not (TBIExcelExport.Engine=TBIExcelEngine)) or
       TBIExcelEngine.IsExcelInstalled then
         Items.AddChildObject(tmp,'Microsoft Excel',@ExportToExcel);

  tmp:=Items.AddChild(nil,'Apache');
    Items.AddChildObject(tmp,'Select a,b',@SelectApacheAB);
end;

procedure TFormTests.FormCreate(Sender: TObject);
begin
  FillNodes(Tree.Items);

  Tree.Items[0].Expand(True);
end;

procedure TFormTests.TryDestroyPreviousData;

  function IsFromStore(const AData:TDataItem):Boolean;
  var tmp : String;
  begin
    tmp:=TStore.OriginOf(AData,'');
    result:=SameText(Copy(tmp,1,7),'Steema:');
  end;

begin
  // Do not destroy previous data that we want to preserve
  if Last<>nil then
     if (not IsFromStore(Last)) and
        (not Last.IsChildOf(Demo)) and
        (not ((Last=RandomTable) or Last.IsChildOf(RandomTable))) then
     begin
       Last.Free;
       Last:=nil;
     end;
end;

procedure TFormTests.FormDestroy(Sender: TObject);
begin
  TryDestroyPreviousData;
end;

procedure TFormTests.Test(const Node: TTreeNode);
var TestFunction : TTest;
    tmp : TDataItem;
    DataSet : TBIDataset;
begin
  if Node.Data<>nil then
  begin
    TryDestroyPreviousData;

    // Special test mode for "Filtering" demos:
    if SameText(Node.Parent.Text,'Filtering') then
    begin
      // Force grid to create internal dataset, just in case:
      BIGrid1.BindTo(nil);
      DataSet:=BIGrid1.DataSource.DataSet as TBIDataSet;

      // Call the test, passing the dataset:
      TDataSetTest(Node.Data)(DataSet);

      Last:=DataSet.Data;
    end
    else
    begin
      // Export tests do not return data, they return a String
      if SameText(Node.Parent.Text,'Exporting') then
      begin
        if Node.Data=@ExportToExcel then
        begin
          TProcedureTest(Node.Data);
        end
        else
        begin
          Memo1.Lines.Text:=TStringTest(Node.Data);

          BIGrid1.Hide;
          Memo1.Show;
        end;
      end
      else
      begin
        // Normal test.
        // Obtain data:
        TestFunction:=TTest(Node.Data);

        tmp:=TestFunction;

        if tmp<>nil then
           if tmp.Name='' then
              tmp.Name:=Node.Text;

        // Empty grid
        BIGrid1.Data:=nil;

        // And bind the Grid to it:
        BIGrid1.BindTo(tmp);

        Last:=tmp;

        Memo1.Hide;
        BIGrid1.Show;

      end;
    end;
  end;
end;

procedure TFormTests.TreeChange(Sender: TObject; Node: TTreeNode);
begin
  if Tree.Selected.Data<>nil then
     Test(Tree.Selected);
end;

initialization
finalization
  _RandomTable.Free;
  _Demo.Free; // <-- release memory
end.
