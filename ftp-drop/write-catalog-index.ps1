# Fileman catalog index.html. agency002.com may only have a unique 120.cash/
# ghost link (no cash_120 card). Presence / Printful / page_100 stay.
# Dot-sourced from upload-120cash.ps1 (needs Invoke-PythonPatch + Save-Fileman).

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
