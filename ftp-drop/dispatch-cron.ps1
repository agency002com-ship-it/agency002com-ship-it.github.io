# After github.io secrets exist. No tokens printed. Safe to re-run.
$ErrorActionPreference = 'Continue'
$PagesRepo = 'agency002com-ship-it/agency002com-ship-it.github.io'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Host 'WARN: gh not on PATH. Skip put-120cash-cron'
  exit 0
}
try {
  & gh workflow run put-120cash-cron.yml --repo $PagesRepo
  Write-Host 'Triggered put-120cash-cron (no token printed)'
} catch {
  Write-Host ("WARN put-120cash-cron: {0}" -f $_.Exception.Message)
}
