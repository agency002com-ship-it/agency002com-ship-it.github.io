# Laptop Fileman for the same-night €120 door.
# Nav.js first (eidotevil / agency002 / sebarv / 120.cash): Pay cash_120 →
# cash.keychain.gr; unique wait-a-day copy → same night; briefs → tonight KV.
# Then unique nav.js src cache-bust. Then catalog index.html → tonight
# (agency002 may only have a unique 120.cash/ ghost link). Presence stays.
# Then 120.cash brief-submit.php (KV).
# Then 120.cash index.html from 120-index.html (#book desk — curl/Google see
# source, not JS). Then keychain.gr pay.html cash_120 after-pay.
# Other keychain plans stay. No mail. No PayPal passwords. No FormSubmit.
#
#   powershell -File upload-120cash.ps1

$ErrorActionPreference = 'Stop'
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'
$Pages = 'https://agency002com-ship-it.github.io'
$Paid = "$Pages/paid.html"

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
$Dir = $env:CPANEL_DIR
if (-not $Dir) { $Dir = $CpanelDir }
if (-not $Dir) { $Dir = "/home/$User/domains/120.cash/public_html" }
$WhmUserName = $env:WHM_USER
if (-not $WhmUserName) { $WhmUserName = $WhmUser }
$HostNames = @($HostName, '192.250.229.162', 'agency002.com', 'lemonpie.codes') |
  Where-Object { $_ } | Select-Object -Unique

if (-not $Token) {
  Write-Error @"
No cPanel token in this session.
Dot-source GrokWork\ftp\config.cpanel.local.ps1 (already on the laptop),
or set CPANEL_TOKEN. Do not invent a password. Do not use PayPal credentials.
"@
}

$here = $PSScriptRoot
if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }

function Invoke-DropScript([string]$name) {
  $local = Join-Path $here $name
  if (Test-Path $local) {
    & $local
    return
  }
  $tmp = Join-Path $env:TEMP "shift002-$name"
  $stamp = Get-Date -Format 'yyyyMMddHHmmss'
  Invoke-WebRequest -Uri "$Drop/${name}?t=$stamp" -OutFile $tmp -UseBasicParsing
  & $tmp
}

$localSave = Join-Path $here 'save-fileman.ps1'
if (Test-Path $localSave) {
  . $localSave
} else {
  $save = Join-Path $env:TEMP 'shift002-save-fileman.ps1'
  Invoke-WebRequest -Uri "$Drop/save-fileman.ps1" -OutFile $save -UseBasicParsing
  . $save
}

Write-Host 'Writing catalog /assets/nav.js (cash_120 only).'
try { Invoke-DropScript 'write-nav.ps1' } catch {
  Write-Host ("WARN nav.js: {0}" -f $_.Exception.Message)
}

Write-Host 'Pointing unique nav.js tags at github.io night nav.'
try { Invoke-DropScript 'write-nav-src.ps1' } catch {
  Write-Host ("WARN nav src: {0}" -f $_.Exception.Message)
}

Write-Host 'Patching catalog index.html (agency002 may only have a 120.cash/ ghost link).'
try { Invoke-DropScript 'write-catalog-index.ps1' } catch {
  Write-Host ("WARN catalog index: {0}" -f $_.Exception.Message)
}

Write-Host 'Writing 120.cash brief-submit.php (KV publish; this host only).'
try { Invoke-DropScript 'write-brief-submit.ps1' } catch {
  Write-Host ("WARN brief-submit.php: {0}" -f $_.Exception.Message)
}

$page120 = ''
try { $page120 = (Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing).Content } catch { }
$needDesk = ($page120 -match 'one working day') -or ($page120 -notmatch '#book')
if ($needDesk) {
  Write-Host 'Writing 120.cash index.html from 120-index.html (same-night #book desk).'
  $indexFile = Join-Path $here '120-index.html'
  if (-not (Test-Path $indexFile)) {
    $indexFile = Join-Path $env:TEMP 'shift002-120-index.html'
    Invoke-WebRequest -Uri "$Drop/120-index.html" -OutFile $indexFile -UseBasicParsing
  }
  $deskHtml = [System.IO.File]::ReadAllText($indexFile)
  if ($deskHtml -notmatch '#book' -or $deskHtml -match 'one working day' -or $deskHtml -notmatch 'ftp-drop/desk.js') {
    Write-Error '120-index.html is not the same-night desk. Refusing to overwrite origin index.html.'
  }
  foreach ($d in @($Dir, "/home/$User/public_html/120.cash", "/home/$User/domains/120.cash/public_html")) {
    try { Save-Fileman $d 'index.html' $deskHtml } catch {
      Write-Host ("skip {0}: {1}" -f $d, $_.Exception.Message)
    }
  }
  Start-Sleep -Seconds 2
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

Write-Host 'Patching live keychain.gr/pay.html (cash_120 return only).'
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
      foreach ($d in @("/home/$User/keychain.gr", "/home/$User/public_html/keychain.gr", "/home/$User/domains/keychain.gr/public_html")) {
        try { Save-Fileman $d 'pay.html' $html } catch {
          Write-Host ("skip {0}: {1}" -f $d, $_.Exception.Message)
          continue
        }
        Start-Sleep -Seconds 2
        $check = Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing
        if (Test-KeychainPatched $check.Content) { $keychainOk = $true; break }
      }
    }
  }
}

$finalPay = (Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing).Content
if (Test-KeychainPatched $finalPay) { $keychainOk = $true }
if ($finalPay -notmatch 'intifrog.com' -or $finalPay -notmatch 'sitepilot') {
  Write-Error 'Other keychain plans missing after write. Stop.'
}

$navLive = 0
foreach ($site in @('eidotevil.com', 'agency002.com', 'sebarv.com', '120.cash')) {
  try {
    $h = (Invoke-WebRequest -Uri ("https://{0}/" -f $site) -UseBasicParsing).Content
    $js = (Invoke-WebRequest -Uri ("https://{0}/assets/nav.js" -f $site) -UseBasicParsing).Content
    if ($h.Contains('ftp-drop/nav-night.js') -or $js.Contains('cash.keychain.gr')) {
      Write-Host ("OK {0} night nav live." -f $site)
      $navLive++
    } else {
      Write-Host ("WARN {0} nav.js still year-stamp." -f $site)
    }
  } catch {
    Write-Host ("WARN check {0}: {1}" -f $site, $_.Exception.Message)
  }
}

if ($keychainOk) { Write-Host 'keychain cash_120 now returns to the night desk. Other plans untouched.' }
if (-not $keychainOk) { Write-Host 'WARN: keychain still sends cash_120 to 120.cash/#brief. Catalog nav.js still flips Pay to cash.keychain.gr.' }

$stillCash = $false
try {
  $liveCash = (Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing).Content
  $stillCash = ($liveCash -match 'one working day') -or ($liveCash -notmatch '#book')
} catch { $stillCash = $true }

if (-not $keychainOk -or $navLive -lt 4 -or $stillCash) {
  Write-Host 'Still wait-a-day. Cloudflare orange-cloud (existing grok-cf routes).'
  try { Invoke-DropScript 'orange-120cash.ps1' } catch {
    Write-Host ("Cloudflare orange: {0}" -f $_.Exception.Message)
  }
}
Write-Host 'Done.'
