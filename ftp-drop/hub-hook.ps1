# Drop-in for C:\Users\Pasja\Hub\watch.ps1 (HubWatch, every 3 hours).
# Orange-cloud DNS first (grok-cf already intercepts 120.cash/* and keychain pay.html*).
# Fileman if still wait-a-day. Orange again as fallback workers.
# ping 20260907y: refuse upload-120cash.ps1 if Python `or`; refuse orange-120cash.ps1
# if the last Write-Host is unclosed (parse abort). Silent if the door is already flipped.
# Does not send mail. Does not touch PayPal. Does not restore FormSubmit.

$ErrorActionPreference = 'Stop'
# Pages is stuck serving a 13-byte PLACEHOLDER for two Fileman scripts.
# Raw git has the full files. Orange scripts on Pages are fine; uploads go through raw.
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'
$Stamp = Get-Date -Format 'yyyyMMddHHmmss'

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
try {
  $b = Join-Path $env:TEMP 'write-brief-submit.ps1'
  Invoke-WebRequest -Uri "$Drop/write-brief-submit.ps1?t=$Stamp" -OutFile $b -UseBasicParsing
  & $b
} catch {
  Write-Host ("brief-submit.php: {0}" -f $_.Exception.Message)
}

# Always Fileman catalog index.html (presence/printful stay). Skip if already tonight.
try {
  $idx = Join-Path $env:TEMP 'write-catalog-index.ps1'
  Invoke-WebRequest -Uri "$Drop/write-catalog-index.ps1?t=$Stamp" -OutFile $idx -UseBasicParsing
  & $idx
} catch {
  Write-Host ("catalog index: {0}" -f $_.Exception.Message)
}

if (-not (Need-Flip)) { exit 0 }

try {
  $n = Join-Path $env:TEMP 'write-nav.ps1'
  Invoke-WebRequest -Uri "$Drop/write-nav.ps1?t=$Stamp" -OutFile $n -UseBasicParsing
  & $n
} catch {
  Write-Host ("nav.js: {0}" -f $_.Exception.Message)
}

try {
  $ns = Join-Path $env:TEMP 'write-nav-src.ps1'
  Invoke-WebRequest -Uri "$Drop/write-nav-src.ps1?t=$Stamp" -OutFile $ns -UseBasicParsing
  & $ns
} catch {
  Write-Host ("nav src: {0}" -f $_.Exception.Message)
}

try {
  $o = Join-Path $env:TEMP 'orange-120cash.ps1'
  Invoke-WebRequest -Uri "$Drop/orange-120cash.ps1?t=$Stamp" -OutFile $o -UseBasicParsing
  if (-not (Test-OrangePack $o)) {
    Write-Host 'WARN: orange-120cash.ps1 would not parse. Skip Cloudflare orange (Fileman still runs).'
  } else {
    & $o
  }
} catch {
  Write-Host ("Cloudflare first: {0}" -f $_.Exception.Message)
}

if (-not (Need-Flip)) { exit 0 }

$tmp = Join-Path $env:TEMP 'upload-120cash.ps1'
Invoke-WebRequest -Uri "$Drop/upload-120cash.ps1?t=$Stamp" -OutFile $tmp -UseBasicParsing
$pack = Get-Content -Raw -Path $tmp
if ($pack -match ' or \$js\.Contains') {
  Write-Host 'WARN: upload-120cash.ps1 has Python or. Skip (PowerShell would not parse). Orange DNS already ran.'
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
