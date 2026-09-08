# Tiny Fileman: IndexNow key on indexed catalogs + keychain.gr.
# Does not rewrite index.html / nav.js / pay.html. Does not send mail.
# Does not Fileman wait-a-day 120.cash. Does not ping IndexNow.
# leftover empty $env:CPANEL_TOKEN must not wipe a sourced WHM $Token.
# leftover silent save-fileman.ps1 must wget helper-proof a460b294.
# ping 20260908d: leftover IndexNow key Fileman must reach WHM :2087.
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
  Write-Host 'No cPanel token. Skip IndexNow key Fileman.'
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

$key = '7c2a9f1e4b8d0c3a5e6f7a8b9c0d1e2f'
$localKey = Join-Path $here 'origin-indexnow.txt'
if (Test-Path $localKey) {
  $body = ([System.IO.File]::ReadAllText($localKey)).Trim()
  if ($body -ne $key) {
    Write-Host 'origin-indexnow.txt is not the night key. Skip.'
    exit 0
  }
}
$roots = @(
  "/home/$User/eidotevil.com",
  "/home/$User/public_html/eidotevil.com",
  "/home/$User/domains/eidotevil.com/public_html",
  "/home/$User/public_html",
  "/home/$User/agency002.com",
  "/home/$User/public_html/agency002.com",
  "/home/$User/sebarv.com",
  "/home/$User/public_html/sebarv.com",
  "/home/$User/domains/sebarv.com/public_html",
  "/home/$User/keychain.gr",
  "/home/$User/public_html/keychain.gr",
  "/home/$User/domains/keychain.gr/public_html"
)
foreach ($d in $roots) {
  try {
    Save-Fileman $d ($key + '.txt') $key
    Write-Host ("Wrote {0}/{1}.txt" -f $d, $key)
  } catch {
    Write-Host ("skip IndexNow {0}: {1}" -f $d, $_.Exception.Message)
  }
}
