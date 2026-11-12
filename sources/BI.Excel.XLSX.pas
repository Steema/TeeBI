{*********************************************}
{  TeeBI Software Library                     }
{  Microsoft Excel XLSX import and export.    }
{                                             }
{  LibreOffice, OpenOffice                    }
{  Google Spreadsheets                        }
{                                             }
{  Copyright (c) 2015-2026 by Steema Software }
{  All Rights Reserved                        }
{*********************************************}
unit BI.Excel.XLSX;

interface

uses
  System.Classes, System.SysUtils,
  BI.DataSource, BI.DataItem, BI.Arrays, BI.Persist, BI.XMLData,
  BI.Web, BI.Excel;

type
  EExcelException=class(EBIException);

  TBIExcelXLSX=class(TBITextSource)
  public
    class function FileFilter: TFileFilters; override;
    class function Supports(const Extension:String):Boolean; override;
  end;

  TBIXLSXEngine=class(TBIExcelEngine)
  public
    class procedure SaveToFile(const AData:TDataItem; const AFileName:String); override;
    class procedure SaveToStream(const AData: TDataItem; const AStream: TStream);
  end;

implementation

uses
  System.Zip, System.Generics.Collections,
  System.RegularExpressions, System.Math;

function ConvertGoogleSheetUrlToXlsx(const AUrl: string): string;
var
  Match: TMatch;
  DocId, Gid: string;
begin
  // Extracts the document ID from standard Google Sheets links:
  // https://docs.google.com/spreadsheets/d/{ID}/edit...
  Match := TRegEx.Match(AUrl, 'spreadsheets/d/([a-zA-Z0-9-_]+)');
  if not Match.Success then
    Exit(AUrl); // Assume it is already a direct .xlsx URL

  DocId := Match.Groups[1].Value;
  Result := Format('https://docs.google.com/spreadsheets/d/%s/export?format=xlsx', [DocId]);

  // Preserve specific tab gid if present in the URL
  Match := TRegEx.Match(AUrl, '[#&?]gid=([0-9]+)');
  if Match.Success then
  begin
    Gid := Match.Groups[1].Value;
    Result := Result + '&gid=' + Gid;
  end;
end;

function ColNameToIndex(const ACellRef: string): Integer;
var
  I: Integer;
  Ch: Char;
begin
  Result := 0;
  for I := 1 to Length(ACellRef) do
  begin
    Ch := UpCase(ACellRef[I]);
    if CharInSet(Ch, ['A'..'Z']) then
      Result := Result * 26 + (Ord(Ch) - Ord('A') + 1)
    else
      Break;
  end;
  Dec(Result); // 0-based (A=0, B=1, ...)
end;

function ReadZipEntryText(AZip: TZipFile; const APath: String): String;
var
  Bytes: TBytes;
  Index: Integer;
  CleanPath: String;
begin
  Result := '';
  CleanPath := APath;
  if CleanPath.StartsWith('/') then
    Delete(CleanPath, 1, 1);

  Index := AZip.IndexOf(CleanPath);
  if Index >= 0 then
  begin
    AZip.Read(Index, Bytes);
    Result := TEncoding.UTF8.GetString(Bytes);
  end;
end;

class function TBIExcelXLSX.FileFilter: TFileFilters;
begin
  result:=nil;
  result.Add('Spreadsheet files','*.xlsx');
end;

class function TBIExcelXLSX.Supports(const Extension:String):Boolean;
begin
  result:=SameText(Extension,'.XLSX');
end;

(*
function ParseSharedStrings(const AXmlText: string): TArray<string>;
var
  Doc: IXMLDocument;
  Root, SiNode, TNode: IXMLNode;
  I, J: Integer;
  List: TList<string>;
  Combined: string;
begin
  if AXmlText = '' then
    Exit(nil);

  List := TList<string>.Create;
  try
    Doc := LoadXMLData(AXmlText);
    Root := Doc.DocumentElement;
    for I := 0 to Root.ChildNodes.Count - 1 do
    begin
      SiNode := Root.ChildNodes[I];
      if SiNode.LocalName = 'si' then
      begin
        Combined := '';
        for J := 0 to SiNode.ChildNodes.Count - 1 do
        begin
          TNode := SiNode.ChildNodes[J];
          if TNode.LocalName = 't' then
            Combined := Combined + TNode.Text
          else if (TNode.LocalName = 'r') and (TNode.ChildNodes.FindNode('t') <> nil) then
            Combined := Combined + TNode.ChildNodes.FindNode('t').Text;
        end;
        List.Add(Combined);
      end;
    end;
    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

function GetCellText(ACellNode: IXMLNode; const ASharedStrings: TArray<string>; out AIsString: Boolean): string;
var
  CellType: string;
  VNode, IsNode, TNode: IXMLNode;
  Idx: Integer;
begin
  Result := '';
  AIsString := False;
  CellType := VarToStr(ACellNode.Attributes['t']);

  if CellType = 'inlineStr' then
  begin
    AIsString := True;
    IsNode := ACellNode.ChildNodes.FindNode('is');
    if IsNode <> nil then
    begin
      TNode := IsNode.ChildNodes.FindNode('t');
      if TNode <> nil then
        Result := TNode.Text;
    end;
  end
  else
  begin
    VNode := ACellNode.ChildNodes.FindNode('v');
    if VNode = nil then
      Exit('');

    if CellType = 's' then
    begin
      AIsString := True;
      Idx := StrToIntDef(VNode.Text, -1);
      if (Idx >= 0) and (Idx < Length(ASharedStrings)) then
        Result := ASharedStrings[Idx];
    end
    else if CellType = 'str' then
    begin
      AIsString := True;
      Result := VNode.Text;
    end
    else
      Result := VNode.Text; // Numeric value
  end;
end;

procedure ImportXlsxStream(AStream: TStream);
var
  Zip: TZipFile;
  SharedStrings: TArray<string>;
  SheetXml: string;
  Doc: IXMLDocument;
  SheetData, RowNode, CellNode: IXMLNode;
  R, C, RowNum, ColIdx, SeriesIdx: Integer;
  CellRef, CellVal, XLabel: string;
  IsStr, HasXNum: Boolean;
  XVal, YVal: Double;
  FS: TFormatSettings;
  SeriesMap: TDictionary<Integer, TChartSeries>;
  Series: TChartSeries;
begin
  FS := TFormatSettings.Invariant;

  Zip := TZipFile.Create;
  SeriesMap := TDictionary<Integer, TChartSeries>.Create;
  try
    Zip.Open(AStream, zmRead);
    SharedStrings := ParseSharedStrings(ReadZipEntryText(Zip, 'xl/sharedStrings.xml'));
    SheetXml := ReadZipEntryText(Zip, 'xl/worksheets/sheet1.xml');
    if SheetXml = '' then
      raise Exception.Create('xl/worksheets/sheet1.xml not found in XLSX archive.');

    Doc := LoadXMLData(SheetXml);
    SheetData := Doc.DocumentElement.ChildNodes.FindNode('sheetData');
    if SheetData = nil then
      Exit;

    for R := 0 to SheetData.ChildNodes.Count - 1 do
    begin
      RowNode := SheetData.ChildNodes[R];
      if RowNode.LocalName <> 'row' then
        Continue;

      RowNum := StrToIntDef(VarToStr(RowNode.Attributes['r']), R + 1);

      // Row 1: Create series and set titles from columns B..N
      if RowNum = 1 then
      begin
        for C := 0 to RowNode.ChildNodes.Count - 1 do
        begin
          CellNode := RowNode.ChildNodes[C];
          CellRef := VarToStr(CellNode.Attributes['r']);
          ColIdx := ColNameToIndex(CellRef);
          if ColIdx >= 1 then // Skip Col A (0)
          begin
            CellVal := GetCellText(CellNode, SharedStrings, IsStr);
            Series := ASeriesClass.Create(AChart);
            Series.Title := CellVal;
            AChart.AddSeries(Series);
            SeriesMap.Add(ColIdx, Series);
          end;
        end;
        Continue;
      end;

      // Rows 2..N: Extract X (Col A) first, then Y values (Cols B..N)
      HasXNum := False;
      XVal := RowNum - 2;
      XLabel := '';

      for C := 0 to RowNode.ChildNodes.Count - 1 do
      begin
        CellNode := RowNode.ChildNodes[C];
        ColIdx := ColNameToIndex(VarToStr(CellNode.Attributes['r']));
        if ColIdx = 0 then
        begin
          CellVal := GetCellText(CellNode, SharedStrings, IsStr);
          if not IsStr and TryStrToFloat(CellVal, XVal, FS) then
            HasXNum := True
          else
            XLabel := CellVal;
          Break;
        end;
      end;

      for C := 0 to RowNode.ChildNodes.Count - 1 do
      begin
        CellNode := RowNode.ChildNodes[C];
        ColIdx := ColNameToIndex(VarToStr(CellNode.Attributes['r']));
        if (ColIdx >= 1) and SeriesMap.TryGetValue(ColIdx, Series) then
        begin
          CellVal := GetCellText(CellNode, SharedStrings, IsStr);
          if (CellVal <> '') and TryStrToFloat(CellVal, YVal, FS) then
          begin
            if HasXNum then
              Series.AddXY(XVal, YVal, XLabel)
            else
              Series.Add(YVal, XLabel);
          end;
        end;
      end;
    end;
  finally
    Zip.Free;
  end;
end;
*)

function EscapeXml(const S: String): String;
begin
  Result := S.Replace('&', '&amp;')
             .Replace('<', '&lt;')
             .Replace('>', '&gt;')
             .Replace('"', '&quot;')
             .Replace('''', '&apos;');
end;

function ColIndexToName(AColIndex: Integer): String; // 1-based: 1 -> A, 2 -> B
var
  Dividend, Modulo: Integer;
begin
  Result := '';
  Dividend := AColIndex;
  while Dividend > 0 do
  begin
    Modulo := (Dividend - 1) mod 26;
    Result := Chr(65 + Modulo) + Result;
    Dividend := (Dividend - Modulo) div 26;
  end;
end;

function RowIndexFromRef(const ACellRef: String): Integer; // A12 -> 12
var
  I: Integer;
begin
  for I := 1 to Length(ACellRef) do
    if CharInSet(ACellRef[I], ['0'..'9']) then
      Exit(StrToIntDef(Copy(ACellRef, I, MaxInt), 0));
  Result := 0;
end;

procedure ParseRangeBounds(const ARange: String; out MinCol, MinRow, MaxCol, MaxRow: Integer);
var
  Parts: TArray<String>;
  CleanRange: String;
begin
  MinCol := 1;
  MinRow := 1;
  MaxCol := MaxInt;
  MaxRow := MaxInt;

  CleanRange := ARange.Replace('$', '').Trim;
  if CleanRange = '' then
    Exit;

  Parts := CleanRange.Split([':']);
  if Length(Parts) >= 1 then
  begin
    MinCol := Max(1, ColNameToIndex(Parts[0]));
    MinRow := Max(1, RowIndexFromRef(Parts[0]));
  end;

  if Length(Parts) >= 2 then
  begin
    MaxCol := ColNameToIndex(Parts[1]);
    MaxRow := RowIndexFromRef(Parts[1]);
    if MaxCol <= 0 then MaxCol := MaxInt;
    if MaxRow <= 0 then MaxRow := MaxInt;
  end
  else
  begin
    MaxCol := MinCol;
    MaxRow := MinRow;
  end;
end;

procedure AddStringToZip(AZip: TZipFile; const AArchivePath, AContent: String);
var
  Bytes: TBytes;
  Stream: TBytesStream;
begin
  Bytes := TEncoding.UTF8.GetBytes(AContent);
  Stream := TBytesStream.Create(Bytes);
  try
    AZip.Add(Stream, AArchivePath);
  finally
    Stream.Free;
  end;
end;

type
  TXlsxSheetInfo = record
    Name: String;
    RelId: String;
    TargetPath: String;
  end;

  TSheetGrid = class
  private
    // Row -> (Col -> XML cell snippet)
    FRows: TObjectDictionary<Integer, TDictionary<Integer, String>>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetStringCell(const ARow, ACol: Integer; const AValue: String);
    procedure SetNumberCell(const ARow, ACol: Integer; const AValue: Double; const AFS: TFormatSettings);
    function ToXml: String;
  end;

constructor TSheetGrid.Create;
begin
  inherited Create;
  FRows := TObjectDictionary<Integer, TDictionary<Integer, String>>.Create([doOwnsValues]);
end;

destructor TSheetGrid.Destroy;
begin
  FRows.Free;
  inherited;
end;

procedure TSheetGrid.SetStringCell(const ARow, ACol: Integer; const AValue: String);
var
  RowDict: TDictionary<Integer, String>;
  CellRef: String;
begin
  if not FRows.TryGetValue(ARow, RowDict) then
  begin
    RowDict := TDictionary<Integer, String>.Create;
    FRows.Add(ARow, RowDict);
  end;
  CellRef := ColIndexToName(ACol) + IntToStr(ARow);
  RowDict.AddOrSetValue(ACol, Format('<c r="%s" t="inlineStr"><is><t>%s</t></is></c>',
    [CellRef, EscapeXml(AValue)]));
end;

procedure TSheetGrid.SetNumberCell(const ARow, ACol: Integer; const AValue: Double; const AFS: TFormatSettings);
var
  RowDict: TDictionary<Integer, String>;
  CellRef: String;
begin
  if not FRows.TryGetValue(ARow, RowDict) then
  begin
    RowDict := TDictionary<Integer, String>.Create;
    FRows.Add(ARow, RowDict);
  end;
  CellRef := ColIndexToName(ACol) + IntToStr(ARow);
  RowDict.AddOrSetValue(ACol, Format('<c r="%s"><v>%s</v></c>',
    [CellRef, FloatToStr(AValue, AFS)]));
end;

function TSheetGrid.ToXml: String;
var
  SB: TStringBuilder;
  RowKeys, ColKeys: TArray<Integer>;
  R, C: Integer;
  RowDict: TDictionary<Integer, String>;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    SB.AppendLine('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
    SB.AppendLine('<sheetData>');

    RowKeys := FRows.Keys.ToArray;
    TArray.Sort<Integer>(RowKeys);

    for R in RowKeys do
    begin
      RowDict := FRows[R];
      SB.AppendFormat('<row r="%d">', [R]);

      ColKeys := RowDict.Keys.ToArray;
      TArray.Sort<Integer>(ColKeys);
      for C in ColKeys do
        SB.Append(RowDict[C]);

      SB.AppendLine('</row>');
    end;

    SB.AppendLine('</sheetData>');
    SB.AppendLine('</worksheet>');
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

{ TBIXLSXEngine }

class procedure TBIXLSXEngine.SaveToStream(const AData: TDataItem; const AStream: TStream);
type
  TExportSheet = record
    Name: String;
    Xml: String;
  end;

var
  Sheets: TList<TExportSheet>;
  UsedSheetNames: TDictionary<String, Integer>;
  InvariantFS: TFormatSettings;

  function CorrectSheetName(const S: String): String;
  var
    BaseName, Candidate: String;
    Counter: Integer;
  begin
    if S = '' then
      BaseName := 'Sheet1'
    else
      BaseName := S;

    // Strip characters forbidden by Excel in worksheet tab names: \ / ? * [ ] :
    BaseName := BaseName.Replace('\', '_').Replace('/', '_').Replace('?', '_')
                        .Replace('*', '_').Replace('[', '_').Replace(']', '_')
                        .Replace(':', '_');

    if Length(BaseName) > 31 then
      BaseName := Copy(BaseName, 1, 31);

    Candidate := BaseName;
    Counter := 2;
    while UsedSheetNames.ContainsKey(UpperCase(Candidate)) do
    begin
      Candidate := Copy(BaseName, 1, 31 - Length(IntToStr(Counter)) - 1) + '_' + IntToStr(Counter);
      Inc(Counter);
    end;

    UsedSheetNames.Add(UpperCase(Candidate), 1);
    Result := Candidate;
  end;

  function CalcLevels(const AItem: TDataItem): Integer;
  var
    tmp: TDataItem;
    tmpCount: Integer;
  begin
    if AItem.AsTable then
    begin
      Result := 1;
      for tmp in AItem.Items.AsArray do
        if tmp.AsTable then
        begin
          tmpCount := CalcLevels(tmp) + 1;
          if tmpCount > Result then
            Result := tmpCount;
        end;
    end
    else
      Result := 0;
  end;

  procedure AddValues(const AGrid: TSheetGrid; const AItem: TDataItem; const FirstRow, ACol: Integer);
  var
    t: TLoopInteger;
  begin
    for t := 0 to AItem.Count - 1 do
      if not AItem.Missing[t] then
      begin
        if AItem.Kind.IsNumeric then
           AGrid.SetNumberCell(FirstRow + t, ACol, AItem.NumberAt(t), InvariantFS)
        else
        if AItem.Kind=TDataKind.dkBoolean then
           AGrid.SetNumberCell(FirstRow + t, ACol, Ord(AItem.BooleanData[t]), InvariantFS)
        else
           AGrid.SetStringCell(FirstRow + t, ACol, AItem.DataToString(t));
      end;
  end;

  procedure AddTable(const AItem: TDataItem);
  var
    Grid: TSheetGrid;
    SheetRec: TExportSheet;
    FirstRow, tmpRow, t: Integer;
    tt: TLoopInteger;
    tmp, tmpData: TDataItem;
  begin
    SheetRec.Name := CorrectSheetName(AItem.Name);
    Grid := TSheetGrid.Create;
    try
      FirstRow := CalcLevels(AItem) + 1;

      for t := 0 to AItem.Items.Count - 1 do
      begin
        tmp := AItem.Items[t];
        tmpData := tmp;
        tmpRow := 1;

        repeat
          Grid.SetStringCell(tmpRow, 1 + t, tmp.Name);

          if tmp.AsTable then
          begin
            tmpData := tmp;
            if tmp.Items.Count > 0 then
            begin
              tmp := tmp.Items[0];
              Inc(tmpRow);
            end;
          end;
        until not tmp.AsTable;

        if tmpData.AsTable then
          for tt := 0 to tmpData.Items.Count - 1 do
          begin
            Grid.SetStringCell(tmpRow, 1 + t + tt, tmpData.Items[tt].Name);
            AddValues(Grid, tmpData.Items[tt], FirstRow, 1 + t + tt);
          end
        else
          AddValues(Grid, tmpData, FirstRow, 1 + t);
      end;

      SheetRec.Xml := Grid.ToXml;
      Sheets.Add(SheetRec);
    finally
      Grid.Free;
    end;
  end;

  procedure AddColumn(const AItem: TDataItem);
  var
    Grid: TSheetGrid;
    SheetRec: TExportSheet;
  begin
    SheetRec.Name := CorrectSheetName(AItem.Name);
    Grid := TSheetGrid.Create;
    try
      AddValues(Grid, AItem, 1, 1);
      SheetRec.Xml := Grid.ToXml;
      Sheets.Add(SheetRec);
    finally
      Grid.Free;
    end;
  end;

  procedure AddData(const AItem: TDataItem);
  var
    tmp: TDataItem;
  begin
    if AItem.AsTable then
      AddTable(AItem)
    else if AItem.Kind = TDataKind.dkUnknown then
    begin
      for tmp in AItem.Items.AsArray do
        AddData(tmp);
    end
    else
      AddColumn(AItem);
  end;

var
  Zip: TZipFile;
  ContentTypesSB, WorkbookSB, WorkbookRelsSB: TStringBuilder;
  I: Integer;
  RelsXml: String;
  EmptyGrid: TSheetGrid;
  EmptySheet: TExportSheet;
begin
  InvariantFS := TFormatSettings.Invariant;
  Sheets := TList<TExportSheet>.Create;
  UsedSheetNames := TDictionary<String, Integer>.Create;
  try
    if AData <> nil then
      AddData(AData);

    // Excel requires at least one worksheet in a valid workbook
    if Sheets.Count = 0 then
    begin
      EmptySheet.Name := CorrectSheetName('Sheet1');
      EmptyGrid := TSheetGrid.Create;
      try
        EmptySheet.Xml := EmptyGrid.ToXml;
      finally
        EmptyGrid.Free;
      end;
      Sheets.Add(EmptySheet);
    end;

    ContentTypesSB := TStringBuilder.Create;
    WorkbookSB := TStringBuilder.Create;
    WorkbookRelsSB := TStringBuilder.Create;
    Zip := TZipFile.Create;
    try
      ContentTypesSB.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
      ContentTypesSB.Append('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">');
      ContentTypesSB.Append('<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>');
      ContentTypesSB.Append('<Default Extension="xml" ContentType="application/xml"/>');
      ContentTypesSB.Append('<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>');

      WorkbookSB.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
      WorkbookSB.Append('<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">');
      WorkbookSB.Append('<sheets>');

      WorkbookRelsSB.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
      WorkbookRelsSB.Append('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');

      RelsXml :=
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' +
        '</Relationships>';

      Zip.Open(AStream, zmWrite);
      AddStringToZip(Zip, '_rels/.rels', RelsXml);

      for I := 0 to Sheets.Count - 1 do
      begin
        ContentTypesSB.AppendFormat(
          '<Override PartName="/xl/worksheets/sheet%d.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>',
          [I + 1]);

        WorkbookSB.AppendFormat(
          '<sheet name="%s" sheetId="%d" r:id="rId%d"/>',
          [EscapeXml(Sheets[I].Name), I + 1, I + 1]);

        WorkbookRelsSB.AppendFormat(
          '<Relationship Id="rId%d" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet%d.xml"/>',
          [I + 1, I + 1]);

        AddStringToZip(Zip, Format('xl/worksheets/sheet%d.xml', [I + 1]), Sheets[I].Xml);
      end;

      ContentTypesSB.Append('</Types>');
      WorkbookSB.Append('</sheets></workbook>');
      WorkbookRelsSB.Append('</Relationships>');

      AddStringToZip(Zip, '[Content_Types].xml', ContentTypesSB.ToString);
      AddStringToZip(Zip, 'xl/workbook.xml', WorkbookSB.ToString);
      AddStringToZip(Zip, 'xl/_rels/workbook.xml.rels', WorkbookRelsSB.ToString);

      Zip.Close;
    finally
      Zip.Free;
      WorkbookRelsSB.Free;
      WorkbookSB.Free;
      ContentTypesSB.Free;
    end;
  finally
    UsedSheetNames.Free;
    Sheets.Free;
  end;
end;

class procedure TBIXLSXEngine.SaveToFile(const AData: TDataItem; const AFileName: String);
var FS: TFileStream;
begin
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(AData, FS);
  finally
    FS.Free;
  end;
end;

initialization
  TBIExcelExport.Engine:=TBIXLSXEngine;
  TBIFileImporters.RegisterClass(TBIExcelXLSX);
finalization
  TBIExcelExport.Engine:=TBIExcelEngine;
  TBIFileImporters.UnRegisterClass(TBIExcelXLSX);
end.
