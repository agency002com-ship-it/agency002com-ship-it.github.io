# Orange-cloud 120.cash (same-night homepage) and keychain.gr/pay.html (cash_120).
# Uses GrokWork\ftp\config.cloudflare.local.ps1 (laptop only — not in git).
# Does not replace Workers grok / grok-cf. Does not invent tokens. Does not send mail.
#
#   powershell -File orange-120cash.ps1

$ErrorActionPreference = 'Stop'
$Pages = 'https://agency002com-ship-it.github.io/ftp-drop'
$IndexUrl = "$Pages/120-index.html"

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
  $dns = CfGet "/zones/$ZoneId/dns_records?name=$Name"
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

# --- 120.cash homepage ---
$cash = ''
try { $cash = (Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing).Content } catch { }
if ($cash -notmatch 'one working day' -and $cash -match '#book') {
  Write-Host '120.cash already same-night. Skip homepage Worker.'
} else {
  Write-Host 'Looking up Cloudflare zone 120.cash'
  try {
    $zones = CfGet '/zones?name=120.cash'
    $zone = $zones.result | Select-Object -First 1
  } catch {
    $zone = $null
    Write-Host ("WARN 120.cash zone: {0}" -f $_.Exception.Message)
  }
  if (-not $zone) {
    Write-Host 'No Cloudflare zone named 120.cash on this token.'
  } else {
    $worker = @"
export default {
  async fetch(request) {
    const url = new URL(request.url);
    if (request.method === 'GET' && (url.pathname === '/' || url.pathname === '/index.html')) {
      const src = await fetch('$IndexUrl', { cf: { cacheTtl: 30 } });
      const html = await src.text();
      return new Response(html, {
        headers: {
          'content-type': 'text/html; charset=utf-8',
          'cache-control': 'no-store',
          'x-shift002': 'orange'
        }
      });
    }
    return fetch(request);
  }
}
"@
    $tmpJs = Join-Path $env:TEMP 'shift002-120cash-worker.js'
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($tmpJs, $worker, $utf8)
    if (Publish-Worker $zone.account.id 'shift002-120cash' $tmpJs) {
      Ensure-Routes $zone.id 'shift002-120cash' @('120.cash/*', 'www.120.cash/*')
      Proxy-DnsName $zone.id '120.cash'
      Proxy-DnsName $zone.id 'www.120.cash'
    }
  }
}

# --- keychain.gr/pay.html (same CF account, grey-cloud today) ---
$pay = ''
try { $pay = (Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing).Content } catch { }
$payDone = ($pay -match [regex]::Escape('github.io/paid.html') -and $pay -notmatch [regex]::Escape("a('https://120.cash/#brief', '120.cash');"))
if ($payDone) {
  Write-Host 'keychain cash_120 already returns to paid.html. Skip pay.html Worker.'
} else {
  Write-Host 'Looking up Cloudflare zone keychain.gr'
  try {
    $kz = CfGet '/zones?name=keychain.gr'
    $kzone = $kz.result | Select-Object -First 1
  } catch {
    $kzone = $null
    Write-Host ("WARN keychain.gr zone: {0}" -f $_.Exception.Message)
  }
  if (-not $kzone) {
    Write-Host 'No Cloudflare zone named keychain.gr on this token. Fileman still needed for the till.'
  } else {
    $kcJs = Get-DropFile 'orange-keychain-worker.js'
    if (Publish-Worker $kzone.account.id 'shift002-keychain' $kcJs) {
      Ensure-Routes $kzone.id 'shift002-keychain' @('keychain.gr/pay.html*', 'www.keychain.gr/pay.html*')
      Proxy-DnsName $kzone.id 'keychain.gr'
      Proxy-DnsName $kzone.id 'www.keychain.gr'
    }
  }
}

Start-Sleep -Seconds 3
try {
  $live = (Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing).Content
  if ($live -notmatch 'one working day' -and $live -match '#book') {
    Write-Host 'https://120.cash/ is brief then pay via Cloudflare Worker.'
  } else {
    Write-Host 'WARN: 120.cash HTML not flipped yet (DNS/cache).'
  }
} catch { Write-Host ("WARN 120.cash check: {0}" -f $_.Exception.Message) }
try {
  $khtml = (Invoke-WebRequest -Uri 'https://keychain.gr/pay.html' -UseBasicParsing).Content
  if ($khtml -match [regex]::Escape('github.io/paid.html') -and $khtml -notmatch [regex]::Escape("a('https://120.cash/#brief', '120.cash');")) {
    Write-Host 'https://keychain.gr/pay.html cash_120 now returns to paid.html.'
  } else {
    Write-Host 'WARN: keychain cash_120 bounce not flipped yet (DNS/cache or zone token).'
  }
} catch { Write-Host ("WARN keychain check: {0}" -f $_.Exception.Message) }
Write-Host 'Done. Origin /assets/, /api/, and other keychain plans still pass through.'
