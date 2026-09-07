# Read laptop Cloudflare/cPanel tokens from disk. Set github.io Actions secrets.
# Then dispatch put-120cash-cron so Fileman continues after sleep.
# Never echo token values. Safe to re-run. Missing gh or files → warn, exit 0.
$ErrorActionPreference = 'Continue'
$PagesRepo = 'agency002com-ship-it/agency002com-ship-it.github.io'
$ftp = Join-Path $env:USERPROFILE 'GrokWork\ftp'

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

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Host 'WARN: gh not on PATH. Skip github.io secrets.'
  exit 0
}

function Set-NightDoorSecret([string]$Name, [string]$Value) {
  if (-not $Value) { return }
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

try {
  & gh workflow run put-120cash.yml --repo $PagesRepo
  Write-Host 'Triggered put-120cash (no token printed)'
  & gh workflow run put-120cash-cron.yml --repo $PagesRepo
  Write-Host 'Triggered put-120cash-cron (no token printed)'
} catch {
  Write-Host ("WARN workflow run: {0}" -f $_.Exception.Message)
}
