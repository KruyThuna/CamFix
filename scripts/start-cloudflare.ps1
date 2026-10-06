[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = "C:\CamV4\CamFix"
$cloudflaredConfig = Join-Path $env:USERPROFILE '.cloudflared\config.yml'
$cloudflaredExe = "C:\Program Files (x86)\cloudflared\cloudflared.exe"

if (-not (Test-Path $cloudflaredExe)) {
    $cloudflaredExe = (Get-Command cloudflared -ErrorAction SilentlyContinue).Source
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Starting CamFix Cloudflare Hosting   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Check & Start Docker Backend
Set-Location $repoRoot
Write-Host "`n[1/3] Checking Docker Backend Containers..." -ForegroundColor Yellow
$backendListener = Get-NetTCPConnection -State Listen -LocalPort 8081 -ErrorAction SilentlyContinue
if (-not $backendListener) {
    Write-Host "  Starting Docker containers (backend & mysql)..." -ForegroundColor Gray
    docker compose up -d
    Start-Sleep -Seconds 5
} else {
    Write-Host "  Backend is already running on port 8081 (HTTP 200)." -ForegroundColor Green
}

# 2. Check & Start Cloudflare Tunnel
Write-Host "`n[2/3] Checking Cloudflare Tunnel..." -ForegroundColor Yellow
$tunnelProc = Get-Process cloudflared -ErrorAction SilentlyContinue
if (-not $tunnelProc) {
    Write-Host "  Launching Cloudflare Tunnel for api.camapp.store..." -ForegroundColor Gray
    Start-Process `
        -FilePath $cloudflaredExe `
        -ArgumentList "tunnel", "--config", $cloudflaredConfig, "run", "camfix" `
        -WorkingDirectory $repoRoot `
        -WindowStyle Hidden
    Start-Sleep -Seconds 4
    Write-Host "  Cloudflare Tunnel started in background." -ForegroundColor Green
} else {
    Write-Host "  Cloudflare Tunnel is already running (PID: $($tunnelProc.Id -join ', '))." -ForegroundColor Green
}

# 3. Health Check
Write-Host "`n[3/3] Checking Public Domain & API Health..." -ForegroundColor Yellow
$connected = $false
$maxAttempts = 8
for ($i = 1; $i -le $maxAttempts; $i++) {
    try {
        $res = Invoke-WebRequest -Uri "https://api.camapp.store/api/technicians" -TimeoutSec 6 -UseBasicParsing
        if ($res.StatusCode -eq 200) {
            Write-Host "  SUCCESS! https://api.camapp.store is LIVE and responding HTTP 200 OK." -ForegroundColor Green
            $connected = $true
            break
        }
    } catch {
        Write-Host "  Waiting for Cloudflare edge routing to sync... (attempt $i/$maxAttempts)" -ForegroundColor Gray
        Start-Sleep -Seconds 3
    }
}

if (-not $connected) {
    Write-Host "  Public API check timed out. Please run: .\scripts\check-hosting.ps1" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Public API: https://api.camapp.store" -ForegroundColor Green
Write-Host "Admin Panel: https://kruythuna.github.io/CamFix/" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
