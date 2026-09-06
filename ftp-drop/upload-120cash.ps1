# Put the same-night door on the live cPanel account.
# pages 2026-09-07: Fileman also patches sebarv.com cash_120 → tonight.agency002.com.
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
#   https://eidotevil.com/        cash_120 card → tonight.agency002.com/#book
#   https://agency002.com/        cash_120 card → tonight.agency002.com/#book
#   https://sebarv.com/           cash_120 cards → tonight.agency002.com/#book
#
# Keychain is first: the indexed 120.cash CTA already opens cash_120. Flipping
# that return delivers tonight even if the 120.cash homepage write misses.
# eidotevil.com is Google-indexed; only the €120 card is rewritten.
# Agency002.com homepage is grey so Fileman rewrites only the cash_120 links.
# Presence / Printful / DBYW stay.

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

$WhmUserName = $env:WHM_USER
if (-not $WhmUserName) { $WhmUserName = $WhmUser }
$HostNames = @($HostName, 'agency002.com', 'lemonpie.codes') |
  Where-Object { $_ } | Select-Object -Unique
$here = $PSScriptRoot
if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
$localSave = Join-Path $here 'save-fileman.ps1'
if (Test-Path $localSave) {
  . $localSave
} else {
  $save = Join-Path $env:TEMP 'shift002-save-fileman.ps1'
  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop/save-fileman.ps1' -OutFile $save -UseBasicParsing
  . $save
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

# --- 3. eidotevil.com homepage: only the €120 card (Google already indexes this catalog) ---
Write-Host 'Patching eidotevil.com cash_120 links to tonight.agency002.com (other prices stay).'
$eidoOk = $false
try {
  $eidoHtml = (Invoke-WebRequest -Uri 'https://eidotevil.com/' -UseBasicParsing).Content
  $oldPay = 'href="https://keychain.gr/pay.html?plan=cash_120"'
  $newPay = 'href="https://tonight.agency002.com/#book"'
  $oldBrief = 'href="https://120.cash/#brief"'
  $newBrief = 'href="https://tonight.agency002.com/"'
  $oldHome = 'href="https://120.cash/"'
  $newHome = 'href="https://tonight.agency002.com/"'
  $oldLine = 'After pay: short brief on 120.cash'
  $newLine = 'After pay: same-night brief on tonight.agency002.com'
  $nPay = ([regex]::Matches($eidoHtml, [regex]::Escape($oldPay))).Count
  $nBrief = ([regex]::Matches($eidoHtml, [regex]::Escape($oldBrief))).Count
  $nHome = ([regex]::Matches($eidoHtml, [regex]::Escape($oldHome))).Count
  if ($eidoHtml -match [regex]::Escape('tonight.agency002.com/#book')) {
    Write-Host 'eidotevil.com already points cash_120 at tonight.agency002.com.'
    $eidoOk = $true
  } elseif ($nPay -ne 1 -or $nBrief -ne 1 -or $nHome -ne 1) {
    Write-Host ("WARN: eidotevil.com needles not unique (pay=$nPay brief=$nBrief home=$nHome). Skipping catalog rewrite.")
  } else {
    $patchedEido = $eidoHtml.Replace($oldPay, $newPay).Replace($oldBrief, $newBrief).Replace($oldHome, $newHome).Replace($oldLine, $newLine)
    if ($patchedEido -notmatch 'pay.html\?plan=presence' -or $patchedEido -notmatch 'page_100' -or $patchedEido -notmatch 'printful') {
      Write-Host 'WARN: eidotevil.com patch would drop another product. Did not write.'
    } else {
      $eidoDirs = @(
        "/home/$User/eidotevil.com",
        "/home/$User/public_html/eidotevil.com",
        "/home/$User/domains/eidotevil.com/public_html"
      )
      foreach ($d in $eidoDirs) {
        try {
          Save-Fileman $d 'index.html' $patchedEido
        } catch {
          Write-Host ("skip {0}: {1}" -f $d, $_.Exception.Message)
          continue
        }
        Start-Sleep -Seconds 2
        $checkE = (Invoke-WebRequest -Uri 'https://eidotevil.com/' -UseBasicParsing).Content
        if ($checkE -match [regex]::Escape('tonight.agency002.com/#book') -and $checkE -match 'pay.html\?plan=presence') {
          $eidoOk = $true
          Write-Host 'eidotevil.com cash_120 now opens tonight.agency002.com. Other prices untouched.'
          break
        }
      }
    }
  }
} catch {
  Write-Host ("WARN eidotevil.com: {0}" -f $_.Exception.Message)
}
if (-not $eidoOk) { Write-Host 'WARN: eidotevil.com still sends €120 to wait-a-day 120.cash. tonight.agency002.com is already live.' }

# --- 4. agency002.com homepage: only the €120 card (grey apex; orange wildcard already serves tonight.agency002.com) ---
Write-Host 'Patching agency002.com cash_120 links to tonight.agency002.com (other plans stay).'
$agencyOk = $false
try {
  $agencyHtml = (Invoke-WebRequest -Uri 'https://agency002.com/' -UseBasicParsing).Content
  $oldPay = 'href="https://keychain.gr/pay.html?plan=cash_120"'
  $newPay = 'href="https://tonight.agency002.com/#book"'
  $oldBrief = 'href="https://120.cash/#brief"'
  $newBrief = 'href="https://tonight.agency002.com/"'
  $oldHome = 'href="https://120.cash/"'
  $newHome = 'href="https://tonight.agency002.com/"'
  $nPay = ([regex]::Matches($agencyHtml, [regex]::Escape($oldPay))).Count
  $nBrief = ([regex]::Matches($agencyHtml, [regex]::Escape($oldBrief))).Count
  $nHome = ([regex]::Matches($agencyHtml, [regex]::Escape($oldHome))).Count
  if ($agencyHtml -match [regex]::Escape('tonight.agency002.com/#book') -or $agencyHtml -match [regex]::Escape('cash.agency002.com/#book') -or $agencyHtml -match [regex]::Escape('now.agency002.com/#book')) {
    Write-Host 'agency002.com already points cash_120 at an orange night till.'
    $agencyOk = $true
  } elseif ($nPay -ne 1 -or $nBrief -ne 1 -or $nHome -ne 1) {
    Write-Host ("WARN: agency002.com needles not unique (pay=$nPay brief=$nBrief home=$nHome). Skipping brand rewrite.")
  } else {
    $patchedAgency = $agencyHtml.Replace($oldPay, $newPay).Replace($oldBrief, $newBrief).Replace($oldHome, $newHome)
    if ($patchedAgency -notmatch 'pay.html\?plan=presence' -or $patchedAgency -notmatch 'eidotevil.com' -or $patchedAgency -notmatch 'printful') {
      Write-Host 'WARN: agency002.com patch would drop another product. Did not write.'
    } else {
      $agencyDirs = @(
        "/home/$User/public_html",
        "/home/$User/agency002.com",
        "/home/$User/public_html/agency002.com"
      )
      foreach ($d in $agencyDirs) {
        try {
          Save-Fileman $d 'index.html' $patchedAgency
        } catch {
          Write-Host ("skip {0}: {1}" -f $d, $_.Exception.Message)
          continue
        }
        Start-Sleep -Seconds 2
        $checkA = (Invoke-WebRequest -Uri 'https://agency002.com/' -UseBasicParsing).Content
        if ($checkA -match [regex]::Escape('tonight.agency002.com/#book') -and $checkA -match 'pay.html\?plan=presence') {
          $agencyOk = $true
          Write-Host 'agency002.com cash_120 now opens tonight.agency002.com. Presence/Printful/DBYW untouched.'
          break
        }
      }
    }
  }
} catch {
  Write-Host ("WARN agency002.com: {0}" -f $_.Exception.Message)
}
if (-not $agencyOk) { Write-Host 'WARN: agency002.com still sends €120 to wait-a-day 120.cash. tonight.agency002.com is already live.' }

# --- 5. sebarv.com homepage: only cash_120 cards (SitePilot / presence / Printful stay) ---
Write-Host 'Patching sebarv.com cash_120 links to tonight.agency002.com (other prices stay).'
$sebOk = $false
try {
  $sebHtml = (Invoke-WebRequest -Uri 'https://sebarv.com/' -UseBasicParsing).Content
  $oldPay = 'href="https://keychain.gr/pay.html?plan=cash_120"'
  $newPay = 'href="https://tonight.agency002.com/#book"'
  $oldHome = 'href="https://120.cash/"'
  $newHome = 'href="https://tonight.agency002.com/"'
  $nPay = ([regex]::Matches($sebHtml, [regex]::Escape($oldPay))).Count
  $nHome = ([regex]::Matches($sebHtml, [regex]::Escape($oldHome))).Count
  if ($sebHtml -match [regex]::Escape('tonight.agency002.com/#book')) {
    Write-Host 'sebarv.com already points cash_120 at tonight.agency002.com.'
    $sebOk = $true
  } elseif ($nPay -lt 1 -or $nHome -ne 1) {
    Write-Host ("WARN: sebarv.com needles not unique (pay=$nPay home=$nHome). Skipping catalog rewrite.")
  } else {
    $patchedSeb = $sebHtml.Replace($oldPay, $newPay).Replace($oldHome, $newHome)
    if ($patchedSeb -notmatch 'pay.html\?plan=presence' -or $patchedSeb -notmatch 'printful' -or $patchedSeb -notmatch 'pay.html\?plan=sitepilot') {
      Write-Host 'WARN: sebarv.com patch would drop another product. Did not write.'
    } elseif ($patchedSeb -match [regex]::Escape($oldPay)) {
      Write-Host 'WARN: sebarv.com cash_120 href still present after replace. Did not write.'
    } else {
      $sebDirs = @(
        "/home/$User/sebarv.com",
        "/home/$User/public_html/sebarv.com",
        "/home/$User/domains/sebarv.com/public_html"
      )
      foreach ($d in $sebDirs) {
        try {
          Save-Fileman $d 'index.html' $patchedSeb
        } catch {
          Write-Host ("skip {0}: {1}" -f $d, $_.Exception.Message)
          continue
        }
        Start-Sleep -Seconds 2
        $checkS = (Invoke-WebRequest -Uri 'https://sebarv.com/' -UseBasicParsing).Content
        if ($checkS -match [regex]::Escape('tonight.agency002.com/#book') -and $checkS -match 'pay.html\?plan=sitepilot') {
          $sebOk = $true
          Write-Host 'sebarv.com cash_120 now opens tonight.agency002.com. SitePilot/presence/Printful untouched.'
          break
        }
      }
    }
  }
} catch {
  Write-Host ("WARN sebarv.com: {0}" -f $_.Exception.Message)
}
if (-not $sebOk) { Write-Host 'WARN: sebarv.com still sends €120 to wait-a-day 120.cash. tonight.agency002.com is already live.' }

$finalPay = (Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing).Content
if (Test-KeychainPatched $finalPay) { $keychainOk = $true }
if ($finalPay -notmatch 'intifrog.com' -or $finalPay -notmatch 'sitepilot') {
  Write-Error 'Other keychain plans missing after write. Stop.'
}

if (-not $keychainOk -and -not $cashOk) {
  Write-Error 'Neither keychain cash_120 nor 120.cash homepage flipped. Stop.'
}
if ($keychainOk) { Write-Host 'keychain cash_120 now returns to the night desk. Other plans untouched.' }
if (-not $keychainOk) { Write-Host 'WARN: keychain still sends cash_120 to 120.cash/#brief. New 120.cash #brief still puts the page live.' }
if (-not $cashOk) {
  Write-Host 'Fileman did not flip 120.cash. Trying Cloudflare orange-cloud worker.'
  $here = $PSScriptRoot
  if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
  $localOrange = Join-Path $here 'orange-120cash.ps1'
  try {
    if (Test-Path $localOrange) {
      & $localOrange
    } else {
      $o = Join-Path $env:TEMP 'orange-120cash.ps1'
      Invoke-WebRequest -Uri "$Pages/ftp-drop/orange-120cash.ps1" -OutFile $o -UseBasicParsing
      & $o
    }
  } catch {
    Write-Host ("Cloudflare orange: {0}" -f $_.Exception.Message)
  }
}
Write-Host 'Done.'
