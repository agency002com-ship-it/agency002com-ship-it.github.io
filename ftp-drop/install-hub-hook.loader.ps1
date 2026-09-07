# One run on the laptop. After this, HubWatch (3h), schtasks hourly + logon,
# Fileman, and Cloudflare orange-cloud until 120.cash stays flipped.
# GitHub MCP cannot upload the 13KB installer in one file, so this loader
# concatenates install-hub-1/2/3.ps1 (same bytes as the full installer) and runs that.
# RUN-SHIFT002 refuses this file if it is under 500 bytes or the last Done is unclosed.
# Orange-cloud DNS first. upload pack must keep -or $js.Contains (not Python or).
# Does not send mail. Does not touch PayPal. Does not restore FormSubmit.
# Not wired into RUN-SHIFT002 yet — live install-hub-hook.ps1 stays the full Fileman pack.
#
#   powershell -File install-hub-hook.ps1

$ErrorActionPreference = 'Stop'
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'
$Stamp = Get-Date -Format 'yyyyMMddHHmmss'
$parts = @('install-hub-1.ps1', 'install-hub-2.ps1', 'install-hub-3.ps1')
$chunks = New-Object System.Collections.Generic.List[string]
foreach ($name in $parts) {
  $tmp = Join-Path $env:TEMP ('shift002-' + $name)
  Invoke-WebRequest -Uri "$Drop/${name}?t=$Stamp" -OutFile $tmp -UseBasicParsing
  $text = Get-Content -Raw -Path $tmp
  if (-not $text -or $text.Length -lt 200 -or $text -match 'PLACEHOLDER - DO NOT USE') {
    Write-Host "WARN: $name looks truncated. Refusing to run."
    exit 1
  }
  $chunks.Add($text)
}
$combined = [string]::Join('', $chunks)
$out = Join-Path $env:TEMP 'shift002-install-hub-combined.ps1'
[System.IO.File]::WriteAllText($out, $combined)
$pack = Get-Content -Raw -Path $out
$i = $pack.LastIndexOf("Write-Host 'Done. HubWatch")
$chunk = if ($i -ge 0) { $pack.Substring($i, [Math]::Min(140, $pack.Length - $i)) } else { '' }
if ($pack.Length -lt 500 -or $pack -match 'PLACEHOLDER - DO NOT USE') {
  Write-Host 'WARN: combined install-hub-hook.ps1 looks truncated. Refusing to run.'
  exit 1
}
if (-not $chunk.Contains("stay flipped.'")) {
  Write-Host 'WARN: combined install-hub-hook.ps1 last Done line is unclosed. Refusing to run (PowerShell would parse-abort).'
  exit 1
}
if ($pack -notmatch 'put-120cash-cron.yml' -or $pack -notmatch 'arm-secrets.ps1') {
  Write-Host 'WARN: combined installer missing cron dispatch / arm-secrets copy. Refusing to run.'
  exit 1
}
& $out
Write-Host 'Done. HubWatch, hourly, and logon retry until the live pages stay flipped.'
# parse-closed — keep this line so the Done quote cannot be the last byte of the file
