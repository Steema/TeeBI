unit Unit_ConvertDateTime;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  VCLBI.DataControl, VCLBI.Grid,

  BI.DataItem;

type
  TFormDateTimeConvert = class(TForm)
    BIGrid1: TBIGrid;
    Panel1: TPanel;
    BIGrid2: TBIGrid;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }

    DateTimeColumn,
    DateTimeTable : TDataItem;
  public
    { Public declarations }
  end;

var
  FormDateTimeConvert: TFormDateTimeConvert;

implementation

{$R *.dfm}

uses
  BI.Convert;

procedure TFormDateTimeConvert.FormCreate(Sender: TObject);
var t : Integer;
begin
  // Create single column
  DateTimeColumn:=TDataItem.Create(TDataKind.dkDateTime,'DateTime');

  // Fill with random date-time

  DateTimeColumn.Resize(100);

  for t:=0 to DateTimeColumn.Count-1 do
      DateTimeColumn.DateTimeData[t]:=Now+t+t*0.001;

  // Show in left Grid
  BIGrid1.Data:=DateTimeColumn;
end;

// From single date-time column to table structure:
procedure TFormDateTimeConvert.Button1Click(Sender: TObject);
begin
  DateTimeTable.Free;

  DateTimeTable:=TDateTimeConvert.ToTable(DateTimeColumn);

  BIGrid2.Data:=DateTimeTable;

  Button2.Enabled:=True;
end;

// From date-time table structure to a single column:
procedure TFormDateTimeConvert.Button2Click(Sender: TObject);
begin
  DateTimeColumn.Free;

  DateTimeColumn:=TDateTimeConvert.ToDateTime(DateTimeTable);

  BIGrid1.Data:=DateTimeColumn;
end;

procedure TFormDateTimeConvert.FormDestroy(Sender: TObject);
begin
  DateTimeColumn.Free;
  DateTimeTable.Free;
end;

end.
