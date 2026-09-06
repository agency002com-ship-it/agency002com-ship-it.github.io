@echo off
REM Drop next to GrokWork\ftp\DEPLOY-ALL-NOW.bat
REM Overwrites 120.cash index + patches keychain cash_120 return.
REM Does not send mail. Does not touch PayPal.

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0upload-120cash.ps1"
exit /b %ERRORLEVEL%
