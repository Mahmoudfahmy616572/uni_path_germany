@echo off
set ANDROID_HOME=%USERPROFILE%\AppData\Local\Android\Sdk
"%ANDROID_HOME%\emulator\emulator.exe" -avd Pixel_10_Pro -no-snapshot
