# Fileman catalog index.html. Standalone (HubWatch / upload-120cash).
# agency002.com may only have a unique 120.cash/ ghost link (no cash_120 card).
# Presence / Printful / page_100 stay. Does not send mail.
# ping 20260908d: leftover stdin-only patch-*.py must wget argv UTF-8 files.
$ErrorActionPreference = 'Stop'
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'

$here = $PSScriptRoot
if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
$tokHelper = Join-Path $here 'night-door-token.ps1'
if (-not (Test-Path $tokHelper)) {
  $tokHelper = Join-Path $env:TEMP 'shift002-night-door-token.ps1'
  Invoke-WebRequest -Uri "$Drop/night-door-token.ps1" -OutFile $tokHelper -UseBasicParsing
}
. $tokHelper
if (-not $Token -and -not $NightDoorHasWhmHelper) {
  Write-Host 'No cPanel token. Skip catalog index Fileman.'
  exit 0
}
$localSave = Join-Path $here 'save-fileman.ps1'
$saveText = ''
if (Test-Path $localSave) { $saveText = Get-Content -Raw -Path $localSave }
if ($saveText -notmatch 'ran but status not 1') {
  Write-Host 'save-fileman.ps1 missing helper-proof. Fetching WHM-first pack a460b294.'
  $save = Join-Path $env:TEMP 'shift002-save-fileman.ps1'
  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/a460b294250a5530aa76f97a09c5e1714fd9540c/ftp-drop/save-fileman.ps1' -OutFile $save -UseBasicParsing
  . $save
} else {
  . $localSave
}

function Find-Python {
  # Windows Store python.exe is a stub that opens the Store. Prefer py -3.
  foreach ($name in @('py', 'python3', 'python')) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if (-not $cmd) { continue }
    if ([string]$cmd.Source -match 'WindowsApps') {
      Write-Host ("skip Windows Store python stub ({0})" -f $cmd.Source)
      continue
    }
    return $cmd
  }
  return $null
}

function Invoke-PythonPatch([string]$scriptName, [string]$html) {
  $py = Join-Path $here $scriptName
  $pyText = ''
  if (Test-Path $py) { $pyText = Get-Content -Raw -Path $py }
  if ($pyText -notmatch 'len\(sys.argv\)') {
    Write-Host ("local {0} leftover stdin-only. Fetching raw git argv UTF-8 files." -f $scriptName)
    $py = Join-Path $env:TEMP "shift002-$scriptName"
    Invoke-WebRequest -Uri "$Drop/$scriptName" -OutFile $py -UseBasicParsing
  }
  $python = Find-Python
  if (-not $python) {
    Write-Host "WARN: python3/python/py not on PATH. Skip $scriptName"
    return $null
  }
  $inFile = Join-Path $env:TEMP ("shift002-in-" + $scriptName + ".html")
  $outFile = Join-Path $env:TEMP ("shift002-out-" + $scriptName + ".html")
  $errFile = Join-Path $env:TEMP ("shift002-err-" + $scriptName + ".txt")
  $utf8 = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($inFile, $html, $utf8)
  if (Test-Path $outFile) { Remove-Item -Force $outFile }
  $oldEnc = $env:PYTHONIOENCODING
  $oldUtf = $env:PYTHONUTF8
  $env:PYTHONIOENCODING = 'utf-8'
  $env:PYTHONUTF8 = '1'
  $exitCode = 1
  try {
    if ($python.Name -match '^py(\.exe)?$') {
      & $python.Source -3 $py $inFile $outFile 2>$errFile
    } else {
      & $python.Source $py $inFile $outFile 2>$errFile
    }
    $exitCode = $LASTEXITCODE
    if ($null -eq $exitCode) { $exitCode = 0 }
  } finally {
    $env:PYTHONIOENCODING = $oldEnc
    $env:PYTHONUTF8 = $oldUtf
  }
  if (($null -ne $exitCode -and $exitCode -ne 0) -or -not (Test-Path $outFile) -or (Get-Item $outFile).Length -lt 80) {
    if (Test-Path $errFile) { Write-Host ("WARN {0}: {1}" -f $scriptName, ((Get-Content -Raw -Path $errFile) -replace '\s+', ' ').Trim()) }
    return $null
  }
  return [System.IO.File]::ReadAllText($outFile, $utf8)
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
