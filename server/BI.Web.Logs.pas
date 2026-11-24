{*********************************************}
{  TeeBI Software Library                     }
{  Store logs of this web server in TeeBI     }
{  format.                                    }
{                                             }
{  Copyright (c) 2015-2026 by Steema Software }
{  All Rights Reserved                        }
{*********************************************}
unit BI.Web.Logs;

interface

uses
  System.SyncObjs,
  BI.Web.Context, BI.DataItem;

type
  THistoryProc=procedure(const AContext:TWebContext;
                         const Command:String;
                         const Tag:String;
                         const Success:Boolean;
                         const Millisec:Integer;
                         const Size:Int64) of object;

  TWebLogs=class
  private
    Lock : TCriticalSection;

    procedure SetCurrentFile;
  public
    const
      LogExtension='.bilog';

    var
    AddHistory : THistoryProc;
    History : TDataItem;

    CurrentFile : String;
    Persist : Boolean;
    Store : String;

    Constructor Create;
    Destructor Destroy; override;

    procedure Enter;
    procedure Leave;

    procedure TrySave;

    class procedure DebugMsg(const AMessage:String); static;
  end;

implementation

uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  {$IFDEF LINUX}
  {$IFDEF FPC}SystemLog{$ELSE}Posix.Base{$ENDIF},
  {$ENDIF}

  System.SysUtils, System.IOUtils,
  BI.Persist;

{ TWebLogs }

function DateTimeFile(const ADate:TDateTime):String;
begin
  result:=FormatDateTime('yyyymmdd_hhnnss',ADate);
end;

Constructor TWebLogs.Create;
begin
  inherited Create;
  Lock:=TCriticalSection.Create;
end;

{$IFDEF LINUX}
const
  LOG_USER = 1 shl 3;
  LOG_DEBUG = 7;

procedure syslog(priority: Integer; format: MarshaledAString); cdecl; varargs;
  external libc name 'syslog';
{$ENDIF}

class procedure TWebLogs.DebugMsg(const AMessage: String);
{$IFDEF LINUX}
var M:TMarshaller;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  OutputDebugString(PChar(AMessage));
  {$ENDIF}

  {$IFDEF LINUX}
  syslog(LOG_USER or LOG_DEBUG, '%s', M.AsUtf8(AMessage).ToPointer);
  {$ENDIF}
end;

Destructor TWebLogs.Destroy;
begin
  Lock.Free;
  inherited;
end;

procedure TWebLogs.Enter;
begin
  Lock.Enter;
end;

procedure TWebLogs.Leave;
begin
  Lock.Leave;
end;

procedure TWebLogs.SetCurrentFile;
var tmp : String;
begin
  if (Store='') or (TStores.IndexOf(Store)=-1) then
     tmp:=TPath.Combine(TPath.GetDocumentsPath,'BIWeb')
  else
     tmp:=TStore.PathOf(Store);

  if not TDirectory.Exists(tmp) then
     ForceDirectories(tmp);

  CurrentFile:=TPath.Combine(tmp,DateTimeFile(Now)+LogExtension);
end;

procedure TWebLogs.TrySave;
begin
  Lock.Enter;
  try
    if CurrentFile='' then
       SetCurrentFile;

    TDataItemPersistence.Save(History,CurrentFile);
  finally
    Lock.Leave;
  end;
end;

end.
