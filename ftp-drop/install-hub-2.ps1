
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
  if (-not $CpTok) { $CpTok = $env:CPANEL_API_TOKEN }
  if (-not $CpTok) { $CpTok = $env:WHM_API_TOKEN }
  if (-not $CpTok) { $CpTok = $env:WHM_TOKEN }
  $CpHost = $env:CPANEL_HOST
  $CpUser = $env:CPANEL_USER
  $Token = $null
  $sourcedToken = $null
  foreach ($cfg in @(
    (Join-Path $ftp 'config.cpanel.local.ps1'),
    (Join-Path $ftp 'config.local.ps1'),
    (Join-Path $ftp 'config.whm.local.ps1'),
    (Join-Path $ftp 'whm-api.ps1')
  )) {
    if (-not (Test-Path $cfg)) { continue }
    . $cfg
    if ($Token) { $sourcedToken = $Token }
    if (-not $CpTok) { $CpTok = $CpanelToken }
    if (-not $CpTok) { $CpTok = $WhmToken }
    if (-not $CpTok) { $CpTok = $CpanelApiToken }
    if (-not $CpTok) { $CpTok = $WhmApiToken }
    if (-not $CpTok) { $CpTok = $WHM_API_TOKEN }
    if (-not $CpHost) { $CpHost = $CpanelHost }
    if (-not $CpHost) { $CpHost = $WhmHost }
    if (-not $CpUser) { $CpUser = $CpanelUser }
  }
  if (-not $CpTok) { $CpTok = $sourcedToken }
  if (-not $CpHost) { $CpHost = '192.250.229.162' }
  if (-not $CpUser) { $CpUser = 'agency00' }
  if (-not $CpTok) {
    $hasWhm = [bool](Get-Command Invoke-WhmCpanel -ErrorAction SilentlyContinue)
    if ($hasWhm) {
      Write-Host 'WARN: Invoke-WhmCpanel is loaded so this laptop can Fileman, but no readable token for gh secret set. Hourly Actions stay skipped until $CpanelToken is in config.cpanel.local.ps1 or $env:CPANEL_TOKEN is set. Value not printed.'
    }
  }

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
      & gh workflow run put-120cash-cron.yml --repo $PagesRepo
      Write-Host 'Triggered github.io workflow put-120cash-cron (no token printed)'
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
