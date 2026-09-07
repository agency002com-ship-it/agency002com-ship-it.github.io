# Tiny Fileman: overwrite grey /assets/nav.js on 120.cash and indexed catalogs.
# Pay €120 → cash.keychain.gr. cash_120 brief → tonight KV.
# Does not rewrite other keychain plans. Does not send mail.
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
  Write-Host 'No cPanel token. Skip nav.js Fileman.'
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

$navTmp = Join-Path $env:TEMP 'nav-night.js'
$localNav = Join-Path $here 'nav-night.js'
if (Test-Path $localNav) {
  Copy-Item $localNav $navTmp -Force
} else {
  # Raw git, not Pages: github.io has served a 13-byte PLACEHOLDER for this path.
  Invoke-WebRequest -Uri "$Drop/nav-night.js" -OutFile $navTmp -UseBasicParsing
}
$navJs = [System.IO.File]::ReadAllText($navTmp)

$assetDirs = @(
  "$Dir/assets",
  "/home/$User/public_html/120.cash/assets",
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
