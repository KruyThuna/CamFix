[CmdletBinding()]
param(
    [switch]$SkipBackendBuild
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $repoRoot 'Backend'
$runtimeRoot = Join-Path $repoRoot '.runtime'
$cloudflaredConfig = Join-Path $env:USERPROFILE '.cloudflared\config.yml'
$backendJar = Join-Path $backendRoot 'build\libs\api.jar'

New-Item -ItemType Directory -Force -Path $runtimeRoot | Out-Null

if (-not (Get-Command cloudflared -ErrorAction SilentlyContinue)) {
    throw 'cloudflared is not installed. Run: winget install --id Cloudflare.cloudflared'
}

if (-not (Test-Path -LiteralPath $cloudflaredConfig)) {
    throw "Missing tunnel configuration: $cloudflaredConfig"
}

cloudflared tunnel ingress validate
if ($LASTEXITCODE -ne 0) {
    throw 'Cloudflare ingress configuration is invalid.'
}

if (-not $SkipBackendBuild) {
    $env:GRADLE_USER_HOME = Join-Path $env:USERPROFILE '.gradle'
    Push-Location $backendRoot
    try {
        & .\gradlew.bat bootJar --offline
        if ($LASTEXITCODE -ne 0) {
            throw 'Backend build failed.'
        }
    }
    finally {
        Pop-Location
    }
}

if (-not (Test-Path -LiteralPath $backendJar)) {
    throw "Backend JAR not found: $backendJar"
}

$backendListener = Get-NetTCPConnection -State Listen -LocalPort 8081 -ErrorAction SilentlyContinue
if (-not $backendListener) {
    $backendProcess = Start-Process `
        -FilePath 'java.exe' `
        -ArgumentList '-jar', $backendJar `
        -WorkingDirectory $backendRoot `
        -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $runtimeRoot 'backend.log') `
        -RedirectStandardError (Join-Path $runtimeRoot 'backend.err') `
        -PassThru
    Set-Content -LiteralPath (Join-Path $runtimeRoot 'backend.pid') -Value $backendProcess.Id
}

$deadline = (Get-Date).AddSeconds(45)
do {
    Start-Sleep -Seconds 1
    $backendListener = Get-NetTCPConnection -State Listen -LocalPort 8081 -ErrorAction SilentlyContinue
} until ($backendListener -or (Get-Date) -ge $deadline)

if (-not $backendListener) {
    throw "Backend did not start on port 8081. Check $runtimeRoot\backend.err"
}

$localTunnel = Get-Process cloudflared -ErrorAction SilentlyContinue
if (-not $localTunnel) {
    $tunnelProcess = Start-Process `
        -FilePath 'cloudflared.exe' `
        -ArgumentList 'tunnel', '--config', $cloudflaredConfig, 'run', 'camfix' `
        -WorkingDirectory $repoRoot `
        -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $runtimeRoot 'cloudflared.log') `
        -RedirectStandardError (Join-Path $runtimeRoot 'cloudflared.err') `
        -PassThru
    Set-Content -LiteralPath (Join-Path $runtimeRoot 'cloudflared.pid') -Value $tunnelProcess.Id
}

Start-Sleep -Seconds 3
& (Join-Path $PSScriptRoot 'check-hosting.ps1')
