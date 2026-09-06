# Drop-in for Hub\watch.ps1 (every 3 hours). Silent if the door is already flipped.
# Does not send mail. Does not touch PayPal. Does not restore FormSubmit.
#
# Add one line to Hub\watch.ps1:
#   & (Join-Path $PSScriptRoot '..\..\...\hub-hook.ps1')
# Or wget this file next to upload-120cash.ps1 and call it from watch.

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }

$cash = (Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing).Content
$pay = (Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing).Content
$needCash = $cash -match 'one working day'
$needPay = $pay -match [regex]::Escape("a('https://120.cash/#brief', '120.cash');")
if (-not $needCash -and -not $needPay) { exit 0 }

$script = Join-Path $here 'upload-120cash.ps1'
if (-not (Test-Path $script)) {
  $tmp = Join-Path $env:TEMP 'upload-120cash.ps1'
  Invoke-WebRequest -Uri 'https://agency002com-ship-it.github.io/ftp-drop/upload-120cash.ps1' -OutFile $tmp -UseBasicParsing
  $script = $tmp
}
& $script
exit $LASTEXITCODE
