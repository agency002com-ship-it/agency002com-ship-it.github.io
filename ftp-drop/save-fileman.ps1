# Dot-sourced by upload-120cash.ps1. Uses $User, $Token, $HostName, $WhmUserName.
# Addon-domain FTP returns 553. WHM :2087 Fileman first (known-good), then :2083.
# Laptop helpers (Invoke-WhmCpanel) must prove status=1. A silent no-op used to
# skip WHM and leave catalogs on the 120-byte nav.js year stamp.

$HostNames = @($HostNames + @($HostName, '192.250.229.162', 'agency002.com', 'lemonpie.codes')) |
  Where-Object { $_ } | Select-Object -Unique

function Test-FilemanOk($res) {
  if ($null -eq $res) { return $false }
  if ($res -is [string]) {
    try { $res = $res | ConvertFrom-Json } catch { return $false }
  }
  if ($null -ne $res.status) {
    return ([int]$res.status -eq 1)
  }
  $ev = $null
  if ($res.cpanelresult -and $res.cpanelresult.event) {
    $ev = $res.cpanelresult.event.result
  }
  if ($null -ne $ev) { return ([int]$ev -eq 1) }
  $meta = $null
  if ($res.metadata) { $meta = $res.metadata.result }
  if ($null -ne $meta) { return ([int]$meta -eq 1) }
  if ($res.errors) { return $false }
  return $true
}

function Save-Fileman([string]$directory, [string]$file, [string]$content) {
  Write-Host "Writing $directory/$file via Fileman"
  $body2083 = @{
    dir     = $directory
    file    = $file
    content = $content
    charset = 'utf-8'
  }
  $errors = @()

  foreach ($cmd in @('Invoke-WhmCpanel', 'Save-CpanelFile', 'Invoke-CpanelUapi')) {
    if (Get-Command -Name $cmd -ErrorAction SilentlyContinue) {
      try {
        $res = $null
        if ($cmd -eq 'Invoke-WhmCpanel') {
          $res = & $cmd -Module Fileman -Function save_file_content -User $User -Params $body2083
        } elseif ($cmd -eq 'Save-CpanelFile') {
          $res = & $cmd -Dir $directory -File $file -Content $content
        } else {
          $res = & $cmd -Module Fileman -Function save_file_content -Args $body2083
        }
        if (Test-FilemanOk $res) {
          Write-Host ("Fileman helper {0} {1}/{2}" -f $cmd, $directory, $file)
          return
        }
        $errors += "${cmd}: ran but status not 1"
      } catch {
        $errors += "${cmd}: $($_.Exception.Message)"
      }
    }
  }

  # Known-good path: WHM :2087 Fileman::save_file_content (addon FTP is 553).
  $whmUsers = @($WhmUserName, $User, 'root') | Where-Object { $_ } | Select-Object -Unique
  foreach ($h in $HostNames) {
    foreach ($wu in $whmUsers) {
      try {
        $uri = ('https://{0}:2087/json-api/cpanel' -f $h)
        $body = @{
          cpanel_jsonapi_user      = $User
          cpanel_jsonapi_apimodule = 'Fileman'
          cpanel_jsonapi_apifunc   = 'save_file_content'
          cpanel_jsonapi_version   = 2
          dir                      = $directory
          file                     = $file
          content                  = $content
          charset                  = 'utf-8'
        }
        $res = Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = ('WHM {0}:{1}' -f $wu, $Token) } -Body $body -SkipCertificateCheck
        if (Test-FilemanOk $res) {
          Write-Host ("Fileman :2087 WHM {0} {1}/{2}" -f $wu, $directory, $file)
          return
        }
        $errors += "2087/$h/$wu: HTTP ok but status not 1"
      } catch { $errors += "2087/$h/$wu: $($_.Exception.Message)" }
    }
  }

  foreach ($h in $HostNames) {
    $pair = '{0}:{1}' -f $User, $Token
    $basic = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
    try {
      $uri = ('https://{0}:2083/execute/Fileman/save_file_content' -f $h)
      $res = Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = $basic } -Body $body2083 -SkipCertificateCheck
      if (Test-FilemanOk $res) {
        Write-Host ("Fileman :2083 basic {0}/{1}" -f $directory, $file)
        return
      }
      $errors += "2083/$h basic: HTTP ok but status not 1"
    } catch { $errors += "2083/$h basic: $($_.Exception.Message)" }
    try {
      $uri = ('https://{0}:2083/execute/Fileman/save_file_content' -f $h)
      $res = Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = ('cpanel {0}:{1}' -f $User, $Token) } -Body $body2083 -SkipCertificateCheck
      if (Test-FilemanOk $res) {
        Write-Host ("Fileman :2083 cpanel {0}/{1}" -f $directory, $file)
        return
      }
      $errors += "2083/$h cpanel: HTTP ok but status not 1"
    } catch { $errors += "2083/$h cpanel: $($_.Exception.Message)" }
  }

  throw ('Fileman failed. ' + ($errors -join ' | '))
}
