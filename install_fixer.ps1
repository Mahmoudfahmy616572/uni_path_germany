$scriptPath = "$env:USERPROFILE\uni_path_germany\fix_emulator_window.ps1"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -RunLevel Limited
Register-ScheduledTask -TaskName "FixEmulatorWindow" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force

Write-Output "Done. Task installed."
