# Put the same-night 120.cash homepage on the live docroot.
# Addon-domain FTP on this account returns 553. Use cPanel Fileman instead.
# Does not send mail. Does not touch PayPal passwords. Does not restore FormSubmit.
#
# Laptop:  powershell -File upload-120cash.ps1
# Needs one of:
#   GrokWork\ftp\config.cpanel.local.ps1  (existing WHM/cPanel token)
#   env CPANEL_HOST, CPANEL_USER, CPANEL_TOKEN, optional CPANEL_DIR
#
# After: https://120.cash/ must say brief then pay, not one working day.

$ErrorActionPreference = 'Stop'
$Source = 'https://agency002com-ship-it.github.io/ftp-drop/120-index.html'
$Tmp = Join-Path $env:TEMP '120-index.html'

$ftpDir = Join-Path $env:USERPROFILE 'GrokWork\ftp'
foreach ($name in @('config.cpanel.local.ps1', 'config.local.ps1', 'whm-api.ps1')) {
  $p = Join-Path $ftpDir $name
  if (Test-Path $p) { . $p }
}

$HostName = $env:CPANEL_HOST
if (-not $HostName) { $HostName = $CpanelHost }
if (-not $HostName) { $HostName = $WhmHost }
$User = $env:CPANEL_USER
if (-not $User) { $User = $CpanelUser }
if (-not $User) { $User = 'agency00' }
$Token = $env:CPANEL_TOKEN
if (-not $Token) { $Token = $CpanelToken }
if (-not $Token) { $Token = $WhmToken }
$Dir = $env:CPANEL_DIR
if (-not $Dir) { $Dir = $CpanelDir }
if (-not $Dir) { $Dir = "/home/$User/120.cash" }

if (-not $Token -or -not $HostName) {
  Write-Error @"
No cPanel token in this session.
Dot-source GrokWork\ftp\config.cpanel.local.ps1 (already on the laptop),
or set CPANEL_HOST, CPANEL_USER, CPANEL_TOKEN.
Do not invent a password. Do not use PayPal credentials.
"@
}

Write-Host "Downloading $Source"
Invoke-WebRequest -Uri $Source -OutFile $Tmp -UseBasicParsing
$html = [System.IO.File]::ReadAllText($Tmp)

function Save-Index([string]$directory) {
  $pair = '{0}:{1}' -f $User, $Token
  $auth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
  $uri = ('https://{0}:2083/execute/Fileman/save_file_content' -f $HostName)
  $body = @{
    dir     = $directory
    file    = 'index.html'
    content = $html
    charset = 'utf-8'
  }
  Write-Host "Writing $directory/index.html via Fileman"
  Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = $auth } -Body $body -SkipCertificateCheck
}

Save-Index $Dir

$live = Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing
if ($live.Content -match 'one working day') {
  Write-Host 'Still says working day. Trying public_html addon path.'
  Save-Index "/home/$User/public_html/120.cash"
  $live = Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing
}

if ($live.Content -match 'one working day') {
  Write-Error 'https://120.cash/ still says one working day. Stop. Do not guess another site.'
}
if ($live.Content -notmatch '#book') {
  Write-Error 'https://120.cash/ did not get the brief-then-pay form. Stop.'
}

Write-Host 'https://120.cash/ is brief then pay. Keep /assets/. Leave brief-submit.php.'
