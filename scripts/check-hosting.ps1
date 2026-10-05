$ErrorActionPreference = 'Continue'

Write-Host 'Local backend:'
try {
    $local = Invoke-WebRequest -Uri 'http://127.0.0.1:8081/api/technicians' -UseBasicParsing -TimeoutSec 10
    Write-Host "  HTTP $($local.StatusCode)"
}
catch {
    Write-Host "  FAILED: $($_.Exception.Message)"
}

Write-Host 'Cloudflare tunnel:'
cloudflared tunnel info camfix

Write-Host 'Public DNS:'
try {
    Resolve-DnsName 'api.camapp.store' -Server '1.1.1.1' -ErrorAction Stop |
        Select-Object Name, Type, NameHost, IPAddress |
        Format-Table
}
catch {
    Write-Host '  FAILED: api.camapp.store does not resolve publicly.'
}

Write-Host 'Public API:'
try {
    $public = Invoke-WebRequest -Uri 'https://api.camapp.store/api/technicians' -UseBasicParsing -TimeoutSec 20
    Write-Host "  HTTP $($public.StatusCode)"
}
catch {
    Write-Host "  FAILED: $($_.Exception.Message)"
}
