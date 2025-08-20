## BIWeb server DEBUG version

Small project that configures BIWeb server (Windows VCL version) to use [madExcept](https://www.madshi.net/) Delphi library.

When an exception happens in BIWeb, madExcept is used to generate the bug report including the stack-trace that generated the exception.

This report is saved as a plain text file at your ```Documents\BIWeb``` folder, like:

C:\Users\xxx\Documents\BIWeb\BIWeb_Exception_20250820_181625.txt

### Exception report example:

This is a test exception raised at Form OnCreate event, just to produce the report:

```
date/time          : 2025-08-20, 18:16:24, 875ms
computer name      : xxxx
user name          : david
registered owner   : david
operating system   : Windows 11 x64 build 26100
system language    : English
system up time     : 6 days 19 hours
program up time    : 2 seconds
processors         : 20x 13th Gen Intel(R) Core(TM) i9-13900HK
physical memory    : 15814/32463 MB (free/total)
free disk space    : (C:) 861,57 GB
display mode       : 3840x2160, 32 bit
process id         : $1408
allocated memory   : 42,22 MB
largest free block : 1,20 GB
executable         : BIWeb_Debug.exe
exec. date/time    : 2025-08-20 18:16
version            : 1.0.0.0
compiled with      : Delphi 12
madExcept version  : 5.1.5
callstack crc      : $00000000, $00000000, $c6ab1d89
exception number   : 1
exception message  : The application seems to be frozen.

thread $73b8:
76a55d47 +17 KERNEL32.DLL  BaseThreadInitThunk

thread $7878:
76a55d47 +17 KERNEL32.DLL  BaseThreadInitThunk

thread $76ec:
76a55d47 +17 KERNEL32.DLL  BaseThreadInitThunk

thread $893c:
7672770c +4c USER32.dll    MsgWaitForMultipleObjectsEx
76723a6a +1a USER32.dll    MsgWaitForMultipleObjects
76a55d47 +17 KERNEL32.DLL  BaseThreadInitThunk

thread $20c: <priority:2>
768ea72c +0bc WS2_32.dll                                        select
013bc03a +062 BIWeb_Debug.exe IdStackWindows           1911  +8 TIdSocketListWindows.FDSelect
013bbfc8 +020 BIWeb_Debug.exe IdStackWindows           1894  +3 TIdSocketListWindows.SelectRead
013c3952 +006 BIWeb_Debug.exe IdSocketHandle            652  +1 TIdSocketHandle.Select
013da660 +048 BIWeb_Debug.exe IdServerIOHandlerSocket   130 +10 TIdServerIOHandlerSocket.Accept
013da6c7 +0af BIWeb_Debug.exe IdServerIOHandlerSocket   140 +20 TIdServerIOHandlerSocket.Accept
013dc4d8 +058 BIWeb_Debug.exe IdCustomTCPServer        1107 +15 TIdListenerThread.Run
013d95ad +0f5 BIWeb_Debug.exe IdThread                  436 +50 TIdThread.Execute
013d9664 +1ac BIWeb_Debug.exe IdThread                  459 +73 TIdThread.Execute
013d96a4 +1ec BIWeb_Debug.exe IdThread                  466 +80 TIdThread.Execute
013d96d0 +218 BIWeb_Debug.exe IdThread                  470 +84 TIdThread.Execute
00da0219 +049 BIWeb_Debug.exe System.Classes          16396 +18 ThreadProc
00da027c +0ac BIWeb_Debug.exe System.Classes          16425 +47 ThreadProc
00ccb4c8 +028 BIWeb_Debug.exe System                  25850 +45 ThreadWrapper
76a55d47 +017 KERNEL32.DLL                                      BaseThreadInitThunk

thread $787c: <priority:2>
768ea72c +0bc WS2_32.dll                                        select
013bc03a +062 BIWeb_Debug.exe IdStackWindows           1911  +8 TIdSocketListWindows.FDSelect
013bbfc8 +020 BIWeb_Debug.exe IdStackWindows           1894  +3 TIdSocketListWindows.SelectRead
013c3952 +006 BIWeb_Debug.exe IdSocketHandle            652  +1 TIdSocketHandle.Select
013da660 +048 BIWeb_Debug.exe IdServerIOHandlerSocket   130 +10 TIdServerIOHandlerSocket.Accept
013da6c7 +0af BIWeb_Debug.exe IdServerIOHandlerSocket   140 +20 TIdServerIOHandlerSocket.Accept
013dc4d8 +058 BIWeb_Debug.exe IdCustomTCPServer        1107 +15 TIdListenerThread.Run
013d95ad +0f5 BIWeb_Debug.exe IdThread                  436 +50 TIdThread.Execute
013d9664 +1ac BIWeb_Debug.exe IdThread                  459 +73 TIdThread.Execute
013d96a4 +1ec BIWeb_Debug.exe IdThread                  466 +80 TIdThread.Execute
013d96d0 +218 BIWeb_Debug.exe IdThread                  470 +84 TIdThread.Execute
00da0219 +049 BIWeb_Debug.exe System.Classes          16396 +18 ThreadProc
00da027c +0ac BIWeb_Debug.exe System.Classes          16425 +47 ThreadProc
00ccb4c8 +028 BIWeb_Debug.exe System                  25850 +45 ThreadWrapper
76a55d47 +017 KERNEL32.DLL                                      BaseThreadInitThunk

thread $1ec4:
76a55d47 +17 KERNEL32.DLL  BaseThreadInitThunk

thread $77e4:
76a55d47 +17 KERNEL32.DLL  BaseThreadInitThunk

0176e1d5 BIWeb_Debug.exe BIWeb_Exception    33 Log
0176e32d BIWeb_Debug.exe BIWeb_Exception    41 TBIWeb_Exception.Save
0176e355 BIWeb_Debug.exe BIWeb_Exception    42 TBIWeb_Exception.Save
0176e0b6 BIWeb_Debug.exe BIWeb_Exception    25 TBIWeb_Exception.HandleException
00f20e72 BIWeb_Debug.exe Vcl.Forms       13628 TApplication.HandleException
00f1bffb BIWeb_Debug.exe Vcl.Forms       10219 TCustomForm.HandleCreateException
00f13645 BIWeb_Debug.exe Vcl.Forms        5536 TCustomForm.DoCreate
77a7bf3a ntdll.dll                             KiUserExceptionDispatcher
00da4278 BIWeb_Debug.exe System.Classes  19091 StdWndProc
00f13629 BIWeb_Debug.exe Vcl.Forms        5534 TCustomForm.DoCreate
00f13148 BIWeb_Debug.exe Vcl.Forms        5401 TCustomForm.AfterConstruction
00cc9da5 BIWeb_Debug.exe System          19736 @AfterConstruction
00f13104 BIWeb_Debug.exe Vcl.Forms        5391 TCustomForm.Create
00f20b66 BIWeb_Debug.exe Vcl.Forms       13527 TApplication.CreateForm
76a55d47 KERNEL32.DLL                          BaseThreadInitThunk

```

