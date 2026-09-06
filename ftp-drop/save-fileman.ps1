# Dot-sourced by upload-120cash.ps1. Uses $User, $Token, $HostName, $WhmUserName.
# Addon-domain FTP returns 553. Try cPanel :2083, then WHM :2087 passthrough.

if (-not $HostNames) {
  $HostNames = @($HostName, 'agency002.com', 'lemonpie.codes') |
    Where-Object { $_ } | Select-Object -Unique
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
        if ($cmd -eq 'Invoke-WhmCpanel') {
          & $cmd -Module Fileman -Function save_file_content -User $User -Params $body2083
        } elseif ($cmd -eq 'Save-CpanelFile') {
          & $cmd -Dir $directory -File $file -Content $content
        } else {
          & $cmd -Module Fileman -Function save_file_content -Args $body2083
        }
        return
      } catch {
        $errors += "${cmd}: $($_.Exception.Message)"
      }
    }
  }

  foreach ($h in $HostNames) {
    $pair = '{0}:{1}' -f $User, $Token
    $basic = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
    try {
      $uri = ('https://{0}:2083/execute/Fileman/save_file_content' -f $h)
      Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = $basic } -Body $body2083 -SkipCertificateCheck
      return
    } catch { $errors += "2083/$h basic: $($_.Exception.Message)" }
    try {
      $uri = ('https://{0}:2083/execute/Fileman/save_file_content' -f $h)
      Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = ('cpanel {0}:{1}' -f $User, $Token) } -Body $body2083 -SkipCertificateCheck
      return
    } catch { $errors += "2083/$h cpanel: $($_.Exception.Message)" }
  }

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
        Invoke-RestMethod -Method Post -Uri $uri -Headers @{ Authorization = ('WHM {0}:{1}' -f $wu, $Token) } -Body $body -SkipCertificateCheck
        return
      } catch { $errors += "2087/$h/$wu: $($_.Exception.Message)" }
    }
  }

  throw ('Fileman failed. ' + ($errors -join ' | '))
}
