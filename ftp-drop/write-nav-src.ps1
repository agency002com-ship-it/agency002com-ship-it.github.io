# Point unique catalog /assets/nav.js?v=2 (v=4 on 120.cash) at github.io night nav.
# One HTML needle. Does not rewrite product cards. Other prices stay.
$ErrorActionPreference = 'Stop'
$Pages = 'https://agency002com-ship-it.github.io'
$Drop = 'https://raw.githubusercontent.com/agency002com-ship-it/agency002com-ship-it.github.io/main/ftp-drop'
$NewSrc = 'src="https://agency002com-ship-it.github.io/ftp-drop/nav-night.js?v=20260907n"'

$ftpDir = Join-Path $env:USERPROFILE 'GrokWork\ftp'
foreach ($name in @('config.cpanel.local.ps1', 'config.local.ps1', 'whm-api.ps1')) {
  $p = Join-Path $ftpDir $name
  if (Test-Path $p) { . $p }
}

$User = $env:CPANEL_USER
if (-not $User) { $User = $CpanelUser }
if (-not $User) { $User = 'agency00' }
$Token = $env:CPANEL_TOKEN
if (-not $Token) { $Token = $CpanelToken }
if (-not $Token) { $Token = $WhmToken }
$Dir = $env:CPANEL_DIR
if (-not $Dir) { $Dir = $CpanelDir }
if (-not $Dir) { $Dir = "/home/$User/120.cash" }
$WhmUserName = $env:WHM_USER
if (-not $WhmUserName) { $WhmUserName = $WhmUser }
$HostName = $env:CPANEL_HOST
if (-not $HostName) { $HostName = $CpanelHost }
if (-not $HostName) { $HostName = $WhmHost }
if (-not $HostName) { $HostName = 'agency002.com' }
$HostNames = @($HostName, 'agency002.com', 'lemonpie.codes') |
  Where-Object { $_ } | Select-Object -Unique

if (-not $Token) {
  Write-Host 'No cPanel token. Skip nav src Fileman.'
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
  @{ Url = 'https://120.cash/'; Guard = 'cash_120'; Dirs = @($Dir, "/home/$User/public_html/120.cash") }
)
foreach ($t in $targets) {
  try {
    $liveHtml = (Invoke-WebRequest -Uri $t.Url -UseBasicParsing).Content
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
