# Drop-in for C:\Users\Pasja\Hub\watch.ps1 (HubWatch, every 3 hours).
# Orange-cloud DNS first (grok-cf routes already on 120.cash/* and keychain pay.html*).
# Fileman if still wait-a-day. Orange again as fallback workers.
# Silent if the door is already flipped.
# Does not send mail. Does not touch PayPal. Does not restore FormSubmit.

$ErrorActionPreference = 'Stop'
$Drop = 'https://agency002com-ship-it.github.io/ftp-drop'

function Need-Flip {
  $cash = ''
  $pay = ''
  $agency = ''
  try { $cash = (Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing).Content } catch { }
  try { $pay = (Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing).Content } catch { }
  try { $agency = (Invoke-WebRequest -Uri 'https://agency002.com/' -UseBasicParsing).Content } catch { }
  $needCash = $cash -match 'one working day'
  $needPay = $pay -match [regex]::Escape("a('https://120.cash/#brief', '120.cash');")
  $needAgency = $agency -match [regex]::Escape('href="https://keychain.gr/pay.html?plan=cash_120"')
  return ($needCash -or $needPay -or $needAgency)
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
