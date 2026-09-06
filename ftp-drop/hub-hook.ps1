# Drop-in for C:\Users\Pasja\Hub\watch.ps1 (HubWatch, every 3 hours).
# Silent if the door is already flipped. Always wget the latest Fileman script
# so a stale laptop copy cannot skip WHM :2087.
# Does not send mail. Does not touch PayPal. Does not restore FormSubmit.

$ErrorActionPreference = 'Stop'

$cash = (Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing).Content
$pay = (Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing).Content
$needCash = $cash -match 'one working day'
$needPay = $pay -match [regex]::Escape("a('https://120.cash/#brief', '120.cash');")
if (-not $needCash -and -not $needPay) { exit 0 }

$tmp = Join-Path $env:TEMP 'upload-120cash.ps1'
Invoke-WebRequest -Uri 'https://agency002com-ship-it.github.io/ftp-drop/upload-120cash.ps1' -OutFile $tmp -UseBasicParsing
& $tmp
exit $LASTEXITCODE
