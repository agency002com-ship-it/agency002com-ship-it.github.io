# Tiny Fileman: overwrite 120.cash/brief-submit.php only.
# Mails unpaid briefs. KV publish only when Stripe/PayPal id is on the POST.
# Do not write eidotevil / agency002 / sebarv brief-submit.php.
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
  Write-Host 'No cPanel token. Skip 120.cash brief-submit.php Fileman.'
  exit 0
}
$localSave = Join-Path $here 'save-fileman.ps1'
if (Test-Path $localSave) {
  . $localSave
} else {
  $save = Join-Path $env:TEMP 'shift002-save-fileman.ps1'
  Invoke-WebRequest -Uri "$Drop/save-fileman.ps1" -OutFile $save -UseBasicParsing
  . $save
}

$phpTmp = Join-Path $env:TEMP 'brief-submit.php'
$localPhp = Join-Path $here 'brief-submit.php'
if (Test-Path $localPhp) {
  Copy-Item $localPhp $phpTmp -Force
} else {
  Invoke-WebRequest -Uri "$Drop/brief-submit.php" -OutFile $phpTmp -UseBasicParsing
}
$php = [System.IO.File]::ReadAllText($phpTmp)
if ($php.Length -lt 400 -or $php -notmatch 'cash\.120\.cash/api/publish') {
  Write-Error 'brief-submit.php is not the KV publisher. Skip origin overwrite.'
  exit 1
}
if ($php -notmatch 'tonight\.agency002\.com/#book' -or $php -notmatch 'cs_\(live\|test\)_') {
  Write-Error 'brief-submit.php would publish unpaid. Skip origin overwrite.'
  exit 1
}

foreach ($d in @($Dir, "/home/$User/public_html/120.cash", "/home/$User/domains/120.cash/public_html")) {
  try {
    Save-Fileman $d 'brief-submit.php' $php
    Write-Host "Wrote $d/brief-submit.php"
  } catch {
    Write-Host ("skip brief-submit {0}: {1}" -f $d, $_.Exception.Message)
  }
}
