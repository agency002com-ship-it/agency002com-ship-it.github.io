# Tiny Fileman: IndexNow key on indexed catalogs + keychain.gr.
# Does not rewrite index.html / nav.js / pay.html. Does not send mail.
# Lets Google recrawl the unique eidotevil cash_120 door after this file exists.
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
if (-not $HostName) { $HostName = '192.250.229.162' }
$User = $env:CPANEL_USER
if (-not $User) { $User = $CpanelUser }
if (-not $User) { $User = 'agency00' }
$Token = $env:CPANEL_TOKEN
if (-not $Token) { $Token = $CpanelToken }
if (-not $Token) { $Token = $WhmToken }
$WhmUserName = $env:WHM_USER
if (-not $WhmUserName) { $WhmUserName = $WhmUser }
$HostNames = @($HostName, '192.250.229.162', 'agency002.com', 'lemonpie.codes') |
  Where-Object { $_ } | Select-Object -Unique

if (-not $Token) {
  Write-Host 'No cPanel token. Skip IndexNow key Fileman.'
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
