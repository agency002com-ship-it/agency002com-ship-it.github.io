# One run on the laptop. After this, HubWatch Fileman's the night door
# every 3 hours until 120.cash and keychain cash_120 stay flipped.
# Does not send mail. Does not touch PayPal. Does not restore FormSubmit.
#
#   powershell -File install-hub-hook.ps1

$ErrorActionPreference = 'Stop'
$HookUrl = 'https://agency002com-ship-it.github.io/ftp-drop/hub-hook.ps1'
$UploadUrl = 'https://agency002com-ship-it.github.io/ftp-drop/upload-120cash.ps1'
$BatUrl = 'https://agency002com-ship-it.github.io/ftp-drop/PUT-NIGHT-DOOR.bat'
$marker = 'shift002-night-door'

$snippet = @"
# $marker — silent if 120.cash already same-night
try {
  `$h = Join-Path `$env:TEMP 'shift002-hub-hook.ps1'
  Invoke-WebRequest -Uri '$HookUrl' -OutFile `$h -UseBasicParsing
  & `$h
} catch { }
"@

$watchCandidates = @(
  (Join-Path $env:USERPROFILE 'Hub\watch.ps1'),
  (Join-Path $env:USERPROFILE 'GrokWork\Hub\watch.ps1'),
  (Join-Path $env:USERPROFILE 'GrokWork\hub\watch.ps1')
)

$patched = $false
foreach ($watch in $watchCandidates) {
  if (-not (Test-Path $watch)) { continue }
  $text = Get-Content -Raw -Path $watch
  if ($text -match [regex]::Escape($marker)) {
    Write-Host "HubWatch already calls the night door: $watch"
    $patched = $true
    break
  }
  Add-Content -Path $watch -Value ("`r`n" + $snippet + "`r`n")
  Write-Host "Patched $watch"
  $patched = $true
  break
}
if (-not $patched) {
  Write-Host 'WARN: Hub\watch.ps1 not found. Desktop double-click still works.'
}

$desktop = Join-Path $env:USERPROFILE 'Desktop'
if (Test-Path $desktop) {
  $bat = Join-Path $desktop 'PUT-NIGHT-DOOR.bat'
  Invoke-WebRequest -Uri $BatUrl -OutFile $bat -UseBasicParsing
  Write-Host "Wrote $bat"
}

Write-Host 'Running Fileman now (keychain cash_120, then 120.cash).'
$tmp = Join-Path $env:TEMP 'upload-120cash.ps1'
Invoke-WebRequest -Uri $UploadUrl -OutFile $tmp -UseBasicParsing
try {
  & $tmp
} catch {
  Write-Host ("Fileman this run: {0}" -f $_.Exception.Message)
  if (-not $patched) { throw }
}
Write-Host 'Done. HubWatch will retry every 3 hours until the live pages stay flipped.
