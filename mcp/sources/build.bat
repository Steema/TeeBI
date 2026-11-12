@echo off
setlocal
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"

echo Building TeeBI MCP Server (Win64)...
dcc64 -B -CC -NSSystem;System.Win;Winapi;Data;Web;Soap;Xml -U"%BDS%\lib\win64\release;..\..\sources" -NU.\Win64\Release -ETeeBI_MCP.exe TeeBI_MCP.dpr
if errorlevel 1 (
  echo Error building Win64!
  exit /b 1
)

echo.
echo Building TeeBI MCP Server (Win32)...
dcc32 -B -CC -NSSystem;System.Win;Winapi;Data;Web;Soap;Xml -U"%BDS%\lib\win32\release;..\..\sources" -NU.\Win32\Release -ETeeBI_MCP32.exe TeeBI_MCP.dpr
if errorlevel 1 (
  echo Error building Win32!
  exit /b 1
)

echo.
echo Build completed successfully!
