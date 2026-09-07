# Shift 002 — Grok wake / laptop. Tokens stay on this machine. Never echo them.
# Pulls the latest Fileman + orange-cloud installer from raw git (not Pages).
# Then Filemans catalog index.html (agency002 may only have a 120.cash/ ghost link).
# Pages has served a 13-byte PLACEHOLDER on ftp-drop paths. Raw git is the pack.
# Does not send mail. Does not touch PayPal. Does not replace workers grok / grok-cf.
#
#   powershell -File RUN-SHIFT002.ps1

$ErrorActionPreference = 'Stop'
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'
$Url = "$Drop/install-hub-hook.ps1"
$Out = Join-Path $env:TEMP 'shift002-install-hub-hook.ps1'
Invoke-WebRequest -Uri $Url -OutFile $Out -UseBasicParsing
& $Out

$Cat = Join-Path $env:TEMP 'shift002-write-catalog-index.ps1'
try {
  Invoke-WebRequest -Uri "$Drop/write-catalog-index.ps1" -OutFile $Cat -UseBasicParsing
  & $Cat
} catch {
  Write-Host ("catalog index: {0}" -f $_.Exception.Message)
}
