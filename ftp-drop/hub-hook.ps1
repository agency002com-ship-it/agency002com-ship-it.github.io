# Drop-in for C:\Users\Pasja\Hub\watch.ps1 (HubWatch, every 3 hours).
# Orange-cloud DNS first (grok-cf already intercepts 120.cash/* and keychain pay.html*).
# Fileman if still wait-a-day. Orange again as fallback workers.
# Silent if the door is already flipped.
# Does not send mail. Does not touch PayPal. Does not restore FormSubmit.

$ErrorActionPreference = 'Stop'
# Pages is stuck serving a 13-byte PLACEHOLDER for two Fileman scripts.
# Raw git has the full files. Orange scripts on Pages are fine; uploads go through raw.
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'

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
  $needCash = $cash -match 'one working day'
  $needPay = $pay -match [regex]::Escape("a('https://120.cash/#brief', '120.cash');")
  $needEido = $eido -match [regex]::Escape('href="https://keychain.gr/pay.html?plan=cash_120"')
  $needAgency = (
    ($agency -match 'one working day') -or
    ($agency -match [regex]::Escape('href="https://keychain.gr/pay.html?plan=cash_120"')) -or
    (($agency -match [regex]::Escape('href="https://120.cash/"')) -and ($agency -notmatch 'tonight.agency002.com'))
  )
  $needSeb = $seb -match [regex]::Escape('href="https://keychain.gr/pay.html?plan=cash_120"')
  return ($needCash -or $needPay -or $needEido -or $needAgency -or $needSeb)
}

if (-not (Need-Flip)) { exit 0 }

try {
  $o = Join-Path $env:TEMP 'orange-120cash.ps1'
  Invoke-WebRequest -Uri "$Drop/orange-120cash.ps1" -OutFile $o -UseBasicParsing
  & $o
} catch {
  Write-Host ("Cloudflare first: {0}" -f $_.Exception.Message)
}

if (-not (Need-Flip)) { exit 0 }

try {
  $n = Join-Path $env:TEMP 'write-nav.ps1'
  Invoke-WebRequest -Uri "$Drop/write-nav.ps1" -OutFile $n -UseBasicParsing
  & $n
} catch {
  Write-Host ("nav.js: {0}" -f $_.Exception.Message)
}

try {
  $ns = Join-Path $env:TEMP 'write-nav-src.ps1'
  Invoke-WebRequest -Uri "$Drop/write-nav-src.ps1" -OutFile $ns -UseBasicParsing
  & $ns
} catch {
  Write-Host ("nav src: {0}" -f $_.Exception.Message)
}

if (-not (Need-Flip)) { exit 0 }

$tmp = Join-Path $env:TEMP 'upload-120cash.ps1'
Invoke-WebRequest -Uri "$Drop/upload-120cash.ps1" -OutFile $tmp -UseBasicParsing
try { & $tmp } catch { Write-Host ("Fileman: {0}" -f $_.Exception.Message) }

if (-not (Need-Flip)) { exit 0 }

try {
  $o = Join-Path $env:TEMP 'orange-120cash.ps1'
  Invoke-WebRequest -Uri "$Drop/orange-120cash.ps1" -OutFile $o -UseBasicParsing
  & $o
} catch {
  Write-Host ("Cloudflare: {0}" -f $_.Exception.Message)
}
