program BI_Tests;

uses
  {$IFDEF FullDebugMode}
  FastMM4,
  {$ENDIF }
  Vcl.Forms,
  BI_Unit in 'BI_Unit.pas' {FormTests},
  BI_Demo_Data in 'BI_Demo_Data.pas';

{$R *.res}

begin
  {$IFOPT D+}
  ReportMemoryLeaksOnShutdown:=True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormTests, FormTests);
  Application.Run;
end.
