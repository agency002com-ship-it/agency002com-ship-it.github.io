# Tiny Fileman: overwrite grey /assets/nav.js on 120.cash and indexed catalogs.
# ping 20260907t: also Fileman addon docroot /home/agency00/domains/120.cash/public_html.
# Pay €120 → cash.keychain.gr. cash_120 brief → tonight KV.
# Does not rewrite other keychain plans. Does not send mail.
$ErrorActionPreference = 'Stop'
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'

$here = $PSScriptRoot
if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
$tokHelper = Join-Path $here 'night-door-token.ps1'
if (-not (Test-Path $tokHelper)) {
  $tokHelper = Join-Path $env:TEMP 'shift002-night-door-token.ps1'
  Invoke-WebRequest -Uri "$Drop/night-door-token.ps1" -OutFile $tokHelper -UseBasicParsing
}
. $tokHelper
if (-not $Token -and -not $NightDoorHasWhmHelper) {
  Write-Host 'No cPanel token. Skip nav.js Fileman.'
  exit 0
}
$localSave = Join-Path $here 'save-fileman.ps1'
$saveText = ''
if (Test-Path $localSave) { $saveText = Get-Content -Raw -Path $localSave }
if ($saveText -notmatch 'ran but status not 1') {
  Write-Host 'save-fileman.ps1 missing helper-proof. Fetching WHM-first pack a460b294.'
  $save = Join-Path $env:TEMP 'shift002-save-fileman.ps1'
  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/a460b294250a5530aa76f97a09c5e1714fd9540c/ftp-drop/save-fileman.ps1' -OutFile $save -UseBasicParsing
  . $save
} else {
  . $localSave
}

$navTmp = Join-Path $env:TEMP 'nav-night.js'
$localNav = Join-Path $here 'nav-night.js'
if (Test-Path $localNav) {
  Copy-Item $localNav $navTmp -Force
} else {
  # Raw git, not Pages: github.io has served a 13-byte PLACEHOLDER for this path.
  Invoke-WebRequest -Uri "$Drop/nav-night.js" -OutFile $navTmp -UseBasicParsing
}
$navJs = [System.IO.File]::ReadAllText($navTmp)
if ($navJs.Length -lt 500 -or $navJs -notmatch 'cash\.keychain\.gr') {
  Write-Error 'nav-night.js missing cash.keychain.gr (would overwrite catalogs with the 120-byte year stamp). Skip.'
  exit 1
}

$assetDirs = @(
  "$Dir/assets",
  "/home/$User/public_html/120.cash/assets",
  "/home/$User/domains/120.cash/public_html/assets",
  "/home/$User/eidotevil.com/assets",
  "/home/$User/public_html/eidotevil.com/assets",
  "/home/$User/domains/eidotevil.com/public_html/assets",
  "/home/$User/public_html/assets",
  "/home/$User/agency002.com/assets",
  "/home/$User/public_html/agency002.com/assets",
  "/home/$User/sebarv.com/assets",
  "/home/$User/public_html/sebarv.com/assets",
  "/home/$User/domains/sebarv.com/public_html/assets"
)
foreach ($d in $assetDirs) {
  try {
    Save-Fileman $d 'nav.js' $navJs
    Write-Host "Wrote $d/nav.js"
  } catch {
    Write-Host ("skip nav.js {0}: {1}" -f $d, $_.Exception.Message)
  }
}
