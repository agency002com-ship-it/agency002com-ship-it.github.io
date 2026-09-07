# Fileman catalog index.html. Standalone (HubWatch / upload-120cash).
# agency002.com may only have a unique 120.cash/ ghost link (no cash_120 card).
# Presence / Printful / page_100 stay. Does not send mail.
$ErrorActionPreference = 'Stop'
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'

$ftpDir = Join-Path $env:USERPROFILE 'GrokWork\ftp'
foreach ($name in @('config.cpanel.local.ps1', 'config.local.ps1', 'whm-api.ps1')) {
  $p = Join-Path $ftpDir $name
  if (Test-Path $p) { . $p }
}

$HostName = $env:CPANEL_HOST
if (-not $HostName) { $HostName = $CpanelHost }
if (-not $HostName) { $HostName = $WhmHost }
if (-not $HostName) { $HostName = '192.250.229.162' }
$User = $env:CPANEL_USER
if (-not $User) { $User = $CpanelUser }
if (-not $User) { $User = 'agency00' }
$Token = $env:CPANEL_TOKEN
if (-not $Token) { $Token = $CpanelToken }
if (-not $Token) { $Token = $WhmToken }
$WhmUserName = $env:WHM_USER
if (-not $WhmUserName) { $WhmUserName = $WhmUser }
$HostNames = @($HostName, '192.250.229.162', 'agency002.com', 'lemonpie.codes') |
  Where-Object { $_ } | Select-Object -Unique

if (-not $Token) {
  Write-Host 'No cPanel token. Skip catalog index Fileman.'
  exit 0
}

$here = $PSScriptRoot
if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
$localSave = Join-Path $here 'save-fileman.ps1'
if (Test-Path $localSave) {
  . $localSave
} else {
  $save = Join-Path $env:TEMP 'shift002-save-fileman.ps1'
  Invoke-WebRequest -Uri "$Drop/save-fileman.ps1" -OutFile $save -UseBasicParsing
  . $save
}

function Invoke-PythonPatch([string]$scriptName, [string]$html) {
  $py = Join-Path $here $scriptName
  if (-not (Test-Path $py)) {
    $py = Join-Path $env:TEMP "shift002-$scriptName"
    Invoke-WebRequest -Uri "$Drop/$scriptName" -OutFile $py -UseBasicParsing
  }
  $python = Get-Command python3 -ErrorAction SilentlyContinue
  if (-not $python) { $python = Get-Command python -ErrorAction SilentlyContinue }
  if (-not $python) {
    Write-Host "WARN: python3/python not on PATH. Skip $scriptName"
    return $null
  }
  $inFile = Join-Path $env:TEMP ("shift002-in-" + $scriptName + ".html")
  $outFile = Join-Path $env:TEMP ("shift002-out-" + $scriptName + ".html")
  $errFile = Join-Path $env:TEMP ("shift002-err-" + $scriptName + ".txt")
  [System.IO.File]::WriteAllText($inFile, $html)
  $p = Start-Process -FilePath $python.Source -ArgumentList @($py) -RedirectStandardInput $inFile -RedirectStandardOutput $outFile -RedirectStandardError $errFile -Wait -PassThru -NoNewWindow
  if ($p.ExitCode -ne 0 -or -not (Test-Path $outFile)) { return $null }
  return [System.IO.File]::ReadAllText($outFile)
}

function Write-CatalogIndex([string]$hostName, [string]$scriptName, [string[]]$dirs) {
  $page = ''
  try { $page = (Invoke-WebRequest -Uri ("https://{0}/" -f $hostName) -UseBasicParsing).Content } catch {
    Write-Host ("WARN fetch {0}: {1}" -f $hostName, $_.Exception.Message)
    return
  }
  if ($page -match 'tonight.agency002.com') {
    Write-Host ("{0} already points at the night till." -f $hostName)
    return
  }
  $patched = $null
  try { $patched = Invoke-PythonPatch $scriptName $page } catch {
    Write-Host ("WARN {0} patch: {1}" -f $hostName, $_.Exception.Message)
  }
  if (-not $patched -or $patched -notmatch 'tonight.agency002.com') {
    Write-Host ("WARN: {0} needles not unique. Skip index write." -f $hostName)
    return
  }
  if ($patched -notmatch 'pay.html\?plan=presence') {
    Write-Host ("WARN: {0} patch would drop another product. Skip." -f $hostName)
    return
  }
  foreach ($d in $dirs) {
    try { Save-Fileman $d 'index.html' $patched } catch {
      Write-Host ("skip {0}: {1}" -f $d, $_.Exception.Message)
    }
  }
}

Write-Host 'Patching catalog index.html (agency002 may only have a 120.cash/ ghost link). Presence/Printful stay.'
Write-CatalogIndex 'agency002.com' 'patch-agency.py' @(
  "/home/$User/public_html",
  "/home/$User/agency002.com",
  "/home/$User/public_html/agency002.com"
)
Write-CatalogIndex 'eidotevil.com' 'patch-eidotevil.py' @(
  "/home/$User/eidotevil.com",
  "/home/$User/public_html/eidotevil.com",
  "/home/$User/domains/eidotevil.com/public_html"
)
Write-CatalogIndex 'sebarv.com' 'patch-sebarv.py' @(
  "/home/$User/sebarv.com",
  "/home/$User/public_html/sebarv.com",
  "/home/$User/domains/sebarv.com/public_html"
)
