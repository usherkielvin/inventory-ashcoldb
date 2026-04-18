# Optional: two separate windows instead of `npm run dev` at web root.
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Start-Process powershell -WorkingDirectory $root -ArgumentList @(
    '-NoExit', '-NoProfile', '-Command',
    "Set-Location '$root\server'; npm run dev"
)
Start-Sleep -Seconds 2
Start-Process powershell -WorkingDirectory $root -ArgumentList @(
    '-NoExit', '-NoProfile', '-Command',
    "Set-Location '$root\client'; npm run dev"
)
Write-Host 'Started API (server) and UI (client) in new windows. API: http://localhost:3001  UI: http://localhost:5174' -ForegroundColor Green
