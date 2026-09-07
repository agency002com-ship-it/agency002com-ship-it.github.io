# DOT this from script scope (do not &-invoke). Sets $Token without wiping a
# sourced whm-api.ps1 $Token via empty $env:CPANEL_TOKEN.
# Never echoes token values. Never invents passwords.
$ftpDir = Join-Path $env:USERPROFILE 'GrokWork\ftp'
$sourcedToken = $null
if ($Token) { $sourcedToken = $Token }
foreach ($name in @(
  'config.cpanel.local.ps1',
  'config.local.ps1',
  'config.whm.local.ps1',
  'whm-api.ps1'
)) {
  $p = Join-Path $ftpDir $name
  if (Test-Path $p) { . $p }
}
if ($Token) { $sourcedToken = $Token }

$HostName = $env:CPANEL_HOST
if (-not $HostName) { $HostName = $CpanelHost }
if (-not $HostName) { $HostName = $WhmHost }
if (-not $HostName) { $HostName = '192.250.229.162' }

$User = $env:CPANEL_USER
if (-not $User) { $User = $CpanelUser }
if (-not $User) { $User = 'agency00' }

$fromEnv = $env:CPANEL_TOKEN
if (-not $fromEnv) { $fromEnv = $env:CPANEL_API_TOKEN }
if (-not $fromEnv) { $fromEnv = $env:WHM_API_TOKEN }
if (-not $fromEnv) { $fromEnv = $env:WHM_TOKEN }

$Token = $fromEnv
if (-not $Token) { $Token = $CpanelToken }
if (-not $Token) { $Token = $WhmToken }
if (-not $Token) { $Token = $CpanelApiToken }
if (-not $Token) { $Token = $WhmApiToken }
if (-not $Token) { $Token = $WHM_API_TOKEN }
if (-not $Token) { $Token = $sourcedToken }

$Dir = $env:CPANEL_DIR
if (-not $Dir) { $Dir = $CpanelDir }
if (-not $Dir) { $Dir = "/home/$User/domains/120.cash/public_html" }
$WhmUserName = $env:WHM_USER
if (-not $WhmUserName) { $WhmUserName = $WhmUser }
$HostNames = @($HostName, '192.250.229.162', 'agency002.com', 'lemonpie.codes') |
  Where-Object { $_ } | Select-Object -Unique

$NightDoorHasWhmHelper = $false
foreach ($cmd in @('Invoke-WhmCpanel', 'Save-CpanelFile', 'Invoke-CpanelUapi')) {
  if (Get-Command -Name $cmd -ErrorAction SilentlyContinue) {
    $NightDoorHasWhmHelper = $true
    break
  }
}

if (-not $Token -and $NightDoorHasWhmHelper) {
  Write-Host 'WARN: Invoke-WhmCpanel is loaded so this laptop can Fileman, but no readable token for gh secret set. Hourly Actions stay skipped until $CpanelToken is in config.cpanel.local.ps1 or $env:CPANEL_TOKEN is set. Value not printed.'
}
