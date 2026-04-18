# Frees TCP port 3001 (typical stuck inventory API). Run from PowerShell:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
#   .\web\scripts\free-port-api.ps1

$port = 3001
$conns = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
if (-not $conns) {
    Write-Host "Nothing listening on port $port."
    exit 0
}
$conns | ForEach-Object {
    $procId = $_.OwningProcess
    try {
        $p = Get-Process -Id $procId -ErrorAction Stop
        Write-Host "Stopping PID $procId ($($p.ProcessName)) on port $port"
        Stop-Process -Id $procId -Force -ErrorAction Stop
    } catch {
        Write-Warning "Could not stop PID ${procId}: $_"
    }
}
Write-Host "Done. Run: cd web; npm run dev"
