[CmdletBinding()]
param()

$repoRoot = "C:\CamV4\CamFix"

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "    Stopping CamFix Server & Tunnel     " -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# 1. Stop Cloudflare Tunnel
Write-Host "`n[1/2] Stopping Cloudflare Tunnel..." -ForegroundColor Gray
$tunnelProc = Get-Process cloudflared -ErrorAction SilentlyContinue
if ($tunnelProc) {
    Stop-Process -Name cloudflared -Force -ErrorAction SilentlyContinue
    Write-Host "  Cloudflare Tunnel stopped." -ForegroundColor Green
} else {
    Write-Host "  Cloudflare Tunnel was not running." -ForegroundColor Gray
}

# 2. Stop Docker Containers
Write-Host "`n[2/2] Stopping Docker Containers..." -ForegroundColor Gray
Set-Location $repoRoot
docker compose down
Write-Host "  Docker containers stopped." -ForegroundColor Green

Write-Host "`nServer and Tunnel are completely stopped.`n" -ForegroundColor Yellow

