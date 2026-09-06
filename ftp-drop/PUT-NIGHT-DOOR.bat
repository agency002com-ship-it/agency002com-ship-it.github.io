@echo off
REM Double-click. Always wget the latest Fileman script (WHM :2087).
REM Does not send mail. Does not touch PayPal.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop/upload-120cash.ps1' -OutFile ($env:TEMP + '\upload-120cash.ps1') -UseBasicParsing; & ($env:TEMP + '\upload-120cash.ps1')"
exit /b %ERRORLEVEL%
