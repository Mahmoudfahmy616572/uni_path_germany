' fix_emulator.vbs — تشغيل fix_emulator_window.ps1 من غير window
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\fix_emulator_window.ps1""", 0, False
