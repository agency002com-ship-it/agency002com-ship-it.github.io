# One branch on live keychain.gr pay.html.
# Indexed 120.cash "Pay €120" already opens plan=cash_120. After pay, live
# keychain still sends buyers to 120.cash/#brief (working day). Point that
# next-step at github.io/paid.html so they are not charged twice.
# Addon-domain FTP returns 553. Use cPanel Fileman, same as upload-120cash.ps1.
# Do not send mail. Do not touch PayPal. Do not edit other plans.
#
# Laptop:  powershell -File upload-keychain-cash120.ps1

$ErrorActionPreference = 'Stop'

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
$Dir = $env:KEYCHAIN_DIR
 if (-not $Dir) { $Dir = "/home/$User/keychain.gr" }

if (-not $Token -or -not $HostName) {
  Write-Error @"
No cPanel token in this session.
Dot-source GrokWork\ftp\config.cpanel.local.ps1 (already on the laptop),
or set CPANEL_HOST, CPANEL_USER, CPANEL_TOKEN.
Do not invent a password. Do not use PayPal credentials.
"@
}

$live = Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing
$html = $live.Content
if ($html -match 'agency002com-ship-it\.github\.io/paid\.html') {
  Write-Host 'keychain.gr pay.html already sends cash_120 to paid.html. Stop.'
  exit 0
}

$old = @"
      } else if (kind === 'cash_120') {
        t('Next step: open ');
        a('https://120.cash/#brief', '120.cash');
        t(' and send the brief (“I paid — send brief”). We build after that.');
      }
"@

$new = @"
      } else if (kind === 'cash_120') {
        t('Next step: open ');
        var sid = (new URLSearchParams(location.search)).get('session_id') || '';
        var paid = 'https://agency002com-ship-it.github.io/paid.html';
        if (sid) paid += '?session_id=' + encodeURIComponent(sid);
        a(paid, 'the night desk');
        t(' and leave the brief. The page goes live the same night. Do not pay again.');
      }
"@

if ($html.IndexOf($old) -lt 0) {
  Write-Error 'cash_120 next-step block not found as expected. Stop. Do not rewrite pay.html.'
}

$patched = $html.Replace($old, $new)
if ($patched -eq $html) {
  Write-Error 'Replace did nothing. Stop.'
}
if ($patched -notmatch 'agency002com-ship-it\.github\.io/paid\.html') {
  Write-Error 'Patch missing paid.html. Stop.'
}
if ($patched -notmatch 'buymy\.works/setup' -or $patched -notmatch 'sitepilot') {
  Write-Error 'Other plans would be damaged. Stop. Do not upload.'
}

function Save-Pay([string]$directory) {
  $pair = '{0}:{1}' -f $User, $Token
  $auth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
  $uri = ('https://{0}:2083/execute/Fileman/save_file_content' -f $HostName)
  $body = @{
    dir     = $directory
    file    = 'pay.html'
    content = $patched
    charset = 'utf-8'
  }
  Write-Host "Writing $directory/pay.html via Fileman"
  Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = $auth } -Body $body -SkipCertificateCheck
}

Save-Pay $Dir

function Confirm-Live {
  $check = Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing
  return $check.Content
}

$after = Confirm-Live
$fallbacks = @(
  "/home/$User/public_html/keychain.gr",
  "/home/$User/public_html"
)
$i = 0
while ($after -notmatch 'agency002com-ship-it\.github\.io/paid\.html' -and $i -lt $fallbacks.Length) {
  Write-Host "Live pay.html not patched yet. Trying $($fallbacks[$i])."
  Save-Pay $fallbacks[$i]
  $after = Confirm-Live
  $i++
}

if ($after -notmatch 'agency002com-ship-it\.github\.io/paid\.html') {
  Write-Error 'https://keychain.gr/pay.html still sends cash_120 to 120.cash/#brief. Stop. Do not guess another site.'
}
if ($after -notmatch 'buymy\.works/setup') {
  Write-Error 'buy_link next-step missing after upload. Stop.'
}

Write-Host 'keychain.gr cash_120 now opens github.io/paid.html. Other plans left alone.'
