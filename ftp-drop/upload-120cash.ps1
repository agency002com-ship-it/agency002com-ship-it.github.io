# Put the same-night door on the live cPanel account.
# Addon-domain FTP returns 553. Use Fileman. Same token as GrokWork\ftp\.
# Does not send mail. Does not touch PayPal passwords. Does not restore FormSubmit.
# Does not rewrite other keychain plans (SitePilot, Intifrog, Ms King, MPG, …).
#
# Laptop:  powershell -File upload-120cash.ps1
# Needs one of:
#   GrokWork\ftp\config.cpanel.local.ps1
#   env CPANEL_HOST, CPANEL_USER, CPANEL_TOKEN
#
# After:
#   https://keychain.gr/pay.html  cash_120 return → github.io/paid.html
#   https://120.cash/             brief then pay, not one working day
#
# Keychain is first: the indexed 120.cash CTA already opens cash_120. Flipping
# that return delivers tonight even if the 120.cash homepage write misses.

$ErrorActionPreference = 'Stop'
$Pages = 'https://agency002com-ship-it.github.io'
$Paid = "$Pages/paid.html"
$IndexSource = "$Pages/ftp-drop/120-index.html"

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

if (-not $Token) {
  Write-Error @"
No cPanel token in this session.
Dot-source GrokWork\ftp\config.cpanel.local.ps1 (already on the laptop),
or set CPANEL_TOKEN. Do not invent a password. Do not use PayPal credentials.
"@
}

$pair = '{0}:{1}' -f $User, $Token
$auth = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))

function Save-Fileman([string]$directory, [string]$file, [string]$content) {
  $uri = ('https://{0}:2083/execute/Fileman/save_file_content' -f $HostName)
  $body = @{
    dir     = $directory
    file    = $file
    content = $content
    charset = 'utf-8'
  }
  Write-Host "Writing $directory/$file via Fileman"
  Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = $auth } -Body $body -SkipCertificateCheck
}

function Test-KeychainPatched([string]$content) {
  return ($content -match [regex]::Escape($Paid) -and $content -notmatch [regex]::Escape("a('https://120.cash/#brief', '120.cash');"))
}

$oldLink = "a('https://120.cash/#brief', '120.cash');"
$newLink = @"
        var sid = (new URLSearchParams(location.search)).get('session_id') || '';
        var tok = (new URLSearchParams(location.search)).get('token') || (new URLSearchParams(location.search)).get('order_id') || '';
        var paid = '$Paid';
        if (sid) paid += '?session_id=' + encodeURIComponent(sid);
        else if (tok) paid += '?token=' + encodeURIComponent(tok);
        a(paid, 'the night desk');
"@

$oldBounce = @"
        return false;
      }
      return false;
    }

    /* ---------------- return from PayPal / Stripe ---------------- */
"@
$newBounce = @"
        return false;
      }
      if (kind === 'cash_120') {
        var paid = '$Paid';
        if (sid && /^cs_(live|test)_/.test(sid)) {
          location.href = paid + '?session_id=' + encodeURIComponent(sid);
          return true;
        }
        if (token) {
          location.href = paid + '?token=' + encodeURIComponent(token);
          return true;
        }
        return false;
      }
      return false;
    }

    /* ---------------- return from PayPal / Stripe ---------------- */
"@

$oldDone = @"
      showProductNextStep(); // product-aware next step as soon as thank-you shows
      var oid = q.get('token') || q.get('order_id') || sessionStorage.getItem('a2_pp_order') || '';
"@
$newDone = @"
      showProductNextStep(); // product-aware next step as soon as thank-you shows
      if (productKind() === 'cash_120') {
        var sidNow = q.get('session_id') || q.get('checkout_session_id') || '';
        var tokNow = q.get('token') || q.get('order_id') || sessionStorage.getItem('a2_pp_order') || '';
        if (doorBounce(sidNow, tokNow)) return;
      }
      var oid = q.get('token') || q.get('order_id') || sessionStorage.getItem('a2_pp_order') || '';
"@

# --- 1. keychain.gr/pay.html : cash_120 only (indexed money door already uses this) ---
Write-Host 'Patching live keychain.gr/pay.html (cash_120 return + bounce).'
$pay = Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing
$html = $pay.Content
$keychainOk = $false

if ($html -notmatch "kind === 'cash_120'") {
  Write-Host 'WARN: live pay.html has no cash_120 branch. Skipping till rewrite.'
} elseif (Test-KeychainPatched $html) {
  Write-Host 'pay.html already points cash_120 at paid.html.'
  $keychainOk = $true
} else {
  $nLink = ([regex]::Matches($html, [regex]::Escape($oldLink))).Count
  $nBounce = ([regex]::Matches($html, [regex]::Escape($oldBounce))).Count
  $nDone = ([regex]::Matches($html, [regex]::Escape($oldDone))).Count
  if ($nLink -ne 1 -or $nBounce -ne 1 -or $nDone -ne 1) {
    Write-Host ("WARN: pay.html needles not unique (link=$nLink bounce=$nBounce done=$nDone). Skipping till rewrite.")
  } else {
    $html = $html.Replace($oldLink, $newLink).Replace($oldBounce, $newBounce).Replace($oldDone, $newDone)
    if ($html -notmatch 'intifrog.com' -or $html -notmatch 'msking.shop' -or $html -notmatch 'muslimpowergroup.com') {
      Write-Host 'WARN: patch would drop another plan. Did not write pay.html.'
    } else {
      $payDirs = @(
        "/home/$User/keychain.gr",
        "/home/$User/public_html/keychain.gr",
        "/home/$User/domains/keychain.gr/public_html"
      )
      foreach ($d in $payDirs) {
        try {
          Save-Fileman $d 'pay.html' $html
        } catch {
          Write-Host ("skip {0}: {1}" -f $d, $_.Exception.Message)
          continue
        }
        Start-Sleep -Seconds 2
        $check = Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing
        if (Test-KeychainPatched $check.Content) {
          $keychainOk = $true
          break
        }
      }
    }
  }
}

# --- 2. 120.cash homepage ---
$cashOk = $false
$Tmp = Join-Path $env:TEMP '120-index.html'
Write-Host "Downloading $IndexSource"
Invoke-WebRequest -Uri $IndexSource -OutFile $Tmp -UseBasicParsing
$indexHtml = [System.IO.File]::ReadAllText($Tmp)
try {
  Save-Fileman $Dir 'index.html' $indexHtml
} catch {
  Write-Host ("WARN 120.cash primary dir: {0}" -f $_.Exception.Message)
}

$live = Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing
if ($live.Content -match 'one working day' -or $live.Content -notmatch '#book') {
  Write-Host 'Trying public_html addon path for 120.cash.'
  try {
    Save-Fileman "/home/$User/public_html/120.cash" 'index.html' $indexHtml
  } catch {
    Write-Host ("WARN 120.cash addon dir: {0}" -f $_.Exception.Message)
  }
  $live = Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing
}
if ($live.Content -notmatch 'one working day' -and $live.Content -match '#book') {
  $cashOk = $true
  Write-Host 'https://120.cash/ is brief then pay. Keep /assets/. Leave brief-submit.php.'
} else {
  Write-Host 'WARN: https://120.cash/ still says one working day. Keychain bounce can still deliver tonight.'
}

$finalPay = (Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing).Content
if (Test-KeychainPatched $finalPay) { $keychainOk = $true }
if ($finalPay -notmatch 'intifrog.com' -or $finalPay -notmatch 'sitepilot') {
  Write-Error 'Other keychain plans missing after write. Stop.'
}

if (-not $keychainOk -and -not $cashOk) {
  Write-Error 'Neither keychain cash_120 nor 120.cash homepage flipped. Stop.'
}
if ($keychainOk) { Write-Host 'keychain cash_120 now returns to the night desk. Other plans untouched.' }
if (-not $keychainOk) { Write-Host 'WARN: keychain still sends cash_120 to 120.cash/#brief.' }
Write-Host 'Done.'
