# One branch on live keychain.gr pay.html.
# Indexed 120.cash "Pay €120" already opens plan=cash_120. After pay, live
# keychain still sends buyers to 120.cash/#brief (working day). Point that
# next-step at github.io/paid.html so they are not charged twice.
# Addon-domain FTP returns 553. leftover :2083-only Save-Pay skipped WHM.
# Use Save-Fileman (WHM :2087 first), same as upload-120cash.ps1.
# Do not send mail. Do not touch PayPal. Do not edit other plans.
#
# Laptop:  powershell -File upload-keychain-cash120.ps1
# ping 20260908b: leftover :2083 553 must not abort keychain after-pay Fileman.

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
# Token helper defaults $Dir to 120.cash. This script writes keychain.gr only.
if ($env:KEYCHAIN_DIR) { $Dir = $env:KEYCHAIN_DIR } else { $Dir = "/home/$User/keychain.gr" }
if (-not $Token -and -not $NightDoorHasWhmHelper) {
  Write-Error @"
No cPanel token in this session.
Dot-source GrokWork\ftp\config.cpanel.local.ps1 or whm-api.ps1 (already on the laptop),
or set CPANEL_HOST, CPANEL_USER, CPANEL_TOKEN.
Do not invent a password. Do not use PayPal credentials.
"@
}
if (-not $HostName) {
  Write-Error 'No cPanel host. Set CPANEL_HOST. Do not invent a password.'
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

function Confirm-Live {
  $check = Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing
  return $check.Content
}

$dirs = @(
  $Dir,
  "/home/$User/public_html/keychain.gr",
  "/home/$User/domains/keychain.gr/public_html",
  "/home/$User/public_html"
) | Where-Object { $_ } | Select-Object -Unique

$after = $html
foreach ($d in $dirs) {
  Write-Host "Writing $d/pay.html via Save-Fileman (WHM first)."
  try {
    Save-Fileman $d 'pay.html' $patched
  } catch {
    Write-Host ("skip {0}: {1}" -f $d, $_.Exception.Message)
    continue
  }
  Start-Sleep -Seconds 2
  $after = Confirm-Live
  if ($after -match 'agency002com-ship-it\.github\.io/paid\.html') { break }
}

if ($after -notmatch 'agency002com-ship-it\.github\.io/paid\.html') {
  Write-Error 'https://keychain.gr/pay.html still sends cash_120 to 120.cash/#brief. Stop. Do not guess another site.'
}
if ($after -notmatch 'buymy\.works/setup') {
  Write-Error 'buy_link next-step missing after upload. Stop.'
}

Write-Host 'keychain.gr cash_120 now opens github.io/paid.html. Other plans left alone.'
