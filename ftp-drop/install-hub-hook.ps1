# One run on the laptop. After this, HubWatch (3h) and schtasks hourly
# Fileman until 120.cash and keychain cash_120 stay flipped.
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
  Write-Host 'WARN: Hub\watch.ps1 not found. Hourly task still runs.'
}

$desktop = Join-Path $env:USERPROFILE 'Desktop'
if (Test-Path $desktop) {
  $bat = Join-Path $desktop 'PUT-NIGHT-DOOR.bat'
  Invoke-WebRequest -Uri $BatUrl -OutFile $bat -UseBasicParsing
  Write-Host "Wrote $bat"
}

# HubWatch is every 3 hours. Also an hourly task that only Fileman's while
# 120.cash still says working day. schtasks /Create works here; Register-ScheduledTask does not.
$hub = Join-Path $env:USERPROFILE 'Hub'
if (-not (Test-Path $hub)) { New-Item -ItemType Directory -Path $hub | Out-Null }
$runner = Join-Path $hub 'shift002-night-door.bat'
@(
  '@echo off'
  'REM Silent when 120.cash and keychain cash_120 are already same-night.'
  "powershell -NoProfile -ExecutionPolicy Bypass -Command `"Invoke-WebRequest -Uri '$HookUrl' -OutFile (`$env:TEMP + '\shift002-hub-hook.ps1') -UseBasicParsing; & (`$env:TEMP + '\shift002-hub-hook.ps1')`""
) | Set-Content -Path $runner -Encoding ASCII
$scheduled = $false
cmd /c "schtasks /Create /TN Shift002NightDoor /TR `"$runner`" /SC HOURLY /F"
if ($LASTEXITCODE -eq 0) {
  $scheduled = $true
  Write-Host "Scheduled hourly Shift002NightDoor -> $runner"
} else {
  Write-Host 'WARN: schtasks did not create Shift002NightDoor. HubWatch patch / Desktop bat still apply.'
}

Write-Host 'Running Fileman now (keychain cash_120, then 120.cash).'
$tmp = Join-Path $env:TEMP 'upload-120cash.ps1'
Invoke-WebRequest -Uri $UploadUrl -OutFile $tmp -UseBasicParsing
try {
  & $tmp
} catch {
  Write-Host ("Fileman this run: {0}" -f $_.Exception.Message)
  if (-not $patched -and -not $scheduled) { throw }
}
Write-Host 'Done. HubWatch and hourly Shift002NightDoor retry until the live pages stay flipped.'
