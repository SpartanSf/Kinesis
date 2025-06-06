Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "cmd /c luajit.exe launch.lua", 0
Set WshShell = Nothing