@echo off
start /min powershell -WindowStyle Hidden -File "%~dp0fix_emulator_window.ps1"
echo Emulator window fix running in background.
echo Close VS Code and reopen, then run the emulator.
pause
