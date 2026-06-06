unit BIWeb_Exception;

interface

{
   This unit uses madExcept api to save the exception and stack trace to
   a text log file, at Documents\BIWeb folder.

   https://www.madshi.net/
}

{$DEFINE USE_MADEXCEPT}

uses
  Vcl.Forms,
  System.SysUtils,
  System.DateUtils,

  {$IFDEF USE_MADEXCEPT}
  madExcept,
  madStackTrace
  {$ENDIF}

  System.IOUtils;

type
  TBIWeb_Exception=class
  private
    procedure HandleException(Sender: TObject; E: Exception);
  public
    class var Prefix:String;

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
  tmp:=TPath.Combine(tmp,TBIWeb_Exception.Prefix+FormatDateTime('yyyymmdd_hhnnss',Now)+'.txt');

  {$IFDEF USE_MADEXCEPT}
  TFile.WriteAllText(tmp,S+#13#10+#13#10+ MadStackTrace.StackTrace);
  {$ENDIF}
end;

class procedure TBIWeb_Exception.Save(const E:Exception);
{$IFDEF USE_MADEXCEPT}
var ex: IMEException;
{$ENDIF}
begin
  {$IFDEF USE_MADEXCEPT}
  ex := madExcept.NewException;
  Log(e.Message+#13#10+ex.BugReport);
  {$ENDIF}
end;

var E : TBIWeb_Exception;
initialization
  TBIWeb_Exception.Prefix:='BIWeb_Exception_';

  E:=TBIWeb_Exception.Create;
  Application.OnException:=E.HandleException;
finalization
  E.Free;
end.
