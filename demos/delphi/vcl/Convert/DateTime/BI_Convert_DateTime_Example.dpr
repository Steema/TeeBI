program BI_Convert_DateTime_Example;

uses
  Vcl.Forms,
  Unit_ConvertDateTime in 'Unit_ConvertDateTime.pas' {FormDateTimeConvert};

{$R *.res}

begin
  {$IFOPT D+}
  ReportMemoryLeaksOnShutdown:=True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormDateTimeConvert, FormDateTimeConvert);
  Application.Run;
end.
