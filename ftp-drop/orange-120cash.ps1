# Orange-cloud 120.cash and intercept GET / with the same-night page.
# Does not need Fileman. Uses GrokWork\ftp\config.cloudflare.local.ps1
# (laptop only — not in git). Does not touch keychain.gr. Does not send mail.
# Does not invent tokens. Does not replace the hello-world `grok` worker.
#
#   powershell -File orange-120cash.ps1

$ErrorActionPreference = 'Stop'
$ScriptName = 'shift002-120cash'
$IndexUrl = 'https://agency002com-ship-it.github.io/ftp-drop/120-index.html'

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

Write-Host 'Looking up Cloudflare zone 120.cash'
$zones = CfGet '/zones?name=120.cash'
$zone = $zones.result | Select-Object -First 1
if (-not $zone) {
  Write-Error 'No Cloudflare zone named 120.cash on this token. Fileman is still the origin path.'
}
$ZoneId = $zone.id
$AccountId = $zone.account.id
Write-Host ("zone={0} account={1}" -f $ZoneId, $AccountId)

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
$metaFile = Join-Path $env:TEMP 'shift002-worker-meta.json'
[System.IO.File]::WriteAllText($metaFile, '{"main_module":"worker.js","bindings":[],"compatibility_date":"2026-09-01"}', $utf8)

Write-Host "Uploading Worker $ScriptName (does not replace grok / grok-cf)"
$put = & curl.exe -sS -X PUT "https://api.cloudflare.com/client/v4/accounts/$AccountId/workers/scripts/$ScriptName" `
  -H "Authorization: Bearer $CfToken" `
  -F "worker.js=@$tmpJs;type=application/javascript+module" `
  -F "metadata=@$metaFile;type=application/json"
$putObj = $put | ConvertFrom-Json
if (-not $putObj.success) {
  Write-Error ("Worker upload failed: {0}" -f $put)
}
Write-Host 'Worker uploaded.'

$routes = CfGet "/zones/$ZoneId/workers/routes"
$want = @('120.cash/*', 'www.120.cash/*')
$have = @($routes.result | ForEach-Object { $_.pattern })
foreach ($pattern in $want) {
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

$dns = CfGet "/zones/$ZoneId/dns_records?type=A&name=120.cash"
foreach ($rec in @($dns.result)) {
  if ($rec.proxied -eq $true) {
    Write-Host ("A {0} already proxied" -f $rec.name)
    continue
  }
  try {
    CfJson 'PATCH' "/zones/$ZoneId/dns_records/$($rec.id)" @{
      proxied = $true
      type    = 'A'
      name    = $rec.name
      content = $rec.content
    }
    Write-Host ("Proxied A {0} -> {1}" -f $rec.name, $rec.content)
  } catch {
    Write-Host ("WARN DNS proxy {0}: {1}" -f $rec.name, $_.Exception.Message)
  }
}

$www = CfGet "/zones/$ZoneId/dns_records?name=www.120.cash"
foreach ($rec in @($www.result)) {
  if ($rec.proxied -eq $true) { continue }
  try {
    CfJson 'PATCH' "/zones/$ZoneId/dns_records/$($rec.id)" @{
      proxied = $true
      type    = $rec.type
      name    = $rec.name
      content = $rec.content
    }
    Write-Host ("Proxied {0} {1}" -f $rec.type, $rec.name)
  } catch {
    Write-Host ("WARN www proxy: {0}" -f $_.Exception.Message)
  }
}

Start-Sleep -Seconds 3
$live = Invoke-WebRequest -Uri 'https://120.cash/' -UseBasicParsing
if ($live.Content -notmatch 'one working day' -and $live.Content -match '#book') {
  Write-Host 'https://120.cash/ is brief then pay via Cloudflare Worker.'
} else {
  Write-Host 'WARN: 120.cash HTML not flipped yet (DNS/cache). Worker is uploaded. Fileman still needed for keychain cash_120.'
}
Write-Host 'Done. Origin /assets/ and brief-submit.php still pass through.'
