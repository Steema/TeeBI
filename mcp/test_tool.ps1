param (
  [string]$Tool = "teebi_query_natural_language",
  [object]$ToolArgs = @{
    dataset = "Restaurants"
    query_text = "count by cuisine"
  },
  [string]$ExePath = ".\TeeBI_MCP.exe",
  [string]$DataDir = "..\sampledata"
)

if ($ToolArgs -is [string]) {
  if ($ToolArgs.Trim() -eq "" -or $ToolArgs -eq "{}") {
    $argsJson = "{}"
  } else {
    $argsJson = $ToolArgs
  }
} else {
  $argsJson = $ToolArgs | ConvertTo-Json -Compress
}

$initReq = '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}}'
$toolReq = '{"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "' + $Tool + '", "arguments": ' + $argsJson + '}}'

Write-Host "Connecting to TeeBI MCP Server ($ExePath)..." -ForegroundColor Cyan
Write-Host "Calling Tool: $Tool" -ForegroundColor Yellow
Write-Host "Arguments: $argsJson" -ForegroundColor Gray

$inputPayload = "$initReq`n$toolReq`n"

$process = New-Object System.Diagnostics.Process
$process.StartInfo.FileName = $ExePath
$process.StartInfo.Arguments = "--data-dir `"$DataDir`""
$process.StartInfo.UseShellExecute = $false
$process.StartInfo.RedirectStandardInput = $true
$process.StartInfo.RedirectStandardOutput = $true
$process.StartInfo.RedirectStandardError = $true
$process.StartInfo.CreateNoWindow = $true

$process.Start() | Out-Null

$writer = $process.StandardInput
$writer.Write($inputPayload)
$writer.Flush()
$writer.Close()

$output = $process.StandardOutput.ReadToEnd()
$stderr = $process.StandardError.ReadToEnd()
$process.WaitForExit()

if ($stderr) {
  Write-Host "[Server stderr]: $stderr" -ForegroundColor DarkGray
}

# Parse response lines
$lines = $output -split "`r?`n"
foreach ($line in $lines) {
  if ($line.Trim() -ne "") {
    $json = $line | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($json -and $json.id -eq 2) {
      Write-Host "`n=== Result from $Tool ===" -ForegroundColor Green
      if ($json.result.content) {
        $text = $json.result.content[0].text
        # Pretty print if JSON
        try {
          $parsedText = $text | ConvertFrom-Json
          $parsedText | ConvertTo-Json -Depth 6
        } catch {
          Write-Output $text
        }
      } else {
        $json.result | ConvertTo-Json -Depth 5
      }
    }
  }
}
