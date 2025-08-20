program BIWeb_Debug;

uses
  System.SysUtils,
  Vcl.Forms,
  Main_VCL_Web in '..\VCL\Main_VCL_Web.pas' {FormBIWeb},
  Unit_Constants in '..\vcl\Unit_Constants.pas' {FormConstants},
  BI.Web.AllData in '..\BI.Web.AllData.pas',
  BI.Web.Common in '..\BI.Web.Common.pas',
  BI.Web.Common.Chart in '..\BI.Web.Common.Chart.pas',
  BI.Web.SingleInstance in '..\BI.Web.SingleInstance.pas',
  BI.Web.IndyContext in '..\BI.Web.IndyContext.pas',
  BI.Web.Server.Indy in '..\BI.Web.Server.Indy.pas',
  BI.Web.Context in '..\BI.Web.Context.pas',
  BI.Web.Logs in '..\BI.Web.Logs.pas',
  BI.Web.Modules.Default in '..\BI.Web.Modules.Default.pas',
  BI.Web.Modules in '..\BI.Web.Modules.pas',
  BI.Web.Scheduler in '..\BI.Web.Scheduler.pas',
  BIWeb_Exception in 'BIWeb_Exception.pas';

{$R *.res}

begin
  {$IFOPT D+}
  ReportMemoryLeaksOnShutdown:=True;
  {$ENDIF}

  try
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TFormBIWeb, FormBIWeb);
    Application.CreateForm(TFormConstants, FormConstants);
    Application.Run;
  except
    on E:Exception do
       TBIWeb_Exception.Save(E);
  end;
end.
