# Shift 002 — Grok wake / laptop. Tokens stay on this machine. Never echo them.
# Pulls the latest Fileman + orange-cloud installer from raw git (not Pages).
# Then Filemans catalog index.html (agency002 may only have a 120.cash/ ghost link).
# Pages has served a 13-byte PLACEHOLDER on ftp-drop paths. Raw git is the pack.
# After the hook sets github.io secrets (whm-api.ps1 $Token included; empty
# $env:CPANEL_TOKEN no longer wipes it), dispatch put-120cash-cron.
# Does not send mail. Does not touch PayPal. Does not replace workers grok / grok-cf.
#
#   powershell -File RUN-SHIFT002.ps1

$ErrorActionPreference = 'Stop'
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'
$Stamp = Get-Date -Format 'yyyyMMddHHmmss'
$Url = "$Drop/install-hub-hook.ps1?t=$Stamp"
$Out = Join-Path $env:TEMP 'shift002-install-hub-hook.ps1'
Invoke-WebRequest -Uri $Url -OutFile $Out -UseBasicParsing
$pack = Get-Content -Raw -Path $Out
$i = $pack.LastIndexOf("Write-Host 'Done. HubWatch")
$chunk = if ($i -ge 0) { $pack.Substring($i, [Math]::Min(140, $pack.Length - $i)) } else { '' }
if ($pack.Length -lt 500 -or $pack -match 'PLACEHOLDER - DO NOT USE') {
  Write-Host 'WARN: install-hub-hook.ps1 looks truncated. Refusing to run.'
  exit 1
}
if (-not $chunk.Contains("stay flipped.'")) {
  Write-Host 'WARN: install-hub-hook.ps1 last Done line is unclosed. Refusing to run (PowerShell would parse-abort).'
  exit 1
}
& $Out

try {
  if (Get-Command gh -ErrorAction SilentlyContinue) {
    & gh workflow run put-120cash-cron.yml --repo 'agency002com-ship-it/agency002com-ship-it.github.io'
    Write-Host 'Triggered put-120cash-cron (no token printed)'
  }
} catch {
  Write-Host ("WARN put-120cash-cron: {0}" -f $_.Exception.Message)
}

$Cat = Join-Path $env:TEMP 'shift002-write-catalog-index.ps1'
try {
  Invoke-WebRequest -Uri "$Drop/write-catalog-index.ps1?t=$Stamp" -OutFile $Cat -UseBasicParsing
  & $Cat
} catch {
  Write-Host ("catalog index: {0}" -f $_.Exception.Message)
}
