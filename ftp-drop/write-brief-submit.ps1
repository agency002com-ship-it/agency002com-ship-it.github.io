# Tiny Fileman: overwrite 120.cash/brief-submit.php only.
# Grey 120.cash + orange tonight (grok-cf → origin) POST KV without waiting on Gmail.
# Do not write eidotevil / agency002 / sebarv brief-submit.php.
$ErrorActionPreference = 'Stop'
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'

$ftpDir = Join-Path $env:USERPROFILE 'GrokWork\ftp'
foreach ($name in @('config.cpanel.local.ps1', 'config.local.ps1', 'whm-api.ps1')) {
  $p = Join-Path $ftpDir $name
  if (Test-Path $p) { . $p }
}

$HostName = $env:CPANEL_HOST
if (-not $HostName) { $HostName = $CpanelHost }
if (-not $HostName) { $HostName = $WhmHost }
if (-not $HostName) { $HostName = 'agency002.com' }
$User = $env:CPANEL_USER
if (-not $User) { $User = $CpanelUser }
if (-not $User) { $User = 'agency00' }
$Token = $env:CPANEL_TOKEN
if (-not $Token) { $Token = $CpanelToken }
if (-not $Token) { $Token = $WhmToken }
$Dir = $env:CPANEL_DIR
if (-not $Dir) { $Dir = $CpanelDir }
if (-not $Dir) { $Dir = "/home/$User/120.cash" }
$WhmUserName = $env:WHM_USER
if (-not $WhmUserName) { $WhmUserName = $WhmUser }
$HostNames = @($HostName, 'agency002.com', 'lemonpie.codes') |
  Where-Object { $_ } | Select-Object -Unique

if (-not $Token) {
  Write-Host 'No cPanel token. Skip 120.cash brief-submit.php Fileman.'
  exit 0
}

$here = $PSScriptRoot
if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
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

foreach ($d in @($Dir, "/home/$User/public_html/120.cash")) {
  try {
    Save-Fileman $d 'brief-submit.php' $php
    Write-Host "Wrote $d/brief-submit.php"
  } catch {
    Write-Host ("skip brief-submit {0}: {1}" -f $d, $_.Exception.Message)
  }
}
