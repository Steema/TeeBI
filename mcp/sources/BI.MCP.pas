{*********************************************}
{  TeeBI Software Library                     }
{  MCP (Model Context Protocol) Server        }
{  Copyright (c) 2015-2026 by Steema Software }
{  All Rights Reserved                        }
{*********************************************}
unit BI.MCP;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils, System.Types,
  System.Generics.Collections,
  BI.Arrays, BI.Arrays.Strings, BI.DataItem, BI.DataSource, BI.Persist,
  BI.SQL, BI.Summary, BI.CSV, BI.JSON, BI.Html;

type
  TMCPChartType = (mctBar, mctHorizBar, mctLine, mctPie, mctDonut, mctArea);

  TBI_MCPServer = class
  private
    FDataDir: String;
    FStoreName: String;
    FRunning: Boolean;

    procedure InitStore;
    function ResolveTable(const AData: TDataItem): TDataItem;
    function FindAndLoad(const AName: String; out AOwnerData: TDataItem): TDataItem;

    // MCP Handlers
    function HandleInitialize(const ReqId: TJSONValue; const Params: TJSONObject): TJSONObject;
    function HandleToolsList(const ReqId: TJSONValue): TJSONObject;
    function HandleToolsCall(const ReqId: TJSONValue; const Params: TJSONObject): TJSONObject;
    function HandlePing(const ReqId: TJSONValue): TJSONObject;

    // Tool Implementations
    function ToolListDatasets(const Args: TJSONObject): String;
    function ToolGetSchema(const Args: TJSONObject): String;
    function ToolPreviewData(const Args: TJSONObject): String;
    function ToolQuerySQL(const Args: TJSONObject): String;
    function ToolQueryNaturalLanguage(const Args: TJSONObject): String;
    function ToolCreateChart(const Args: TJSONObject): String;
    function ToolSummarize(const Args: TJSONObject): String;
    function ToolImportData(const Args: TJSONObject): String;
    function ToolExportData(const Args: TJSONObject): String;

    // Helpers
    function DatasetToJSONArray(const AData: TDataItem; const MaxRows: Integer = 50): TJSONArray;
    function GenerateSVGChart(const AData: TDataItem; const ChartType: TMCPChartType;
      const CatCol: String; const ValCols: TArray<String>; const Title: String;
      const Width: Integer = 700; const Height: Integer = 400): String;
    function ParseNaturalLanguage(const ATable: TDataItem; const Prompt: String;
      out Explanation: String): String;
  public
    Constructor Create(const ADataDir: String = '');
    Destructor Destroy; override;

    procedure Run;
    procedure Stop;

    property DataDir: String read FDataDir write FDataDir;
  end;

implementation

uses
  System.Math;

{ TBI_MCPServer }

Constructor TBI_MCPServer.Create(const ADataDir: String);
begin
  inherited Create;
  FStoreName := 'TeeBI_MCP';
  if ADataDir <> '' then
    FDataDir := TPath.GetFullPath(ADataDir)
  else
    FDataDir := TPath.GetFullPath('..\..\sampledata');

  InitStore;
end;

Destructor TBI_MCPServer.Destroy;
begin
  inherited;
end;

procedure TBI_MCPServer.InitStore;
begin
  TBIRegistry.UseRegistry := False;
  TBIRegistry.IniFile := TPath.Combine(FDataDir, 'teebi_mcp.ini');

  if DirectoryExists(FDataDir) then
  begin
    if TStores.Exists(FStoreName) then
      TStores.ChangePath(FStoreName, FDataDir)
    else
      TStores.Add(FStoreName, FDataDir);

    TStore.DefaultName := FStoreName;
  end;
end;

function TBI_MCPServer.ResolveTable(const AData: TDataItem): TDataItem;
begin
  if AData = nil then Exit(nil);

  // If AData is an envelope container with 1 child item that holds the real records:
  if (AData.Count = 0) and (AData.Items.Count = 1) and (AData.Items[0].Count > 0) then
    result := AData.Items[0]
  else
    result := AData;
end;

function TBI_MCPServer.FindAndLoad(const AName: String; out AOwnerData: TDataItem): TDataItem;
var
  Data, Current: TDataItem;
  Parts: TArray<String>;
  RootName: String;
  I: Integer;
begin
  AOwnerData := nil;
  result := nil;

  if Pos('/', AName) > 0 then
    Parts := AName.Split(['/'])
  else if Pos('\', AName) > 0 then
    Parts := AName.Split(['\'])
  else if (Pos('.', AName) > 0) and (not AName.EndsWith('.bi')) then
    Parts := AName.Split(['.'])
  else
    Parts := TArray<String>.Create(AName);

  RootName := Parts[0];

  try
    Data := TStore.Load(FStoreName, RootName);
  except
    Data := nil;
  end;

  if Data = nil then
  begin
    // Fallback: look for file in FDataDir
    if TFile.Exists(TPath.Combine(FDataDir, RootName + '.bi')) then
    begin
      try
        Data := TDataItemPersistence.Load(TPath.Combine(FDataDir, RootName + '.bi'));
      except
        Data := nil;
      end;
    end;
  end;

  if Data <> nil then
  begin
    Data.Load;
    AOwnerData := Data;

    if Length(Parts) > 1 then
    begin
      Current := Data;
      for I := 1 to High(Parts) do
      begin
        Current := Current.Items.Find(Parts[I]);
        if Current = nil then Break;
        Current.Load;
      end;
      result := Current;
    end
    else
    begin
      result := ResolveTable(Data);
      if (result <> nil) and (result <> Data) then
        result.Load;
    end;
  end;
end;

function TBI_MCPServer.DatasetToJSONArray(const AData: TDataItem; const MaxRows: Integer): TJSONArray;
var
  R, C: Integer;
  RowObj: TJSONObject;
  Col: TDataItem;
  NumRows: Integer;
begin
  result := TJSONArray.Create;
  if (AData = nil) or (AData.Items.Count = 0) then Exit;

  NumRows := Min(AData.Count, MaxRows);
  if NumRows = 0 then
  begin
    if (AData.Items.Count > 0) and (AData.Items[0].Count > 0) then
      NumRows := Min(AData.Items[0].Count, MaxRows);
  end;

  for R := 0 to NumRows - 1 do
  begin
    RowObj := TJSONObject.Create;
    for C := 0 to AData.Items.Count - 1 do
    begin
      Col := AData.Items[C];
      case Col.Kind of
        dkInt32, dkInt64:
          RowObj.AddPair(Col.Name, TJSONNumber.Create(Col.Int64Data[R]));
        dkSingle, dkDouble, dkExtended:
          RowObj.AddPair(Col.Name, TJSONNumber.Create(Col.DoubleData[R]));
        dkBoolean:
          RowObj.AddPair(Col.Name, TJSONBool.Create(Col.BooleanData[R]));
        dkUnknown:
          if Col.Items.Count > 0 then
            RowObj.AddPair(Col.Name, '[Nested Table: ' + IntToStr(Col.Items.Count) + ' columns]')
          else
            RowObj.AddPair(Col.Name, '');
        else
          RowObj.AddPair(Col.Name, Col.DataToString(R));
      end;
    end;
    result.AddElement(RowObj);
  end;
end;

function TBI_MCPServer.ToolListDatasets(const Args: TJSONObject): String;
var
  Arr: BI.Arrays.Strings.TStringArray;
  I, SubIdx: Integer;
  Res: TJSONObject;
  List: TJSONArray;
  ItemObj: TJSONObject;
  OwnerData, Table, SubItem: TDataItem;
  Store: String;
  SubTablesArr: TJSONArray;
  SubObj: TJSONObject;
begin
  Store := FStoreName;
  if (Args <> nil) and (Args.Values['store'] <> nil) then
    Store := Args.Values['store'].Value;

  Arr := TStore.AllData(Store);
  Res := TJSONObject.Create;
  try
    Res.AddPair('store', Store);
    Res.AddPair('directory', FDataDir);
    Res.AddPair('count', TJSONNumber.Create(Length(Arr)));
    List := TJSONArray.Create;

    for I := 0 to High(Arr) do
    begin
      ItemObj := TJSONObject.Create;
      ItemObj.AddPair('name', Arr[I]);

      // Peek table stats
      Table := FindAndLoad(Arr[I], OwnerData);
      if Table <> nil then
      try
        if (Table.Count = 0) and (Table.Items.Count > 1) then
        begin
          ItemObj.AddPair('is_database', TJSONBool.Create(True));
          ItemObj.AddPair('table_count', TJSONNumber.Create(Table.Items.Count));
          SubTablesArr := TJSONArray.Create;
          for SubIdx := 0 to Table.Items.Count - 1 do
          begin
            SubItem := Table.Items[SubIdx];
            SubItem.Load;
            SubObj := TJSONObject.Create;
            SubObj.AddPair('name', SubItem.Name);
            SubObj.AddPair('rows', TJSONNumber.Create(SubItem.Count));
            SubObj.AddPair('columns', TJSONNumber.Create(SubItem.Items.Count));
            SubTablesArr.AddElement(SubObj);
          end;
          ItemObj.AddPair('tables', SubTablesArr);
        end
        else
        begin
          ItemObj.AddPair('rows', TJSONNumber.Create(Table.Count));
          ItemObj.AddPair('columns', TJSONNumber.Create(Table.Items.Count));
        end;
      finally
        OwnerData.Free;
      end;

      List.AddElement(ItemObj);
    end;

    Res.AddPair('datasets', List);
    result := Res.Format(2);
  finally
    Res.Free;
  end;
end;

function TBI_MCPServer.ToolGetSchema(const Args: TJSONObject): String;
var
  DatasetName: String;
  OwnerData, Table, SubTable: TDataItem;
  Res: TJSONObject;
  ColsArr, TablesArr: TJSONArray;
  ColObj, TableObj: TJSONObject;
  I, SubIdx, SampleIdx: Integer;
  Col: TDataItem;
  SamplesArr: TJSONArray;
begin
  if (Args = nil) or (Args.Values['dataset'] = nil) then
    Exit('{"error": "Missing required argument: dataset"}');

  DatasetName := Args.Values['dataset'].Value;
  if Args.Values['table'] <> nil then
    DatasetName := DatasetName + '/' + Args.Values['table'].Value;

  Table := FindAndLoad(DatasetName, OwnerData);
  if Table = nil then
    Exit('{"error": "Dataset not found: ' + DatasetName + '"}');

  try
    Res := TJSONObject.Create;
    try
      // If dataset is a multi-table database and no specific table was requested
      if (Table.Count = 0) and (Table.Items.Count > 1) and (Pos('/', DatasetName) = 0) then
      begin
        Res.AddPair('dataset', DatasetName);
        Res.AddPair('is_database', TJSONBool.Create(True));
        Res.AddPair('table_count', TJSONNumber.Create(Table.Items.Count));

        TablesArr := TJSONArray.Create;
        for SubIdx := 0 to Table.Items.Count - 1 do
        begin
          SubTable := Table.Items[SubIdx];
          SubTable.Load;
          TableObj := TJSONObject.Create;
          TableObj.AddPair('table', SubTable.Name);
          TableObj.AddPair('rows', TJSONNumber.Create(SubTable.Count));
          TableObj.AddPair('columns', TJSONNumber.Create(SubTable.Items.Count));

          ColsArr := TJSONArray.Create;
          for I := 0 to SubTable.Items.Count - 1 do
          begin
            Col := SubTable.Items[I];
            ColObj := TJSONObject.Create;
            ColObj.AddPair('name', Col.Name);
            ColObj.AddPair('type', Col.Kind.ToString);
            ColsArr.AddElement(ColObj);
          end;
          TableObj.AddPair('columns_list', ColsArr);
          TablesArr.AddElement(TableObj);
        end;

        Res.AddPair('tables', TablesArr);
        result := Res.Format(2);
        Exit;
      end;

      Res.AddPair('dataset', DatasetName);
      Res.AddPair('table_name', Table.Name);
      Res.AddPair('row_count', TJSONNumber.Create(Table.Count));
      Res.AddPair('column_count', TJSONNumber.Create(Table.Items.Count));

      ColsArr := TJSONArray.Create;
      for I := 0 to Table.Items.Count - 1 do
      begin
        Col := Table.Items[I];
        ColObj := TJSONObject.Create;
        ColObj.AddPair('name', Col.Name);
        ColObj.AddPair('type', Col.Kind.ToString);
        ColObj.AddPair('is_numeric', TJSONBool.Create(Col.Kind.IsNumeric));

        // Sample values
        SamplesArr := TJSONArray.Create;
        if (Col.Kind <> dkUnknown) and (Col.Count > 0) then
        begin
          for SampleIdx := 0 to Min(Col.Count - 1, 4) do
            SamplesArr.Add(Col.DataToString(SampleIdx));
        end
        else if Col.Items.Count > 0 then
        begin
          SamplesArr.Add('[Nested Table: ' + IntToStr(Col.Items.Count) + ' columns]');
        end;
        ColObj.AddPair('sample_values', SamplesArr);

        ColsArr.AddElement(ColObj);
      end;

      Res.AddPair('columns', ColsArr);
      result := Res.Format(2);
    finally
      Res.Free;
    end;
  finally
    OwnerData.Free;
  end;
end;

function TBI_MCPServer.ToolPreviewData(const Args: TJSONObject): String;
var
  DatasetName: String;
  Limit: Integer;
  OwnerData, Table: TDataItem;
  Res: TJSONObject;
begin
  if (Args = nil) or (Args.Values['dataset'] = nil) then
    Exit('{"error": "Missing required argument: dataset"}');

  DatasetName := Args.Values['dataset'].Value;
  if Args.Values['table'] <> nil then
    DatasetName := DatasetName + '/' + Args.Values['table'].Value;

  Limit := 10;
  if (Args.Values['limit'] <> nil) then
    Limit := StrToIntDef(Args.Values['limit'].Value, 10);

  Table := FindAndLoad(DatasetName, OwnerData);
  if Table = nil then
    Exit('{"error": "Dataset not found: ' + DatasetName + '"}');

  try
    Res := TJSONObject.Create;
    try
      Res.AddPair('dataset', DatasetName);
      Res.AddPair('preview_rows', TJSONNumber.Create(Min(Table.Count, Limit)));
      Res.AddPair('total_rows', TJSONNumber.Create(Table.Count));
      Res.AddPair('rows', DatasetToJSONArray(Table, Limit));
      result := Res.Format(2);
    finally
      Res.Free;
    end;
  finally
    OwnerData.Free;
  end;
end;

function TBI_MCPServer.ToolQuerySQL(const Args: TJSONObject): String;
var
  DatasetName, SQLStr, FormatType: String;
  OwnerData, Table, QueryResult: TDataItem;
  Res: TJSONObject;
  T1: TDateTime;
  ElapsedMs: Int64;
begin
  if (Args = nil) or (Args.Values['dataset'] = nil) or (Args.Values['sql'] = nil) then
    Exit('{"error": "Missing required arguments: dataset and sql"}');

  DatasetName := Args.Values['dataset'].Value;
  if Args.Values['table'] <> nil then
    DatasetName := DatasetName + '/' + Args.Values['table'].Value;

  SQLStr := Args.Values['sql'].Value;
  FormatType := 'json';
  if Args.Values['format'] <> nil then
    FormatType := LowerCase(Args.Values['format'].Value);

  Table := FindAndLoad(DatasetName, OwnerData);
  if Table = nil then
    Exit('{"error": "Dataset not found: ' + DatasetName + '"}');

  try
    T1 := Now;
    try
      QueryResult := TBISQL.From(Table, SQLStr);
    except
      on E: Exception do
        Exit('{"error": "SQL execution error: ' + E.Message + '", "sql": "' + SQLStr + '"}');
    end;

    if QueryResult = nil then
      Exit('{"error": "Query returned no data", "sql": "' + SQLStr + '"}');

    try
      ElapsedMs := Round((Now - T1) * 86400000.0);
      QueryResult.Load;

      if FormatType = 'csv' then
      begin
        result := TBICSVExport.AsString(QueryResult);
      end
      else if FormatType = 'html' then
      begin
        result := TBIHTMLExport.AsString(QueryResult);
      end
      else
      begin
        Res := TJSONObject.Create;
        try
          Res.AddPair('dataset', DatasetName);
          Res.AddPair('sql', SQLStr);
          Res.AddPair('elapsed_ms', TJSONNumber.Create(ElapsedMs));
          Res.AddPair('row_count', TJSONNumber.Create(QueryResult.Count));
          Res.AddPair('column_count', TJSONNumber.Create(QueryResult.Items.Count));
          Res.AddPair('rows', DatasetToJSONArray(QueryResult, 100));
          result := Res.Format(2);
        finally
          Res.Free;
        end;
      end;
    finally
      QueryResult.Free;
    end;
  finally
    OwnerData.Free;
  end;
end;
      QueryResult := TBISQL.From(Table, SQLStr);
    except
      on E: Exception do
        Exit('{"error": "SQL execution error: ' + E.Message + '", "sql": "' + SQLStr + '"}');
    end;

    if QueryResult = nil then
      Exit('{"error": "Query returned no data", "sql": "' + SQLStr + '"}');

    try
      ElapsedMs := Round((Now - T1) * 86400000.0);
      QueryResult.Load;

      if FormatType = 'csv' then
      begin
        result := TBICSVExport.AsString(QueryResult);
      end
      else if FormatType = 'html' then
      begin
        result := TBIHTMLExport.AsString(QueryResult);
      end
      else
      begin
        Res := TJSONObject.Create;
        try
          Res.AddPair('dataset', DatasetName);
          Res.AddPair('sql', SQLStr);
          Res.AddPair('elapsed_ms', TJSONNumber.Create(ElapsedMs));
          Res.AddPair('row_count', TJSONNumber.Create(QueryResult.Count));
          Res.AddPair('column_count', TJSONNumber.Create(QueryResult.Items.Count));
          Res.AddPair('rows', DatasetToJSONArray(QueryResult, 100));
          result := Res.Format(2);
        finally
          Res.Free;
        end;
      end;
    finally
      QueryResult.Free;
    end;
  finally
    OwnerData.Free;
  end;
end;

function TBI_MCPServer.ParseNaturalLanguage(const ATable: TDataItem; const Prompt: String;
  out Explanation: String): String;
var
  LowerPrompt: String;
  I: Integer;
  Col, FoundMeasure, FoundGroup: TDataItem;
  AggName, GroupColName: String;
  LimitStr: String;
begin
  LowerPrompt := LowerCase(Prompt);
  Explanation := '';
  FoundMeasure := nil;
  FoundGroup := nil;
  AggName := 'count';

  // 1. Detect Aggregation
  if (Pos('sum', LowerPrompt) > 0) or (Pos('total', LowerPrompt) > 0) or (Pos('revenue', LowerPrompt) > 0) then
    AggName := 'sum'
  else if (Pos('average', LowerPrompt) > 0) or (Pos('avg', LowerPrompt) > 0) or (Pos('mean', LowerPrompt) > 0) then
    AggName := 'average'
  else if (Pos('maximum', LowerPrompt) > 0) or (Pos('max', LowerPrompt) > 0) or (Pos('highest', LowerPrompt) > 0) then
    AggName := 'max'
  else if (Pos('minimum', LowerPrompt) > 0) or (Pos('min', LowerPrompt) > 0) or (Pos('lowest', LowerPrompt) > 0) then
    AggName := 'min'
  else if (Pos('how many', LowerPrompt) > 0) or (Pos('count', LowerPrompt) > 0) or (Pos('number of', LowerPrompt) > 0) then
    AggName := 'count';

  // 2. Identify referenced columns
  for I := 0 to ATable.Items.Count - 1 do
  begin
    Col := ATable.Items[I];
    if Pos(LowerCase(Col.Name), LowerPrompt) > 0 then
    begin
      if Col.Kind.IsNumeric and (FoundMeasure = nil) then
        FoundMeasure := Col
      else if FoundGroup = nil then
        FoundGroup := Col;
    end;
  end;

  // Fallback defaults if not matched
  if (FoundMeasure = nil) and (ATable.Items.Count > 0) then
  begin
    for I := 0 to ATable.Items.Count - 1 do
      if ATable.Items[I].Kind.IsNumeric then
      begin
        FoundMeasure := ATable.Items[I];
        Break;
      end;
  end;

  if (FoundGroup = nil) and (ATable.Items.Count > 0) then
  begin
    for I := 0 to ATable.Items.Count - 1 do
      if (ATable.Items[I].Kind = dkText) and (ATable.Items[I] <> FoundMeasure) then
      begin
        FoundGroup := ATable.Items[I];
        Break;
      end;
  end;

  // 3. Detect Top N
  LimitStr := '';
  if Pos('top 5', LowerPrompt) > 0 then LimitStr := 'top 5 '
  else if Pos('top 10', LowerPrompt) > 0 then LimitStr := 'top 10 '
  else if Pos('top 20', LowerPrompt) > 0 then LimitStr := 'top 20 '
  else if Pos('top ', LowerPrompt) > 0 then LimitStr := 'top 10 ';

  // 4. Construct TeeBI Query / Summary
  if (FoundGroup <> nil) and (FoundMeasure <> nil) then
  begin
    result := LimitStr + FoundGroup.Name + ', ' + AggName + '(' + FoundMeasure.Name + ') group by ' + FoundGroup.Name;
    Explanation := 'Calculated ' + AggName + ' of ' + FoundMeasure.Name + ' grouped by ' + FoundGroup.Name;
  end
  else if FoundGroup <> nil then
  begin
    result := LimitStr + FoundGroup.Name + ', count(' + FoundGroup.Name + ') group by ' + FoundGroup.Name;
    Explanation := 'Grouped and counted by ' + FoundGroup.Name;
  end
  else
  begin
    result := 'top 10';
    Explanation := 'Preview of top 10 records';
  end;
end;

function TBI_MCPServer.ToolQueryNaturalLanguage(const Args: TJSONObject): String;
var
  DatasetName, Prompt, GeneratedSQL, Explanation: String;
  OwnerData, Table, QueryResult: TDataItem;
  Res: TJSONObject;
  T1: TDateTime;
  ElapsedMs: Int64;
  I: Integer;
begin
  if (Args = nil) or (Args.Values['dataset'] = nil) or (Args.Values['query_text'] = nil) then
    Exit('{"error": "Missing required arguments: dataset and query_text"}');

  DatasetName := Args.Values['dataset'].Value;
  if Args.Values['table'] <> nil then
    DatasetName := DatasetName + '/' + Args.Values['table'].Value;

  Prompt := Args.Values['query_text'].Value;

  Table := FindAndLoad(DatasetName, OwnerData);
  if Table = nil then
    Exit('{"error": "Dataset not found: ' + DatasetName + '"}');

  try
    if (Table.Count = 0) and (Table.Items.Count > 1) then
    begin
      for I := 0 to Table.Items.Count - 1 do
      begin
        if Pos(LowerCase(Table.Items[I].Name), LowerCase(Prompt)) > 0 then
        begin
          Table := Table.Items[I];
          Table.Load;
          Break;
        end;
      end;
      if (Table.Count = 0) and (Table.Items.Count > 1) then
      begin
        Table := Table.Items[0];
        Table.Load;
      end;
    end;

    GeneratedSQL := ParseNaturalLanguage(Table, Prompt, Explanation);

    T1 := Now;
    try
      QueryResult := TBISQL.From(Table, GeneratedSQL);
    except
      on E: Exception do
        Exit('{"error": "Natural language query translation failed: ' + E.Message +
             '", "generated_sql": "' + GeneratedSQL + '"}');
    end;

    if QueryResult = nil then
      Exit('{"error": "Query returned no data", "generated_sql": "' + GeneratedSQL + '"}');

    try
      ElapsedMs := Round((Now - T1) * 86400000.0);
      QueryResult.Load;

      Res := TJSONObject.Create;
      try
        Res.AddPair('dataset', DatasetName);
        Res.AddPair('user_prompt', Prompt);
        Res.AddPair('generated_teebi_sql', GeneratedSQL);
        Res.AddPair('explanation', Explanation);
        Res.AddPair('elapsed_ms', TJSONNumber.Create(ElapsedMs));
        Res.AddPair('row_count', TJSONNumber.Create(QueryResult.Count));
        Res.AddPair('rows', DatasetToJSONArray(QueryResult, 50));
        result := Res.Format(2);
      finally
        Res.Free;
      end;
    finally
      QueryResult.Free;
    end;
  finally
    OwnerData.Free;
  end;
end;

function GetNumericVal(const ACol: TDataItem; const Index: Integer): Double;
var
  Inv: TFormatSettings;
begin
  if ACol = nil then Exit(0);
  case ACol.Kind of
    dkInt32, dkInt64: result := ACol.Int64Data[Index];
    dkSingle, dkDouble, dkExtended: result := ACol.DoubleData[Index];
    else
    begin
      Inv := TFormatSettings.Invariant;
      result := StrToFloatDef(ACol.DataToString(Index), 0, Inv);
    end;
  end;
end;

function TBI_MCPServer.GenerateSVGChart(const AData: TDataItem; const ChartType: TMCPChartType;
  const CatCol: String; const ValCols: TArray<String>; const Title: String;
  const Width, Height: Integer): String;
var
  SVG: TStringBuilder;
  NumRows, I: Integer;
  CatData, ValData: TDataItem;
  MaxVal, MinVal, Val, PrevVal: Double;
  BarW, BarH, X, Y, PrevX, PrevY, ChartL, ChartT, ChartW, ChartH: Double;
  Colors: TArray<String>;
  Color: String;
  Inv: TFormatSettings;
  TotalVal, StartAngle, SliceAngle, MidAngle, Radius, InnerRadius, CX, CY: Double;
  X1, Y1, X2, Y2, LX, LY: Double;
  LargeArc: Integer;
  PointsStr: String;
begin
  Inv := TFormatSettings.Invariant;
  if (AData = nil) or (AData.Count = 0) then
    Exit('<svg width="' + IntToStr(Width) + '" height="' + IntToStr(Height) + '"><text x="20" y="30">No data</text></svg>');

  NumRows := Min(AData.Count, 12);

  CatData := nil;
  if CatCol <> '' then
    CatData := AData.Items.Find(CatCol);
  if CatData = nil then CatData := AData.Items[0];

  ValData := nil;
  if Length(ValCols) > 0 then
    ValData := AData.Items.Find(ValCols[0]);

  if ValData = nil then
  begin
    for I := 0 to AData.Items.Count - 1 do
      if AData.Items[I].Kind.IsNumeric then
      begin
        ValData := AData.Items[I];
        Break;
      end;
  end;
  if ValData = nil then ValData := CatData;

  Colors := TArray<String>.Create(
    '#4285F4', '#EA4335', '#FBBC05', '#34A853', '#9C27B0',
    '#FF6D00', '#00BCD4', '#3F51B5', '#009688', '#E91E63',
    '#795548', '#607D8B'
  );

  // Compute min/max/total
  MaxVal := 0.001;
  MinVal := 0;
  TotalVal := 0;
  for I := 0 to NumRows - 1 do
  begin
    Val := GetNumericVal(ValData, I);
    if Val > MaxVal then MaxVal := Val;
    if Val < MinVal then MinVal := Val;
    TotalVal := TotalVal + Val;
  end;
  if TotalVal <= 0 then TotalVal := 1;

  ChartL := 80;
  ChartT := 55;
  ChartW := Width - ChartL - 40;
  ChartH := Height - ChartT - 65;

  SVG := TStringBuilder.Create;
  try
    SVG.AppendLine(Format('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" style="background:#ffffff;font-family:Segoe UI,Helvetica,Arial,sans-serif;">', [Width, Height, Width, Height]));

    // Title
    if Title <> '' then
      SVG.AppendLine(Format('  <text x="%s" y="30" font-size="16" font-weight="bold" fill="#333333">%s</text>', [FloatToStr(ChartL, Inv), Title], Inv))
    else
      SVG.AppendLine(Format('  <text x="%s" y="30" font-size="16" font-weight="bold" fill="#333333">%s by %s</text>', [FloatToStr(ChartL, Inv), ValData.Name, CatData.Name], Inv));

    case ChartType of
      mctPie, mctDonut:
      begin
        CX := Width * 0.4;
        CY := Height * 0.52;
        Radius := Min(CX - 40, CY - 40);
        InnerRadius := 0;
        if ChartType = mctDonut then InnerRadius := Radius * 0.55;

        StartAngle := 0;
        for I := 0 to NumRows - 1 do
        begin
          Val := GetNumericVal(ValData, I);
          SliceAngle := (Val / TotalVal) * 2 * Pi;
          Color := Colors[I mod Length(Colors)];

          X1 := CX + Radius * Cos(StartAngle);
          Y1 := CY + Radius * Sin(StartAngle);
          X2 := CX + Radius * Cos(StartAngle + SliceAngle);
          Y2 := CY + Radius * Sin(StartAngle + SliceAngle);
          if SliceAngle > Pi then LargeArc := 1 else LargeArc := 0;

          if ChartType = mctDonut then
          begin
            SVG.AppendLine(Format('  <path d="M %s %s A %s %s 0 %d 1 %s %s L %s %s A %s %s 0 %d 0 %s %s Z" fill="%s" stroke="#fff" stroke-width="2"><title>%s: %s</title></path>',
              [FloatToStr(X1, Inv), FloatToStr(Y1, Inv), FloatToStr(Radius, Inv), FloatToStr(Radius, Inv), LargeArc, FloatToStr(X2, Inv), FloatToStr(Y2, Inv),
               FloatToStr(CX + InnerRadius * Cos(StartAngle + SliceAngle), Inv), FloatToStr(CY + InnerRadius * Sin(StartAngle + SliceAngle), Inv),
               FloatToStr(InnerRadius, Inv), FloatToStr(InnerRadius, Inv), LargeArc, FloatToStr(CX + InnerRadius * Cos(StartAngle), Inv), FloatToStr(CY + InnerRadius * Sin(StartAngle), Inv),
               Color, CatData.DataToString(I), ValData.DataToString(I)], Inv));
          end
          else
          begin
            SVG.AppendLine(Format('  <path d="M %s %s L %s %s A %s %s 0 %d 1 %s %s Z" fill="%s" stroke="#fff" stroke-width="2"><title>%s: %s</title></path>',
              [FloatToStr(CX, Inv), FloatToStr(CY, Inv), FloatToStr(X1, Inv), FloatToStr(Y1, Inv), FloatToStr(Radius, Inv), FloatToStr(Radius, Inv), LargeArc, FloatToStr(X2, Inv), FloatToStr(Y2, Inv),
               Color, CatData.DataToString(I), ValData.DataToString(I)], Inv));
          end;

          // Legend
          LX := Width * 0.72;
          LY := 70 + (I * 22);
          SVG.AppendLine(Format('  <rect x="%s" y="%s" width="14" height="14" fill="%s" rx="2"/>', [FloatToStr(LX, Inv), FloatToStr(LY, Inv), Color], Inv));
          SVG.AppendLine(Format('  <text x="%s" y="%s" font-size="11" fill="#333333">%s (%s)</text>',
            [FloatToStr(LX + 20, Inv), FloatToStr(LY + 11, Inv), Copy(CatData.DataToString(I), 1, 16), ValData.DataToString(I)], Inv));

          StartAngle := StartAngle + SliceAngle;
        end;
      end;

      mctLine, mctArea:
      begin
        // Grid & axes
        SVG.AppendLine(Format('  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#EEEEEE" stroke-width="1"/>', [FloatToStr(ChartL, Inv), FloatToStr(ChartT, Inv), FloatToStr(ChartL + ChartW, Inv), FloatToStr(ChartT, Inv)], Inv));
        SVG.AppendLine(Format('  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#EEEEEE" stroke-width="1"/>', [FloatToStr(ChartL, Inv), FloatToStr(ChartT + ChartH / 2, Inv), FloatToStr(ChartL + ChartW, Inv), FloatToStr(ChartT + ChartH / 2, Inv)], Inv));
        SVG.AppendLine(Format('  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#CCCCCC" stroke-width="2"/>', [FloatToStr(ChartL, Inv), FloatToStr(ChartT + ChartH, Inv), FloatToStr(ChartL + ChartW, Inv), FloatToStr(ChartT + ChartH, Inv)], Inv));
        SVG.AppendLine(Format('  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#CCCCCC" stroke-width="2"/>', [FloatToStr(ChartL, Inv), FloatToStr(ChartT, Inv), FloatToStr(ChartL, Inv), FloatToStr(ChartT + ChartH, Inv)], Inv));

        // Y Labels
        SVG.AppendLine(Format('  <text x="%s" y="%s" font-size="11" fill="#666666" text-anchor="end">%s</text>', [FloatToStr(ChartL - 8, Inv), FloatToStr(ChartT + 5, Inv), FloatToStr(MaxVal, Inv)], Inv));
        SVG.AppendLine(Format('  <text x="%s" y="%s" font-size="11" fill="#666666" text-anchor="end">%s</text>', [FloatToStr(ChartL - 8, Inv), FloatToStr(ChartT + ChartH / 2 + 5, Inv), FloatToStr(MaxVal / 2, Inv)], Inv));
        SVG.AppendLine(Format('  <text x="%s" y="%s" font-size="11" fill="#666666" text-anchor="end">0</text>', [FloatToStr(ChartL - 8, Inv), FloatToStr(ChartT + ChartH + 5, Inv)], Inv));

        PointsStr := '';
        for I := 0 to NumRows - 1 do
        begin
          Val := GetNumericVal(ValData, I);
          BarH := (Val / MaxVal) * ChartH;
          X := ChartL + (I * (ChartW / Max(1, NumRows - 1)));
          Y := ChartT + ChartH - BarH;
          if I = 0 then PointsStr := Format('%s,%s', [FloatToStr(X, Inv), FloatToStr(Y, Inv)], Inv)
          else PointsStr := PointsStr + Format(' %s,%s', [FloatToStr(X, Inv), FloatToStr(Y, Inv)], Inv);

          // Category labels
          SVG.AppendLine(Format('  <text x="%s" y="%s" font-size="10" fill="#444444" text-anchor="middle" transform="rotate(25, %s, %s)">%s</text>',
            [FloatToStr(X, Inv), FloatToStr(ChartT + ChartH + 15, Inv), FloatToStr(X, Inv), FloatToStr(ChartT + ChartH + 15, Inv), Copy(CatData.DataToString(I), 1, 14)], Inv));
        end;

        if ChartType = mctArea then
        begin
          SVG.AppendLine(Format('  <polygon points="%s %s,%s %s,%s" fill="#4285F4" fill-opacity="0.25"/>',
            [PointsStr, FloatToStr(ChartL + ChartW, Inv), FloatToStr(ChartT + ChartH, Inv), FloatToStr(ChartL, Inv), FloatToStr(ChartT + ChartH, Inv)], Inv));
        end;

        SVG.AppendLine(Format('  <polyline points="%s" fill="none" stroke="#4285F4" stroke-width="3"/>', [PointsStr], Inv));

        // Markers
        for I := 0 to NumRows - 1 do
        begin
          Val := GetNumericVal(ValData, I);
          BarH := (Val / MaxVal) * ChartH;
          X := ChartL + (I * (ChartW / Max(1, NumRows - 1)));
          Y := ChartT + ChartH - BarH;
          SVG.AppendLine(Format('  <circle cx="%s" cy="%s" r="4" fill="#4285F4" stroke="#fff" stroke-width="2"><title>%s: %s</title></circle>',
            [FloatToStr(X, Inv), FloatToStr(Y, Inv), CatData.DataToString(I), ValData.DataToString(I)], Inv));
        end;
      end;

      else // mctBar, mctHorizBar
      begin
        // Grid lines & axes
        SVG.AppendLine(Format('  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#EEEEEE" stroke-width="1"/>', [FloatToStr(ChartL, Inv), FloatToStr(ChartT, Inv), FloatToStr(ChartL + ChartW, Inv), FloatToStr(ChartT, Inv)], Inv));
        SVG.AppendLine(Format('  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#EEEEEE" stroke-width="1"/>', [FloatToStr(ChartL, Inv), FloatToStr(ChartT + ChartH / 2, Inv), FloatToStr(ChartL + ChartW, Inv), FloatToStr(ChartT + ChartH / 2, Inv)], Inv));
        SVG.AppendLine(Format('  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#CCCCCC" stroke-width="2"/>', [FloatToStr(ChartL, Inv), FloatToStr(ChartT + ChartH, Inv), FloatToStr(ChartL + ChartW, Inv), FloatToStr(ChartT + ChartH, Inv)], Inv));
        SVG.AppendLine(Format('  <line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#CCCCCC" stroke-width="2"/>', [FloatToStr(ChartL, Inv), FloatToStr(ChartT, Inv), FloatToStr(ChartL, Inv), FloatToStr(ChartT + ChartH, Inv)], Inv));

        // Y Axis labels
        SVG.AppendLine(Format('  <text x="%s" y="%s" font-size="11" fill="#666666" text-anchor="end">%s</text>', [FloatToStr(ChartL - 8, Inv), FloatToStr(ChartT + 5, Inv), FloatToStr(MaxVal, Inv)], Inv));
        SVG.AppendLine(Format('  <text x="%s" y="%s" font-size="11" fill="#666666" text-anchor="end">%s</text>', [FloatToStr(ChartL - 8, Inv), FloatToStr(ChartT + ChartH / 2 + 5, Inv), FloatToStr(MaxVal / 2, Inv)], Inv));
        SVG.AppendLine(Format('  <text x="%s" y="%s" font-size="11" fill="#666666" text-anchor="end">0</text>', [FloatToStr(ChartL - 8, Inv), FloatToStr(ChartT + ChartH + 5, Inv)], Inv));

        // Render Bars
        BarW := (ChartW / NumRows) * 0.65;
        for I := 0 to NumRows - 1 do
        begin
          Val := GetNumericVal(ValData, I);
          BarH := (Val / MaxVal) * ChartH;
          X := ChartL + (I * (ChartW / NumRows)) + ((ChartW / NumRows - BarW) / 2);
          Y := ChartT + ChartH - BarH;
          Color := Colors[I mod Length(Colors)];

          // Bar rect
          SVG.AppendLine(Format('  <rect x="%s" y="%s" width="%s" height="%s" rx="3" fill="%s"><title>%s: %s</title></rect>',
            [FloatToStr(X, Inv), FloatToStr(Y, Inv), FloatToStr(BarW, Inv), FloatToStr(BarH, Inv), Color, CatData.DataToString(I), ValData.DataToString(I)], Inv));

          // Value label on top of bar
          if BarH > 15 then
            SVG.AppendLine(Format('  <text x="%s" y="%s" font-size="10" fill="#333333" text-anchor="middle">%s</text>',
              [FloatToStr(X + BarW / 2, Inv), FloatToStr(Y - 4, Inv), ValData.DataToString(I)], Inv));

          // Category label under axis
          SVG.AppendLine(Format('  <text x="%s" y="%s" font-size="10" fill="#444444" text-anchor="middle" transform="rotate(25, %s, %s)">%s</text>',
            [FloatToStr(X + BarW / 2, Inv), FloatToStr(ChartT + ChartH + 15, Inv), FloatToStr(X + BarW / 2, Inv), FloatToStr(ChartT + ChartH + 15, Inv), Copy(CatData.DataToString(I), 1, 14)], Inv));
        end;
      end;
    end;

    SVG.AppendLine('</svg>');
    result := SVG.ToString;
  finally
    SVG.Free;
  end;
end;

function TBI_MCPServer.ToolCreateChart(const Args: TJSONObject): String;
var
  DatasetName, ChartTypeStr, CatCol, Title, FormatType: String;
  ValColsArr: TJSONArray;
  ValCols: TArray<String>;
  OwnerData, Table, ChartTable: TDataItem;
  ChartType: TMCPChartType;
  SVGStr: String;
  Res: TJSONObject;
  I: Integer;
  HasNumeric: Boolean;
  AutoSummary: String;
begin
  if (Args = nil) or (Args.Values['dataset'] = nil) then
    Exit('{"error": "Missing required argument: dataset"}');

  DatasetName := Args.Values['dataset'].Value;
  ChartTypeStr := 'bar';
  if Args.Values['chart_type'] <> nil then
    ChartTypeStr := LowerCase(Args.Values['chart_type'].Value);

  CatCol := '';
  if Args.Values['category_column'] <> nil then
    CatCol := Args.Values['category_column'].Value;

  Title := '';
  if Args.Values['title'] <> nil then
    Title := Args.Values['title'].Value;

  FormatType := 'svg';
  if Args.Values['format'] <> nil then
    FormatType := LowerCase(Args.Values['format'].Value);

  ValCols := nil;
  if (Args.Values['value_columns'] <> nil) and (Args.Values['value_columns'] is TJSONArray) then
  begin
    ValColsArr := Args.Values['value_columns'] as TJSONArray;
    SetLength(ValCols, ValColsArr.Count);
    for I := 0 to ValColsArr.Count - 1 do
      ValCols[I] := ValColsArr.Items[I].Value;
  end;

  ChartType := mctBar;
  if (ChartTypeStr = 'horiz_bar') or (ChartTypeStr = 'horizontal_bar') then ChartType := mctHorizBar
  else if ChartTypeStr = 'line' then ChartType := mctLine
  else if ChartTypeStr = 'pie' then ChartType := mctPie
  else if ChartTypeStr = 'donut' then ChartType := mctDonut
  else if ChartTypeStr = 'area' then ChartType := mctArea;

  Table := FindAndLoad(DatasetName, OwnerData);
  if Table = nil then
    Exit('{"error": "Dataset not found: ' + DatasetName + '"}');

  try
    ChartTable := Table;

    // Check if table has numeric columns for values
    HasNumeric := False;
    for I := 0 to Table.Items.Count - 1 do
      if Table.Items[I].Kind.IsNumeric then
      begin
        HasNumeric := True;
        Break;
      end;

    // If table has no numeric value column or user gave a category with no numeric col, auto-summarize
    if (not HasNumeric) and (CatCol <> '') then
    begin
      AutoSummary := 'top 12 ' + CatCol + ', count(' + CatCol + ') group by ' + CatCol;
      try
        ChartTable := TBISQL.From(Table, AutoSummary);
        if ChartTable <> nil then
          ChartTable.Load;
      except
        ChartTable := Table;
      end;
    end;

    try
      SVGStr := GenerateSVGChart(ChartTable, ChartType, CatCol, ValCols, Title, 720, 420);

      Res := TJSONObject.Create;
      try
        Res.AddPair('dataset', DatasetName);
        Res.AddPair('chart_type', ChartTypeStr);
        Res.AddPair('format', FormatType);
        Res.AddPair('svg', SVGStr);
        result := Res.Format(2);
      finally
        Res.Free;
      end;
    finally
      if (ChartTable <> nil) and (ChartTable <> Table) then
        ChartTable.Free;
    end;
  finally
    OwnerData.Free;
  end;
end;

function TBI_MCPServer.ToolSummarize(const Args: TJSONObject): String;
var
  DatasetName, SummaryStr, HavingStr, FilterStr: String;
  OwnerData, Table, SumResult: TDataItem;
  Res: TJSONObject;
begin
  if (Args = nil) or (Args.Values['dataset'] = nil) or (Args.Values['summary'] = nil) then
    Exit('{"error": "Missing required arguments: dataset and summary (e.g. ''count(name);cuisine'')"}');

  DatasetName := Args.Values['dataset'].Value;
  SummaryStr := Args.Values['summary'].Value;
  HavingStr := '';
  if Args.Values['having'] <> nil then HavingStr := Args.Values['having'].Value;
  FilterStr := '';
  if Args.Values['filter'] <> nil then FilterStr := Args.Values['filter'].Value;

  Table := FindAndLoad(DatasetName, OwnerData);
  if Table = nil then
    Exit('{"error": "Dataset not found: ' + DatasetName + '"}');

  try
    try
      SumResult := TBISQL.SummaryOf(Table, SummaryStr, HavingStr, FilterStr);
    except
      on E: Exception do
        Exit('{"error": "Summary error: ' + E.Message + '"}');
    end;

    if SumResult = nil then
      Exit('{"error": "Summary returned no data"}');

    try
      SumResult.Load;
      Res := TJSONObject.Create;
      try
        Res.AddPair('dataset', DatasetName);
        Res.AddPair('summary_spec', SummaryStr);
        Res.AddPair('row_count', TJSONNumber.Create(SumResult.Count));
        Res.AddPair('column_count', TJSONNumber.Create(SumResult.Items.Count));
        Res.AddPair('rows', DatasetToJSONArray(SumResult, 50));
        result := Res.Format(2);
      finally
        Res.Free;
      end;
    finally
      SumResult.Free;
    end;
  finally
    OwnerData.Free;
  end;
end;

function TBI_MCPServer.ToolImportData(const Args: TJSONObject): String;
var
  TargetName, SourcePath, FormatStr: String;
  NewData: TDataItem;
  Ext: String;
  Res: TJSONObject;
begin
  if (Args = nil) or (Args.Values['name'] = nil) or (Args.Values['source_path'] = nil) then
    Exit('{"error": "Missing required arguments: name and source_path"}');

  TargetName := Args.Values['name'].Value;
  SourcePath := Args.Values['source_path'].Value;
  FormatStr := '';
  if Args.Values['format'] <> nil then FormatStr := LowerCase(Args.Values['format'].Value);

  if not TFile.Exists(SourcePath) then
    Exit('{"error": "File does not exist: ' + SourcePath + '"}');

  Ext := LowerCase(TPath.GetExtension(SourcePath));
  NewData := nil;

  try
    if (Ext = '.csv') or (FormatStr = 'csv') then
      NewData := TBICSV.FromFile(SourcePath)
    else if (Ext = '.json') or (FormatStr = 'json') then
      NewData := TBIJSON.FromFile(SourcePath)
    else
      NewData := TBIFileSource.FromFile(SourcePath);

    if NewData = nil then
      Exit('{"error": "Failed to parse data file format"}');

    try
      NewData.Name := TargetName;
      TStore.Save(NewData, FStoreName);

      Res := TJSONObject.Create;
      try
        Res.AddPair('status', 'success');
        Res.AddPair('dataset', TargetName);
        Res.AddPair('store', FStoreName);
        Res.AddPair('rows', TJSONNumber.Create(NewData.Count));
        Res.AddPair('columns', TJSONNumber.Create(NewData.Items.Count));
        result := Res.Format(2);
      finally
        Res.Free;
      end;
    finally
      NewData.Free;
    end;
  except
    on E: Exception do
      Exit('{"error": "Import error: ' + E.Message + '"}');
  end;
end;

function TBI_MCPServer.ToolExportData(const Args: TJSONObject): String;
var
  DatasetName, OutputPath, FormatStr: String;
  OwnerData, Table: TDataItem;
  Ext: String;
  Content: String;
  Res: TJSONObject;
begin
  if (Args = nil) or (Args.Values['dataset'] = nil) or (Args.Values['output_path'] = nil) then
    Exit('{"error": "Missing required arguments: dataset and output_path"}');

  DatasetName := Args.Values['dataset'].Value;
  OutputPath := Args.Values['output_path'].Value;
  FormatStr := '';
  if Args.Values['format'] <> nil then FormatStr := LowerCase(Args.Values['format'].Value);

  Table := FindAndLoad(DatasetName, OwnerData);
  if Table = nil then
    Exit('{"error": "Dataset not found: ' + DatasetName + '"}');

  try
    Ext := LowerCase(TPath.GetExtension(OutputPath));
    if (Ext = '.csv') or (FormatStr = 'csv') then
      Content := TBICSVExport.AsString(Table)
    else if (Ext = '.html') or (Ext = '.htm') or (FormatStr = 'html') then
      Content := TBIHTMLExport.AsString(Table)
    else
      Content := TBIJSONExport.AsString(Table, True);

    TFile.WriteAllText(OutputPath, Content, TEncoding.UTF8);

    Res := TJSONObject.Create;
    try
      Res.AddPair('status', 'success');
      Res.AddPair('dataset', DatasetName);
      Res.AddPair('output_path', OutputPath);
      Res.AddPair('file_size_bytes', TJSONNumber.Create(Length(Content)));
      result := Res.Format(2);
    finally
      Res.Free;
    end;
  finally
    OwnerData.Free;
  end;
end;

{ JSON-RPC MCP Handlers }

function TBI_MCPServer.HandleInitialize(const ReqId: TJSONValue; const Params: TJSONObject): TJSONObject;
var
  Res, ResultObj, Capabilities, ToolsCap, ServerInfo: TJSONObject;
begin
  Res := TJSONObject.Create;
  Res.AddPair('jsonrpc', '2.0');
  Res.AddPair('id', ReqId.Clone as TJSONValue);

  ResultObj := TJSONObject.Create;
  ResultObj.AddPair('protocolVersion', '2024-11-05');

  Capabilities := TJSONObject.Create;
  ToolsCap := TJSONObject.Create;
  Capabilities.AddPair('tools', ToolsCap);
  ResultObj.AddPair('capabilities', Capabilities);

  ServerInfo := TJSONObject.Create;
  ServerInfo.AddPair('name', 'teebi-mcp');
  ServerInfo.AddPair('version', '1.0.0');
  ResultObj.AddPair('serverInfo', ServerInfo);

  Res.AddPair('result', ResultObj);
  result := Res;
end;

function TBI_MCPServer.HandlePing(const ReqId: TJSONValue): TJSONObject;
var
  Res, ResultObj: TJSONObject;
begin
  Res := TJSONObject.Create;
  Res.AddPair('jsonrpc', '2.0');
  Res.AddPair('id', ReqId.Clone as TJSONValue);
  ResultObj := TJSONObject.Create;
  Res.AddPair('result', ResultObj);
  result := Res;
end;

function TBI_MCPServer.HandleToolsList(const ReqId: TJSONValue): TJSONObject;
var
  Res, ResultObj: TJSONObject;
  ToolsArr: TJSONArray;

  procedure AddTool(const AName, ADesc, ASchemaJSON: String);
  var
    ToolObj, SchemaObj: TJSONObject;
  begin
    ToolObj := TJSONObject.Create;
    ToolObj.AddPair('name', AName);
    ToolObj.AddPair('description', ADesc);
    SchemaObj := TJSONObject.ParseJSONValue(ASchemaJSON) as TJSONObject;
    ToolObj.AddPair('inputSchema', SchemaObj);
    ToolsArr.AddElement(ToolObj);
  end;

begin
  Res := TJSONObject.Create;
  Res.AddPair('jsonrpc', '2.0');
  Res.AddPair('id', ReqId.Clone as TJSONValue);

  ResultObj := TJSONObject.Create;
  ToolsArr := TJSONArray.Create;

  AddTool('teebi_list_datasets',
    'List all available datasets in the TeeBI store or directory.',
    '{"type":"object","properties":{"store":{"type":"string","description":"Optional store name"}}}');

  AddTool('teebi_get_schema',
    'Get column metadata, types, row count, and sample values for a TeeBI dataset.',
    '{"type":"object","properties":{"dataset":{"type":"string","description":"Name of dataset"}},"required":["dataset"]}');

  AddTool('teebi_preview_data',
    'Preview the first N rows of a TeeBI dataset.',
    '{"type":"object","properties":{"dataset":{"type":"string","description":"Name of dataset"},"limit":{"type":"integer","description":"Max rows to return (default 10)"}},"required":["dataset"]}');

  AddTool('teebi_query_sql',
    'Execute a TeeBI SQL query against a dataset (e.g. "top 10 ProductName, sum(Amount) where Year>2020 group by ProductName").',
    '{"type":"object","properties":{"dataset":{"type":"string","description":"Name of dataset"},"sql":{"type":"string","description":"TeeBI SQL query statement"},"format":{"type":"string","enum":["json","csv","html"],"description":"Output format (default json)"}},"required":["dataset","sql"]}');

  AddTool('teebi_query_natural_language',
    'Run a query on a TeeBI dataset using plain natural language (e.g. "top 5 cuisines in Brooklyn with highest scores", "average movie length by year"). Automatically translates the request to TeeBI SQL and executes it.',
    '{"type":"object","properties":{"dataset":{"type":"string","description":"Name of dataset"},"query_text":{"type":"string","description":"Natural language question or request"}},"required":["dataset","query_text"]}');

  AddTool('teebi_create_chart',
    'Generate an SVG visualization (bar, horizontal_bar, line, pie, donut, area) for a dataset or query result.',
    '{"type":"object","properties":{"dataset":{"type":"string","description":"Name of dataset"},"chart_type":{"type":"string","enum":["bar","horiz_bar","line","pie","donut","area"],"description":"Chart type (default bar)"},"category_column":{"type":"string","description":"Column to use as category/X-axis"},"value_columns":{"type":"array","items":{"type":"string"},"description":"Columns to use as values/Y-axis"},"title":{"type":"string","description":"Chart title"}},"required":["dataset"]}');

  AddTool('teebi_summarize',
    'Create multi-dimensional pivot summaries on a dataset using measures and dimensions (e.g. summary: "sum(Amount);Country,Year").',
    '{"type":"object","properties":{"dataset":{"type":"string","description":"Name of dataset"},"summary":{"type":"string","description":"Summary expression: <measures>;<dimensions> (e.g. ''count(name);cuisine'')"},"filter":{"type":"string","description":"Optional filter expression"},"having":{"type":"string","description":"Optional having expression"}},"required":["dataset","summary"]}');

  AddTool('teebi_import_data',
    'Import data from a local file (CSV, JSON, etc.) into the TeeBI store.',
    '{"type":"object","properties":{"name":{"type":"string","description":"New dataset name"},"source_path":{"type":"string","description":"Absolute path to source file"},"format":{"type":"string","enum":["csv","json"],"description":"Optional file format"}},"required":["name","source_path"]}');

  AddTool('teebi_export_data',
    'Export a TeeBI dataset or query result to a file on disk (CSV, JSON, or HTML).',
    '{"type":"object","properties":{"dataset":{"type":"string","description":"Name of dataset"},"output_path":{"type":"string","description":"Destination file path"},"format":{"type":"string","enum":["csv","json","html"],"description":"Export format"}},"required":["dataset","output_path"]}');

  ResultObj.AddPair('tools', ToolsArr);
  Res.AddPair('result', ResultObj);
  result := Res;
end;

function TBI_MCPServer.HandleToolsCall(const ReqId: TJSONValue; const Params: TJSONObject): TJSONObject;
var
  ToolName: String;
  Args: TJSONObject;
  ToolResult: String;
  Res, ResultObj: TJSONObject;
  ContentArr: TJSONArray;
  TextContent: TJSONObject;
  IsErr: Boolean;
begin
  ToolName := Params.Values['name'].Value;
  Args := nil;
  if Params.Values['arguments'] is TJSONObject then
    Args := Params.Values['arguments'] as TJSONObject;

  ToolResult := '';
  IsErr := False;

  try
    if ToolName = 'teebi_list_datasets' then
      ToolResult := ToolListDatasets(Args)
    else if ToolName = 'teebi_get_schema' then
      ToolResult := ToolGetSchema(Args)
    else if ToolName = 'teebi_preview_data' then
      ToolResult := ToolPreviewData(Args)
    else if ToolName = 'teebi_query_sql' then
      ToolResult := ToolQuerySQL(Args)
    else if ToolName = 'teebi_query_natural_language' then
      ToolResult := ToolQueryNaturalLanguage(Args)
    else if ToolName = 'teebi_create_chart' then
      ToolResult := ToolCreateChart(Args)
    else if ToolName = 'teebi_summarize' then
      ToolResult := ToolSummarize(Args)
    else if ToolName = 'teebi_import_data' then
      ToolResult := ToolImportData(Args)
    else if ToolName = 'teebi_export_data' then
      ToolResult := ToolExportData(Args)
    else
    begin
      ToolResult := '{"error": "Unknown tool: ' + ToolName + '"}';
      IsErr := True;
    end;
  except
    on E: Exception do
    begin
      ToolResult := '{"error": "Tool execution exception: ' + E.Message + '"}';
      IsErr := True;
    end;
  end;

  Res := TJSONObject.Create;
  Res.AddPair('jsonrpc', '2.0');
  Res.AddPair('id', ReqId.Clone as TJSONValue);

  ResultObj := TJSONObject.Create;
  ContentArr := TJSONArray.Create;
  TextContent := TJSONObject.Create;
  TextContent.AddPair('type', 'text');
  TextContent.AddPair('text', ToolResult);
  ContentArr.AddElement(TextContent);
  ResultObj.AddPair('content', ContentArr);
  ResultObj.AddPair('isError', TJSONBool.Create(IsErr));

  Res.AddPair('result', ResultObj);
  result := Res;
end;

procedure TBI_MCPServer.Run;
var
  Line: String;
  JsonReq, JsonResp: TJSONObject;
  MethodVal, IdVal: TJSONValue;
  MethodStr: String;
  ParamsObj: TJSONObject;
begin
  FRunning := True;
  WriteLn(ErrOutput, 'TeeBI MCP Server started. Store directory: ', FDataDir);
  Flush(ErrOutput);

  while FRunning and (not Eof) do
  begin
    ReadLn(Line);
    Line := Trim(Line);
    if Line = '' then Continue;

    try
      JsonReq := TJSONObject.ParseJSONValue(Line) as TJSONObject;
    except
      JsonReq := nil;
    end;

    if JsonReq = nil then Continue;

    try
      MethodVal := JsonReq.Values['method'];
      IdVal := JsonReq.Values['id'];

      if MethodVal <> nil then
      begin
        MethodStr := MethodVal.Value;
        ParamsObj := nil;
        if JsonReq.Values['params'] is TJSONObject then
          ParamsObj := JsonReq.Values['params'] as TJSONObject;

        JsonResp := nil;

        if MethodStr = 'initialize' then
          JsonResp := HandleInitialize(IdVal, ParamsObj)
        else if MethodStr = 'notifications/initialized' then
        begin
          // Notification: no response per MCP spec
          JsonResp := nil;
        end
        else if MethodStr = 'ping' then
          JsonResp := HandlePing(IdVal)
        else if MethodStr = 'tools/list' then
          JsonResp := HandleToolsList(IdVal)
        else if MethodStr = 'tools/call' then
          JsonResp := HandleToolsCall(IdVal, ParamsObj)
        else if IdVal <> nil then
        begin
          // Unknown method with id -> return error
          JsonResp := TJSONObject.Create;
          JsonResp.AddPair('jsonrpc', '2.0');
          JsonResp.AddPair('id', IdVal.Clone as TJSONValue);
          JsonResp.AddPair('error', TJSONObject.Create
            .AddPair('code', TJSONNumber.Create(-32601))
            .AddPair('message', 'Method not found: ' + MethodStr));
        end;

        if JsonResp <> nil then
        try
          WriteLn(Output, JsonResp.ToJSON);
          Flush(Output);
        finally
          JsonResp.Free;
        end;
      end;
    finally
      JsonReq.Free;
    end;
  end;
end;

procedure TBI_MCPServer.Stop;
begin
  FRunning := False;
end;

end.
