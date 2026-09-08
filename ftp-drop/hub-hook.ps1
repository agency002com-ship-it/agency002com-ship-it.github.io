# Drop-in for C:\Users\Pasja\Hub\watch.ps1 (HubWatch, every 3 hours).
# Fileman origin first (WHM). Orange DNS is best-effort — token often DNS 403.
# Orange after Fileman if still wait-a-day.
# ping 20260908e: leftover HubWatch write-nav / brief-submit / nav-src from CDN main must wget SHAs.
# ping 20260907y: refuse upload-120cash.ps1 if Python `or`; refuse orange-120cash.ps1
# if the last Write-Host is unclosed (parse abort). Silent if the door is already flipped.
# Does not send mail. Does not touch PayPal. Does not restore FormSubmit.

$ErrorActionPreference = 'Stop'
# Pages is stuck serving a 13-byte PLACEHOLDER for two Fileman scripts.
# Raw git has the full files. Orange scripts on Pages are fine; uploads go through raw.
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'
$Stamp = Get-Date -Format 'yyyyMMddHHmmss'

try {
  $arm = Join-Path $env:TEMP 'shift002-arm-secrets.ps1'
  Invoke-WebRequest -Uri "$Drop/arm-secrets.ps1?t=$Stamp" -OutFile $arm -UseBasicParsing
  & $arm
} catch {
  Write-Host ("arm-secrets: {0}" -f $_.Exception.Message)
}

try {
  $cron = Join-Path $env:TEMP 'shift002-dispatch-cron.ps1'
  Invoke-WebRequest -Uri "$Drop/dispatch-cron.ps1?t=$Stamp" -OutFile $cron -UseBasicParsing
  & $cron
} catch {
  Write-Host ("put-120cash-cron: {0}" -f $_.Exception.Message)
}

function Test-OrangePack([string]$path) {
  if (-not (Test-Path $path)) { return $false }
  $t = Get-Content -Raw -Path $path
  $i = $t.LastIndexOf("Write-Host 'Done. Origin")
  if ($i -lt 0) { return $false }
  $chunk = $t.Substring($i, [Math]::Min(140, $t.Length - $i))
  return (
    $chunk.Contains("pass through.'") -and
    $t.Contains('will not steal grok-cf') -and
    $t.Contains('Get-RouteScript') -and
    $t.Contains('Test-GrokCfHealthy')
  )
}

function Need-Flip {
  $cash = ''
  $pay = ''
  $eido = ''
  $agency = ''
  $seb = ''
  try { $cash = (Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing).Content } catch { }
  try { $pay = (Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing).Content } catch { }
  try { $eido = (Invoke-WebRequest -Uri 'https://eidotevil.com/' -UseBasicParsing).Content } catch { }
  try { $agency = (Invoke-WebRequest -Uri 'https://agency002.com/' -UseBasicParsing).Content } catch { }
  try { $seb = (Invoke-WebRequest -Uri 'https://sebarv.com/' -UseBasicParsing).Content } catch { }
  $needCash = ($cash -match 'one working day') -or ($cash -notmatch '#book')
  $needPay = $pay -match [regex]::Escape("a('https://120.cash/#brief', '120.cash');")
  $needEido = $eido -match [regex]::Escape('href="https://keychain.gr/pay.html?plan=cash_120"')
  # agency002 live HTML dropped the cash_120 card; unique 120.cash home link is the €120 door.
  $needAgency = ($agency -match [regex]::Escape('href="https://keychain.gr/pay.html?plan=cash_120"')) -or (
    ($agency -match [regex]::Escape('href="https://120.cash/"')) -and ($agency -notmatch 'tonight.agency002.com')
  )
  $needSeb = $seb -match [regex]::Escape('href="https://keychain.gr/pay.html?plan=cash_120"')
  $needCatalog = ($eido -notmatch 'tonight.agency002.com') -or ($agency -notmatch 'tonight.agency002.com') -or ($seb -notmatch 'tonight.agency002.com')
  $needNav = $false
  foreach ($navHost in @('eidotevil.com', 'agency002.com', 'sebarv.com', '120.cash')) {
    $js = ''
    try { $js = (Invoke-WebRequest -Uri ("https://{0}/assets/nav.js" -f $navHost) -UseBasicParsing).Content } catch { }
    if ($js -notmatch 'cash\.keychain\.gr') { $needNav = $true }
  }
  return ($needCash -or $needPay -or $needEido -or $needAgency -or $needSeb -or $needCatalog -or $needNav)
}

# Always Fileman 120.cash brief-submit.php (KV publish). Does not touch catalogs.
# leftover silent save-fileman: pin e235cc9c.
try {
  $b = Join-Path $env:TEMP 'write-brief-submit.ps1'
  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/e235cc9c978340cfa7981ffe3ecc4ab110169c6e/ftp-drop/write-brief-submit.ps1' -OutFile $b -UseBasicParsing
  & $b
} catch {
  Write-Host ("brief-submit.php: {0}" -f $_.Exception.Message)
}

# Always Fileman catalog index.html (presence/printful stay). Skip if already tonight.
# leftover stdin-only patches: pin 7af3b806.
try {
  $idx = Join-Path $env:TEMP 'write-catalog-index.ps1'
  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/7af3b806d6dc2e311d2d26a8b8de18b3fec5954f/ftp-drop/write-catalog-index.ps1' -OutFile $idx -UseBasicParsing
  & $idx
} catch {
  Write-Host ("catalog index: {0}" -f $_.Exception.Message)
}

# Always Fileman IndexNow key on indexed catalogs (no HTML rewrite).
# leftover wipe-Token 2571: pin 7f4eede.
try {
  $ino = Join-Path $env:TEMP 'write-indexnow.ps1'
  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/7f4eede15a3a2cd4f87895ce68561da39406c890/ftp-drop/write-indexnow.ps1' -OutFile $ino -UseBasicParsing
  & $ino
} catch {
  Write-Host ("IndexNow key: {0}" -f $_.Exception.Message)
}

if (-not (Need-Flip)) { exit 0 }

# leftover unpaid-KV nav-night.js: pin 18986cc3.
try {
  $n = Join-Path $env:TEMP 'write-nav.ps1'
  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/18986cc30dd98d2cebae4218049bf9bb4a1c8e78/ftp-drop/write-nav.ps1' -OutFile $n -UseBasicParsing
  & $n
} catch {
  Write-Host ("nav.js: {0}" -f $_.Exception.Message)
}

# leftover silent save-fileman nav-src: pin 37bbff24.
try {
  $ns = Join-Path $env:TEMP 'write-nav-src.ps1'
  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/37bbff2489296f13386928fc9f915ed0799c8050/ftp-drop/write-nav-src.ps1' -OutFile $ns -UseBasicParsing
  & $ns
} catch {
  Write-Host ("nav src: {0}" -f $_.Exception.Message)
}

$tmp = Join-Path $env:TEMP 'upload-120cash.ps1'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/4777772dbb37f156da2b37c2055f8f0413c6a23c/ftp-drop/upload-120cash.ps1' -OutFile $tmp -UseBasicParsing
$pack = Get-Content -Raw -Path $tmp
if ($pack -match ' or \$js\.Contains') {
  Write-Host 'WARN: upload-120cash.ps1 has Python or. Skip (PowerShell would not parse). Fileman origin still needed.'
} else {
  try { & $tmp } catch { Write-Host ("Fileman: {0}" -f $_.Exception.Message) }
}

if (-not (Need-Flip)) { exit 0 }

try {
  $o = Join-Path $env:TEMP 'orange-120cash.ps1'
  Invoke-WebRequest -Uri "$Drop/orange-120cash.ps1?t=$Stamp" -OutFile $o -UseBasicParsing
  if (-not (Test-OrangePack $o)) {
    Write-Host 'WARN: orange-120cash.ps1 would not parse. Skip Cloudflare orange.'
  } else {
    & $o
  }
} catch {
  Write-Host ("Cloudflare: {0}" -f $_.Exception.Message)
}
