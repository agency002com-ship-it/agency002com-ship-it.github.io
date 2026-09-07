# Laptop Fileman for the same-night €120 door.
# Nav.js first (eidotevil / agency002 / sebarv / 120.cash): Pay cash_120 →
# cash.keychain.gr; unique wait-a-day copy → same night; briefs → tonight KV.
# Then unique nav.js src cache-bust. Then 120.cash index.html if HTML still
# says wait-a-day (curl/Google see source, not JS). After index is same-night:
# sitemap.xml (lastmod + hourly) + IndexNow key, ping 120.cash only (never the
# wait-a-day page). Then keychain.gr pay.html cash_120 after-pay. Other keychain
# plans stay. No mail. No PayPal passwords.
#
#   powershell -File upload-120cash.ps1

$ErrorActionPreference = 'Stop'
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'
$Pages = 'https://agency002com-ship-it.github.io'
$Paid = "$Pages/paid.html"

$ftpDir = Join-Path $env:USERPROFILE 'GrokWork\\ftp'
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
if (-not $Dir) { $Dir = "/home/$User/120.cash" }
$WhmUserName = $env:WHM_USER
if (-not $WhmUserName) { $WhmUserName = $WhmUser }
$HostNames = @($HostName, '192.250.229.162', 'agency002.com', 'lemonpie.codes') |
  Where-Object { $_ } | Select-Object -Unique

if (-not $Token) {
  Write-Error @"
No cPanel token in this session.
Dot-source GrokWork\\ftp\\config.cpanel.local.ps1 (already on the laptop),
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
  Invoke-WebRequest -Uri "$Drop/$name" -OutFile $tmp -UseBasicParsing
  & $tmp
}

function Invoke-PythonPatch([string]$scriptName, [string]$html) {
  $py = Join-Path $here $scriptName
  if (-not (Test-Path $py)) {
    $py = Join-Path $env:TEMP "shift002-$scriptName"
    Invoke-WebRequest -Uri "$Drop/$scriptName" -OutFile $py -UseBasicParsing
  }
  $python = Get-Command python3 -ErrorAction SilentlyContinue
  if (-not $python) { $python = Get-Command python -ErrorAction SilentlyContinue }
  if (-not $python) {
    Write-Host "WARN: python3/python not on PATH. Skip $scriptName"
    return $null
  }
  $inFile = Join-Path $env:TEMP ("shift002-in-" + $scriptName + ".html")
  $outFile = Join-Path $env:TEMP ("shift002-out-" + $scriptName + ".html")
  $errFile = Join-Path $env:TEMP ("shift002-err-" + $scriptName + ".txt")
  [System.IO.File]::WriteAllText($inFile, $html)
  $p = Start-Process -FilePath $python.Source -ArgumentList @($py) -RedirectStandardInput $inFile -RedirectStandardOutput $outFile -RedirectStandardError $errFile -Wait -PassThru -NoNewWindow
  if ($p.ExitCode -ne 0 -or -not (Test-Path $outFile)) { return $null }
  return [System.IO.File]::ReadAllText($outFile)
}

$localSave = Join-Path $here 'save-fileman.ps1'
if (Test-Path $localSave) {
  . $localSave
} else {
  $save = Join-Path $env:TEMP 'shift002-save-fileman.ps1'
  Invoke-WebRequest -Uri "$Drop/save-fileman.ps1" -OutFile $save -UseBasicParsing
  . $save
}

function Write-OriginDiscover {
  $stamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  $sitemap = @"
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">
  <url>
    <loc>https://120.cash/</loc>
    <lastmod>$stamp</lastmod>
    <changefreq>hourly</changefreq>
    <priority>1.0</priority>
  </url>
</urlset>
"@
  $key = '7c2a9f1e4b8d0c3a5e6f7a8b9c0d1e2f'
  foreach ($d in @($Dir, "/home/$User/public_html/120.cash", "/home/$User/domains/120.cash/public_html")) {
    try { Save-Fileman $d 'sitemap.xml' $sitemap } catch {
      Write-Host ("skip sitemap {0}: {1}" -f $d, $_.Exception.Message)
    }
    try { Save-Fileman $d ($key + '.txt') $key } catch {
      Write-Host ("skip IndexNow key {0}: {1}" -f $d, $_.Exception.Message)
    }
  }
  $json = '{\"host\":\"120.cash\",\"key\":\"' + $key + '\",\"keyLocation\":\"https://120.cash/' + $key + '.txt\",\"urlList\":[\"https://120.cash/\"]}'
  try {
    Invoke-WebRequest -Uri 'https://api.indexnow.org/indexnow' -Method POST -ContentType 'application/json; charset=utf-8' -Body $json -UseBasicParsing | Out-Null
    Write-Host 'IndexNow pinged https://120.cash/ (flipped homepage only).'
  } catch {
    Write-Host ("WARN IndexNow: {0}" -f $_.Exception.Message)
  }
}

Write-Host 'Writing catalog /assets/nav.js (cash_120 only).'
try { Invoke-DropScript 'write-nav.ps1' } catch {
  Write-Host ("WARN nav.js: {0}" -f $_.Exception.Message)
}

Write-Host 'Pointing unique nav.js tags at github.io night nav.'
try { Invoke-DropScript 'write-nav-src.ps1' } catch {
  Write-Host ("WARN nav src: {0}" -f $_.Exception.Message)
}

$page120 = ''
try { $page120 = (Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing).Content } catch { }
if ($page120 -match 'one working day') {
  Write-Host 'Patching 120.cash index.html so source (not only JS) is same-night.'
  $patched120 = $null
  try { $patched120 = Invoke-PythonPatch 'patch-120cash.py' $page120 } catch {
    Write-Host ("WARN 120.cash patch: {0}" -f $_.Exception.Message)
  }
  if ($patched120 -and $patched120 -notmatch 'one working day') {
    foreach ($d in @($Dir, "/home/$User/public_html/120.cash", "/home/$User/domains/120.cash/public_html")) {
      try { Save-Fileman $d 'index.html' $patched120 } catch {
        Write-Host ("skip {0}: {1}" -f $d, $_.Exception.Message)
      }
    }
    Start-Sleep -Seconds 2
  } else {
    Write-Host 'WARN: 120.cash index needles not unique. Skip index write.'
  }
}

function Test-KeychainPatched([string]$content) {
  return ($content -match [regex]::Escape($Paid) -and $content -notmatch [regex]::Escape(\"a('https://120.cash/#brief', '120.cash');\"))
}

$oldLink = \"a('https://120.cash/#brief', '120.cash');\"
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
if ($html -notmatch \"kind === 'cash_120'\") {
  Write-Host 'WARN: live pay.html has no cash_120 branch. Skipping till rewrite.'
} elseif (Test-KeychainPatched $html) {
  Write-Host 'pay.html already points cash_120 at paid.html.'
  $keychainOk = $true
} else {
  $nLink = ([regex]::Matches($html, [regex]::Escape($oldLink))).Count
  $nBounce = ([regex]::Matches($html, [regex]::Escape($oldBounce))).Count
  $nDone = ([regex]::Matches($html, [regex]::Escape($oldDone))).Count
  if ($nLink -ne 1 -or $nBounce -ne 1 -or $nDone -ne 1) {
    Write-Host (\"WARN: pay.html needles not unique (link=$nLink bounce=$nBounce done=$nDone). Skipping till rewrite.\")
  } else {
    $html = $html.Replace($oldLink, $newLink).Replace($oldBounce, $newBounce).Replace($oldDone, $newDone)
    if ($html -notmatch 'intifrog.com' -or $html -notmatch 'msking.shop' -or $html -notmatch 'muslimpowergroup.com') {
      Write-Host 'WARN: patch would drop another plan. Did not write pay.html.'
    } else {
      foreach ($d in @(\"/home/$User/keychain.gr\", \"/home/$User/public_html/keychain.gr\", \"/home/$User/domains/keychain.gr/public_html\")) {
        try { Save-Fileman $d 'pay.html' $html } catch {
          Write-Host (\"skip {0}: {1}\" -f $d, $_.Exception.Message)
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
    $h = (Invoke-WebRequest -Uri (\"https://{0}/\" -f $site) -UseBasicParsing).Content
    $js = (Invoke-WebRequest -Uri (\"https://{0}/assets/nav.js\" -f $site) -UseBasicParsing).Content
    if ($h.Contains('ftp-drop/nav-night.js') -or $js.Contains('cash.keychain.gr')) {
      Write-Host (\"OK {0} night nav live.\" -f $site)
      $navLive++
    } else {
      Write-Host (\"WARN {0} nav.js still year-stamp.\" -f $site)
    }
  } catch {
    Write-Host (\"WARN check {0}: {1}\" -f $site, $_.Exception.Message)
  }
}

if ($keychainOk) { Write-Host 'keychain cash_120 now returns to the night desk. Other plans untouched.' }
if (-not $keychainOk) { Write-Host 'WARN: keychain still sends cash_120 to 120.cash/#brief. Catalog nav.js still flips Pay to cash.keychain.gr.' }

$stillCash = $false
try {
  $stillCash = ((Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing).Content -match 'one working day')
} catch { $stillCash = $true }

if (-not $stillCash) {
  Write-Host '120.cash same-night. Origin sitemap + IndexNow key, then ping IndexNow (not the wait-a-day page).'
  try { Write-OriginDiscover } catch {
    Write-Host (\"WARN origin discover: {0}\" -f $_.Exception.Message)
  }
}

if (-not $keychainOk -or $navLive -lt 4 -or $stillCash) {
  Write-Host 'Still wait-a-day. Cloudflare orange-cloud (existing grok-cf routes).'
  try { Invoke-DropScript 'orange-120cash.ps1' } catch {
    Write-Host (\"Cloudflare orange: {0}\" -f $_.Exception.Message)
  }
}
Write-Host 'Done.'
