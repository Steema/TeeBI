unit BIWeb_Exception;

interface

{
   This unit uses madExcept api to save the exception and stack trace to
   a text log file, at Documents\BIWeb folder.

   https://www.madshi.net/
}

uses
  Vcl.Forms,
  System.SysUtils,
  System.DateUtils,
  System.IOUtils,
  madExcept,
  madStackTrace;

type
  TBIWeb_Exception=class
  private
    procedure HandleException(Sender: TObject; E: Exception);
  public
    class procedure Save(const E:Exception); static;
  end;

implementation

procedure TBIWeb_Exception.HandleException(Sender: TObject; E: Exception);
begin
  TBIWeb_Exception.Save(E);
end;

procedure Log(const S:String);
var tmp : String;
begin
  tmp:=TPath.Combine(TPath.GetDocumentsPath,'BIWeb');
  tmp:=TPath.Combine(tmp,'BIWeb_Exception_'+FormatDateTime('yyyymmdd_hhnnss',Now)+'.txt');
  TFile.WriteAllText(tmp,S+#13#10+#13#10+
     MadStackTrace.StackTrace);
end;

class procedure TBIWeb_Exception.Save(const E:Exception);
var ex: IMEException;
begin
  ex := madExcept.NewException;
  Log(e.Message+#13#10+ex.BugReport);
end;

var E : TBIWeb_Exception;
initialization
  E:=TBIWeb_Exception.Create;
  Application.OnException:=E.HandleException;
finalization
  E.Free;
end.
