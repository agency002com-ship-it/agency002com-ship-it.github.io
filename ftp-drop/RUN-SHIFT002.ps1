# Shift 002 — Grok wake / laptop. Tokens stay on this machine. Never echo them.
# Pulls the latest Fileman + orange-cloud installer and runs it.
# Does not send mail. Does not touch PayPal. Does not replace workers grok / grok-cf.
#
#   powershell -File RUN-SHIFT002.ps1

$ErrorActionPreference = 'Stop'
$Url = 'https://agency002com-ship-it.github.io/ftp-drop/install-hub-hook.ps1'
$Out = Join-Path $env:TEMP 'shift002-install-hub-hook.ps1'
Invoke-WebRequest -Uri $Url -OutFile $Out -UseBasicParsing
& $Out
