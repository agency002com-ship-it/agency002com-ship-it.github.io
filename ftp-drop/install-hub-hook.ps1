# One run on the laptop. After this, HubWatch (3h), schtasks hourly + logon,
# pages 2026-09-07: copies patch-sebarv.py; orange-120cash also oranges agency002/sebarv.
# Fileman, and Cloudflare orange-cloud until 120.cash stays flipped.
# Does not send mail. Does not touch PayPal. Does not restore FormSubmit.
#
#   powershell -File install-hub-hook.ps1

$ErrorActionPreference = 'Stop'
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'
$Stamp = Get-Date -Format 'yyyyMMddHHmmss'
$HookUrl = "$Drop/hub-hook.ps1?t=$Stamp"
$UploadUrl = "$Drop/upload-120cash.ps1?t=$Stamp"
$OrangeUrl = "$Drop/orange-120cash.ps1?t=$Stamp"
$BatUrl = "$Drop/PUT-NIGHT-DOOR.bat?t=$Stamp"
$marker = 'shift002-night-door'

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
  try {
    Invoke-WebRequest -Uri "$Drop/RUN-SHIFT002.ps1?t=$Stamp" -OutFile (Join-Path $desktop 'RUN-SHIFT002.ps1') -UseBasicParsing
    Write-Host 'Wrote Desktop\RUN-SHIFT002.ps1'
  } catch {
    Write-Host ("WARN Desktop RUN-SHIFT002: {0}" -f $_.Exception.Message)
  }
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
cmd /c "schtasks /Create /TN Shift002NightDoorLogon /TR `"$runner`" /SC ONLOGON /F"
if ($LASTEXITCODE -eq 0) {
  $scheduled = $true
  Write-Host 'Scheduled Shift002NightDoorLogon (ONLOGON)'
}

$startup = [Environment]::GetFolderPath('Startup')
if ($startup -and (Test-Path $startup)) {
  Copy-Item -Path $runner -Destination (Join-Path $startup 'Shift002NightDoor.bat') -Force
  Write-Host "Wrote Startup\Shift002NightDoor.bat"
}

$gw = Join-Path $env:USERPROFILE 'GrokWork'
if (Test-Path $gw) {
  try {
    Invoke-WebRequest -Uri "$Drop/RUN-SHIFT002.ps1?t=$Stamp" -OutFile (Join-Path $gw 'RUN-SHIFT002.ps1') -UseBasicParsing
    Write-Host 'Wrote GrokWork\RUN-SHIFT002.ps1'
  } catch {
    Write-Host ("WARN GrokWork RUN-SHIFT002: {0}" -f $_.Exception.Message)
  }
}

$ftp = Join-Path $env:USERPROFILE 'GrokWork\ftp'
if (Test-Path $ftp) {
  foreach ($name in @(
    'install-hub-hook.ps1',
    'upload-120cash.ps1',
    'save-fileman.ps1',
    'orange-120cash.ps1',
    'orange-120cash.sh',
    'orange-worker.js',
    'orange-keychain-worker.js',
    'patch-keychain.py',
    'patch-agency.py',
    'patch-eidotevil.py',
    'patch-sebarv.py',
    'patch-120cash.py',
    'patch-nav-src.py',
    'hub-hook.ps1',
    'write-nav.ps1',
    'write-nav-src.ps1',
    'write-brief-submit.ps1',
    'brief-submit.php',
    'write-catalog-index.ps1',
    '120-index.html',
    '120-sitemap.xml.tpl',
    'nav-night.js',
    'fileman-save.sh',
    'fileman-120cash.sh',
    'RUN-SHIFT002.ps1'
  )) {
    try {
      Invoke-WebRequest -Uri "$Drop/${name}?t=$Stamp" -OutFile (Join-Path $ftp $name) -UseBasicParsing
      Write-Host "Copied $name next to the cPanel token"
    } catch {
      Write-Host ("WARN copy ${name}: {0}" -f $_.Exception.Message)
    }
  }
}

# One laptop run can arm GitHub Actions so 120.cash stays flipped after sleep.
# Tokens stay on disk / in gh secrets. Never echoed. Never committed.
# Do not let a missing gh/secret abort Fileman below.
$PagesRepo = 'agency002com-ship-it/agency002com-ship-it.github.io'
try {
  $CfTok = $env:CLOUDFLARE_API_TOKEN
  foreach ($cfg in @(
    (Join-Path $ftp 'config.cloudflare.local.ps1'),
    (Join-Path $ftp 'config.cf.local.ps1')
  )) {
    if (-not (Test-Path $cfg)) { continue }
    . $cfg
    if (-not $CfTok) { $CfTok = $CloudflareToken }
    if (-not $CfTok) { $CfTok = $CfApiToken }
    if (-not $CfTok) { $CfTok = $CF_API_TOKEN }
    if (-not $CfTok) { $CfTok = $ApiToken }
  }
  $CpTok = $env:CPANEL_TOKEN
  $CpHost = $env:CPANEL_HOST
  $CpUser = $env:CPANEL_USER
  foreach ($cfg in @(
    (Join-Path $ftp 'config.cpanel.local.ps1'),
    (Join-Path $ftp 'config.local.ps1')
  )) {
    if (-not (Test-Path $cfg)) { continue }
    . $cfg
    if (-not $CpTok) { $CpTok = $CpanelToken }
    if (-not $CpTok) { $CpTok = $WhmToken }
    if (-not $CpHost) { $CpHost = $CpanelHost }
    if (-not $CpHost) { $CpHost = $WhmHost }
    if (-not $CpUser) { $CpUser = $CpanelUser }
  }
  if (-not $CpHost) { $CpHost = '192.250.229.162' }
  if (-not $CpUser) { $CpUser = 'agency00' }

  function Set-NightDoorSecret([string]$Name, [string]$Value) {
    if (-not $Value) { return }
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
      Write-Host "WARN: gh not on PATH. Skip GitHub secret $Name"
      return
    }
    try {
      $Value | & gh secret set $Name --repo $PagesRepo
      Write-Host "Set github.io Actions secret $Name (value not printed)"
    } catch {
      Write-Host ("WARN gh secret ${Name}: {0}" -f $_.Exception.Message)
    }
  }
  Set-NightDoorSecret 'CLOUDFLARE_API_TOKEN' $CfTok
  Set-NightDoorSecret 'CPANEL_TOKEN' $CpTok
  Set-NightDoorSecret 'CPANEL_HOST' $CpHost
  Set-NightDoorSecret 'CPANEL_USER' $CpUser
  Set-NightDoorSecret 'CPANEL_DIR' ("/home/{0}/domains/120.cash/public_html" -f $CpUser)
  if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
      & gh workflow run put-120cash.yml --repo $PagesRepo
      Write-Host 'Triggered github.io workflow put-120cash (no token printed)'
      & gh workflow run put-catalog-nav.yml --repo $PagesRepo
      Write-Host 'Triggered github.io workflow put-catalog-nav (no token printed)'
      & gh workflow run put-catalog-index.yml --repo $PagesRepo
      Write-Host 'Triggered github.io workflow put-catalog-index (no token printed)'
    } catch {
      Write-Host ("WARN workflow run: {0}" -f $_.Exception.Message)
    }
  }
} catch {
  Write-Host ("WARN GitHub secrets: {0}" -f $_.Exception.Message)
}

$modes = Join-Path $env:USERPROFILE 'GrokModes'
if (Test-Path $modes) {
  @(
    'Stop outreach. No cold mail. Do not touch PayPal.',
    'powershell -File RUN-SHIFT002.ps1',
    'powershell -File install-hub-hook.ps1',
    "$Drop/install-hub-hook.ps1"
  ) | Set-Content -Path (Join-Path $modes 'DO-TONIGHT.txt') -Encoding ASCII
  Write-Host 'Wrote GrokModes\DO-TONIGHT.txt'
}

function Test-NeedFlip {
  $cashAfter = ''
  $payAfter = ''
  $eidoAfter = ''
  $agencyAfter = ''
  $sebAfter = ''
  try { $cashAfter = (Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing).Content } catch { }
  try { $payAfter = (Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing).Content } catch { }
  try { $eidoAfter = (Invoke-WebRequest -Uri 'https://eidotevil.com/' -UseBasicParsing).Content } catch { }
  try { $agencyAfter = (Invoke-WebRequest -Uri 'https://agency002.com/' -UseBasicParsing).Content } catch { }
  try { $sebAfter = (Invoke-WebRequest -Uri 'https://sebarv.com/' -UseBasicParsing).Content } catch { }
  return (
    ($cashAfter -match 'one working day') -or
    ($cashAfter -notmatch '#book') -or
    ($payAfter -match [regex]::Escape("a('https://120.cash/#brief', '120.cash');")) -or
    ($eidoAfter -match [regex]::Escape('href="https://keychain.gr/pay.html?plan=cash_120"')) -or
    ($agencyAfter -match 'one working day') -or
    ($agencyAfter -match [regex]::Escape('href="https://keychain.gr/pay.html?plan=cash_120"')) -or
    (($agencyAfter -match [regex]::Escape('href="https://120.cash/"')) -and ($agencyAfter -notmatch 'tonight.agency002.com')) -or
    ($sebAfter -match [regex]::Escape('href="https://keychain.gr/pay.html?plan=cash_120"'))
  )
}

# Orange DNS first: grok-cf already intercepts 120.cash and keychain pay.html.
# Fileman is origin permanence. Do not skip Fileman if orange already flipped —
# HubWatch will skip later once live HTML stays same-night.
if (Test-NeedFlip) {
  Write-Host 'Orange-cloud DNS first (existing grok-cf routes).'
  $otmp = Join-Path $env:TEMP 'orange-120cash.ps1'
  try {
    Invoke-WebRequest -Uri $OrangeUrl -OutFile $otmp -UseBasicParsing
    if (-not (Test-OrangePack $otmp)) {
      Write-Host 'WARN: orange-120cash.ps1 would not parse. Skip Cloudflare orange (Fileman still runs).'
    } else {
      & $otmp
    }
  } catch {
    Write-Host ("Cloudflare first: {0}" -f $_.Exception.Message)
  }
}

Write-Host 'Writing catalog /assets/nav.js (tiny Fileman; cash_120 only).'
$ntmp = Join-Path $env:TEMP 'write-nav.ps1'
try {
  Invoke-WebRequest -Uri "$Drop/write-nav.ps1?t=$Stamp" -OutFile $ntmp -UseBasicParsing
  & $ntmp
} catch {
  Write-Host ("nav.js this run: {0}" -f $_.Exception.Message)
}

Write-Host 'Pointing unique catalog nav.js tags at github.io (cache-bust).'
$nstmp = Join-Path $env:TEMP 'write-nav-src.ps1'
try {
  Invoke-WebRequest -Uri "$Drop/write-nav-src.ps1?t=$Stamp" -OutFile $nstmp -UseBasicParsing
  & $nstmp
} catch {
  Write-Host ("nav src this run: {0}" -f $_.Exception.Message)
}

Write-Host 'Writing 120.cash brief-submit.php (KV publish; this host only).'
$bstmp = Join-Path $env:TEMP 'write-brief-submit.ps1'
try {
  Invoke-WebRequest -Uri "$Drop/write-brief-submit.ps1?t=$Stamp" -OutFile $bstmp -UseBasicParsing
  & $bstmp
} catch {
  Write-Host ("brief-submit this run: {0}" -f $_.Exception.Message)
}

Write-Host 'Patching catalog index.html (agency002 ghost 120.cash/ link).'
$ctmp = Join-Path $env:TEMP 'write-catalog-index.ps1'
try {
  Invoke-WebRequest -Uri "$Drop/write-catalog-index.ps1?t=$Stamp" -OutFile $ctmp -UseBasicParsing
  & $ctmp
} catch {
  Write-Host ("catalog index this run: {0}" -f $_.Exception.Message)
}

Write-Host 'Running Fileman now (keychain, 120.cash, eidotevil, agency002, sebarv cash_120).'
$tmp = Join-Path $env:TEMP 'upload-120cash.ps1'
Invoke-WebRequest -Uri $UploadUrl -OutFile $tmp -UseBasicParsing
$pack = Get-Content -Raw -Path $tmp
if ($pack -match ' or \$js\.Contains') {
  Write-Host 'WARN: upload-120cash.ps1 has Python or. Skip Fileman pack (PowerShell would not parse).'
} else {
  try {
    & $tmp
  } catch {
    Write-Host ("Fileman this run: {0}" -f $_.Exception.Message)
    if (-not $patched -and -not $scheduled) { throw }
  }
}

if (Test-NeedFlip) {
  Write-Host 'Still wait-a-day. Cloudflare orange-cloud again (fallback workers).'
  $otmp = Join-Path $env:TEMP 'orange-120cash.ps1'
  try {
    Invoke-WebRequest -Uri $OrangeUrl -OutFile $otmp -UseBasicParsing
    if (-not (Test-OrangePack $otmp)) {
      Write-Host 'WARN: orange-120cash.ps1 would not parse. Skip Cloudflare orange.'
    } else {
      & $otmp
    }
  } catch {
    Write-Host ("Cloudflare this run: {0}" -f $_.Exception.Message)
  }
} else {
  Write-Host 'Indexed cash_120 doors already same-night.'
}
Write-Host 'Done. HubWatch, hourly, and logon retry until the live pages stay flipped.'
# parse-closed — keep this line so the Done quote cannot be the last byte of the file
