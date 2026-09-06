# Orange-cloud 120.cash and keychain.gr so existing grok-cf routes receive traffic.
# grok-cf already intercepts 120.cash / www / tonight / now / live / book and keychain pay.html.
# DNS proxy is the unlock. New workers are a fallback only.
# Uses GrokWork\ftp\config.cloudflare.local.ps1 (laptop only — not in git).
# Does not replace Workers grok / grok-cf. Does not invent tokens. Does not send mail.
#
#   powershell -File orange-120cash.ps1

$ErrorActionPreference = 'Stop'
$Pages = 'https://agency002com-ship-it.github.io/ftp-drop'

$ftpDir = Join-Path $env:USERPROFILE 'GrokWork\ftp'
foreach ($name in @(
  'config.cloudflare.local.ps1',
  'config.cf.local.ps1',
  'config.local.ps1'
)) {
  $p = Join-Path $ftpDir $name
  if (Test-Path $p) { . $p }
}

$CfToken = $env:CLOUDFLARE_API_TOKEN
if (-not $CfToken) { $CfToken = $CloudflareToken }
if (-not $CfToken) { $CfToken = $CfApiToken }
if (-not $CfToken) { $CfToken = $CF_API_TOKEN }
if (-not $CfToken) { $CfToken = $ApiToken }

if (-not $CfToken) {
  Write-Error @"
No Cloudflare token in this session.
Dot-source GrokWork\ftp\config.cloudflare.local.ps1 (already on the laptop),
or set CLOUDFLARE_API_TOKEN. Do not invent a password.
"@
}

$Headers = @{
  Authorization = "Bearer $CfToken"
  'Content-Type' = 'application/json'
}

function CfGet([string]$path) {
  Invoke-RestMethod -Method Get -Uri "https://api.cloudflare.com/client/v4$path" -Headers @{ Authorization = "Bearer $CfToken" }
}
function CfJson([string]$method, [string]$path, $body) {
  $json = if ($null -eq $body) { $null } else { ($body | ConvertTo-Json -Compress -Depth 8) }
  Invoke-RestMethod -Method $method -Uri "https://api.cloudflare.com/client/v4$path" -Headers $Headers -Body $json
}

function Get-DropFile([string]$name) {
  $here = $PSScriptRoot
  if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
  $local = Join-Path $here $name
  if ($here -and (Test-Path $local)) { return $local }
  $tmp = Join-Path $env:TEMP $name
  Invoke-WebRequest -Uri "$Pages/$name" -OutFile $tmp -UseBasicParsing
  return $tmp
}

function Publish-Worker([string]$AccountId, [string]$ScriptName, [string]$JsPath) {
  Write-Host "Uploading Worker $ScriptName (does not replace grok / grok-cf)"
  $metaFile = Join-Path $env:TEMP "shift002-$ScriptName-meta.json"
  $utf8 = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($metaFile, '{"main_module":"worker.js","bindings":[],"compatibility_date":"2026-09-01"}', $utf8)
  $put = & curl.exe -sS -X PUT "https://api.cloudflare.com/client/v4/accounts/$AccountId/workers/scripts/$ScriptName" `
    -H "Authorization: Bearer $CfToken" `
    -F "worker.js=@$JsPath;type=application/javascript+module" `
    -F "metadata=@$metaFile;type=application/json"
  $putObj = $put | ConvertFrom-Json
  if (-not $putObj.success) {
    Write-Host ("WARN Worker upload ${ScriptName}: {0}" -f $put)
    return $false
  }
  Write-Host "Worker $ScriptName uploaded."
  return $true
}

function Ensure-Routes([string]$ZoneId, [string]$ScriptName, [string[]]$Want) {
  $routes = CfGet "/zones/$ZoneId/workers/routes"
  $have = @($routes.result | ForEach-Object { $_.pattern })
  foreach ($pattern in $Want) {
    if ($have -contains $pattern) {
      Write-Host "Route already present: $pattern"
      continue
    }
    try {
      CfJson 'POST' "/zones/$ZoneId/workers/routes" @{ pattern = $pattern; script = $ScriptName }
      Write-Host "Added route $pattern -> $ScriptName"
    } catch {
      Write-Host ("WARN route ${pattern}: {0}" -f $_.Exception.Message)
    }
  }
}

function Proxy-DnsName([string]$ZoneId, [string]$Name) {
  try {
    $dns = CfGet "/zones/$ZoneId/dns_records?name=$Name"
  } catch {
    Write-Host ("WARN DNS list {0}: {1}" -f $Name, $_.Exception.Message)
    return
  }
  foreach ($rec in @($dns.result)) {
    if ($rec.type -notin @('A', 'AAAA', 'CNAME')) { continue }
    if ($rec.proxied -eq $true) {
      Write-Host ("{0} {1} already proxied" -f $rec.type, $rec.name)
      continue
    }
    try {
      CfJson 'PATCH' "/zones/$ZoneId/dns_records/$($rec.id)" @{
        proxied = $true
        type    = $rec.type
        name    = $rec.name
        content = $rec.content
      }
      Write-Host ("Proxied {0} {1}" -f $rec.type, $rec.name)
    } catch {
      Write-Host ("WARN DNS proxy {0}: {1}" -f $rec.name, $_.Exception.Message)
    }
  }
}

function Get-Zone([string]$ZoneName) {
  try {
    $zones = CfGet "/zones?name=$ZoneName"
    return $zones.result | Select-Object -First 1
  } catch {
    Write-Host ("WARN zone {0}: {1}" -f $ZoneName, $_.Exception.Message)
    return $null
  }
}

function Test-CashNight {
  try {
    $html = (Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing).Content
    return ($html -notmatch 'one working day' -and $html -match '#book')
  } catch { return $false }
}

function Test-PayNight {
  try {
    $html = (Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing).Content
    return ($html -match [regex]::Escape('github.io/paid.html') -and $html -notmatch [regex]::Escape("a('https://120.cash/#brief', '120.cash');"))
  } catch { return $false }
}

# 1. Orange DNS first. grok-cf already intercepts these hostnames when traffic hits Cloudflare.
$cashZone = Get-Zone '120.cash'
if ($cashZone) {
  Write-Host 'Orange-cloud 120.cash DNS (do not replace grok-cf).'
  Proxy-DnsName $cashZone.id '120.cash'
  Proxy-DnsName $cashZone.id 'www.120.cash'
} else {
  Write-Host 'No Cloudflare zone named 120.cash on this token.'
}

$keyZone = Get-Zone 'keychain.gr'
if ($keyZone) {
  Write-Host 'Orange-cloud keychain.gr DNS (do not replace grok-cf).'
  Proxy-DnsName $keyZone.id 'keychain.gr'
  Proxy-DnsName $keyZone.id 'www.keychain.gr'
} else {
  Write-Host 'No Cloudflare zone named keychain.gr on this token.'
}

Start-Sleep -Seconds 5
$cashOk = Test-CashNight
$payOk = Test-PayNight
if ($cashOk) { Write-Host 'https://120.cash/ is brief then pay (grok-cf / orange DNS).' }
if ($payOk) { Write-Host 'https://keychain.gr/pay.html cash_120 returns to paid.html.' }

# 2. Fallback workers only if DNS orange did not flip the live HTML.
# orange-worker.js talks to origin IP so /assets/ does not loop.
if (-not $cashOk -and $cashZone) {
  Write-Host '120.cash still wait-a-day after DNS. Fallback Worker shift002-120cash (origin IP, not grok-cf).'
  $js = Get-DropFile 'orange-worker.js'
  if (Publish-Worker $cashZone.account.id 'shift002-120cash' $js) {
    Ensure-Routes $cashZone.id 'shift002-120cash' @('120.cash/*', 'www.120.cash/*')
  }
  Proxy-DnsName $cashZone.id '120.cash'
  Proxy-DnsName $cashZone.id 'www.120.cash'
}

if (-not $payOk -and $keyZone) {
  Write-Host 'keychain still old cash_120 bounce after DNS. Fallback Worker shift002-keychain.'
  $kcJs = Get-DropFile 'orange-keychain-worker.js'
  if (Publish-Worker $keyZone.account.id 'shift002-keychain' $kcJs) {
    Ensure-Routes $keyZone.id 'shift002-keychain' @('keychain.gr/pay.html*', 'www.keychain.gr/pay.html*')
  }
  Proxy-DnsName $keyZone.id 'keychain.gr'
  Proxy-DnsName $keyZone.id 'www.keychain.gr'
}

Start-Sleep -Seconds 3
if (Test-CashNight) { Write-Host 'https://120.cash/ is brief then pay via Cloudflare.' }
else { Write-Host 'WARN: 120.cash HTML not flipped yet (DNS/cache or token lacks Zone DNS Edit).' }
if (Test-PayNight) { Write-Host 'https://keychain.gr/pay.html cash_120 now returns to paid.html.' }
else { Write-Host 'WARN: keychain cash_120 bounce not flipped yet (DNS/cache or zone token).' }
Write-Host 'Done. Origin /assets/, /api/, and other keychain plans still pass through.'
