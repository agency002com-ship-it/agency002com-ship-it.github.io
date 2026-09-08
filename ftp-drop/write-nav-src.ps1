# Point unique catalog /assets/nav.js?v=2 (v=4 on 120.cash) at github.io night nav.
# One HTML needle. Does not rewrite product cards. Other prices stay.
$ErrorActionPreference = 'Stop'
$Pages = 'https://agency002com-ship-it.github.io'
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'
$NewSrc = 'src="https://agency002com-ship-it.github.io/ftp-drop/nav-night.js?v=20260907s"'

$here = $PSScriptRoot
if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
$tokHelper = Join-Path $here 'night-door-token.ps1'
if (-not (Test-Path $tokHelper)) {
  $tokHelper = Join-Path $env:TEMP 'shift002-night-door-token.ps1'
  Invoke-WebRequest -Uri "$Drop/night-door-token.ps1" -OutFile $tokHelper -UseBasicParsing
}
. $tokHelper
if (-not $Token -and -not $NightDoorHasWhmHelper) {
  Write-Host 'No cPanel token. Skip nav src Fileman.'
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

function Update-NavSrc([string]$content) {
  if ($content.Contains($NewSrc)) { return $content }
  foreach ($old in @('src="/assets/nav.js?v=2"', 'src="/assets/nav.js?v=4"')) {
    $n = ([regex]::Matches($content, [regex]::Escape($old))).Count
    if ($n -eq 1) { return $content.Replace($old, $NewSrc) }
  }
  return $content
}

$targets = @(
  @{ Url = 'https://eidotevil.com/'; Guard = 'page_100'; Dirs = @("/home/$User/eidotevil.com", "/home/$User/public_html/eidotevil.com", "/home/$User/domains/eidotevil.com/public_html") },
  @{ Url = 'https://agency002.com/'; Guard = 'eidotevil.com'; Dirs = @("/home/$User/public_html", "/home/$User/agency002.com", "/home/$User/public_html/agency002.com") },
  @{ Url = 'https://sebarv.com/'; Guard = 'pay.html?plan=sitepilot'; Dirs = @("/home/$User/sebarv.com", "/home/$User/public_html/sebarv.com", "/home/$User/domains/sebarv.com/public_html") },
  @{ Url = 'https://120.cash/'; Guard = 'cash_120'; Dirs = @($Dir, "/home/$User/public_html/120.cash", "/home/$User/domains/120.cash/public_html") }
)
foreach ($t in $targets) {
  try {
    $liveHtml = (Invoke-WebRequest -Uri $t.Url -UseBasicParsing).Content
    if ($t.Url -eq 'https://120.cash/' -and ($liveHtml -match 'one working day' -or $liveHtml -notmatch '#book')) {
      Write-Host 'Skip nav-src Fileman of wait-a-day 120.cash; upload-120cash writes 120-index.html onto the addon docroot.'
      continue
    }
    $patched = Update-NavSrc $liveHtml
    if ($patched -eq $liveHtml) {
      if ($liveHtml.Contains('ftp-drop/nav-night.js')) {
        Write-Host ("OK {0} already loads github.io night nav." -f $t.Url)
      } else {
        Write-Host ("WARN {0} nav.js src not unique; left origin tag." -f $t.Url)
      }
      continue
    }
    if ($patched -notmatch [regex]::Escape($t.Guard)) {
      Write-Host ("WARN {0} nav src rewrite would drop {1}. Skip." -f $t.Url, $t.Guard)
      continue
    }
    foreach ($d in $t.Dirs) {
      try {
        Save-Fileman $d 'index.html' $patched
      } catch {
        Write-Host ("skip {0}: {1}" -f $d, $_.Exception.Message)
        continue
      }
      Start-Sleep -Seconds 2
      $check = (Invoke-WebRequest -Uri $t.Url -UseBasicParsing).Content
      if ($check.Contains('ftp-drop/nav-night.js') -and $check -match [regex]::Escape($t.Guard)) {
        Write-Host ("OK {0} now loads night nav. Other products stay." -f $t.Url)
        break
      }
    }
  } catch {
    Write-Host ("WARN nav src {0}: {1}" -f $t.Url, $_.Exception.Message)
  }
}
