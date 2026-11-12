program TeeBI_MCP;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  BI.MCP in 'BI.MCP.pas';

var
  Server: TBI_MCPServer;
  DataDir: String;
  I: Integer;
begin
  DataDir := '';

  // Parse command line arguments
  I := 1;
  while I <= ParamCount do
  begin
    if (ParamStr(I) = '--data-dir') or (ParamStr(I) = '-d') then
    begin
      Inc(I);

      if I <= ParamCount then
        DataDir := ParamStr(I);
    end;

    Inc(I);
  end;

  if DataDir = '' then
  begin
    // Check common locations
    if TDirectory.Exists('..\..\sampledata') then
      DataDir := TPath.GetFullPath('..\..\sampledata')
    else
    if TDirectory.Exists('sampledata') then
        DataDir := TPath.GetFullPath('sampledata')
  end;

  Server := TBI_MCPServer.Create(DataDir);
  try
    Server.Run;
  finally
    Server.Free;
  end;
end.
