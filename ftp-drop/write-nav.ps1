# Tiny Fileman: overwrite grey 120.cash /assets/nav.js.
# Pay €120 → cash.keychain.gr. #brief → cash.120.cash KV.
# Does not rewrite other keychain plans. Does not send mail.
$ErrorActionPreference = 'Stop'
$Pages = 'https://agency002com-ship-it.github.io'
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
Invoke-WebRequest -Uri "$Pages/ftp-drop/nav-night.js" -OutFile $navTmp -UseBasicParsing
$navJs = [System.IO.File]::ReadAllText($navTmp)
foreach ($d in @("$Dir/assets", "/home/$User/public_html/120.cash/assets")) {
  try {
    Save-Fileman $d 'nav.js' $navJs
    Write-Host "Wrote $d/nav.js"
  } catch {
    Write-Host ("skip nav.js {0}: {1}" -f $d, $_.Exception.Message)
  }
}
