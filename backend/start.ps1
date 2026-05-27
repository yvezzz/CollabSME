# Start.ps1 - Lance CollabSME Backend + ngrok
param(
    [switch]$NoNgrok
)

$BackendDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$NgrokPath = "$env:USERPROFILE\ngrok.exe"
$NgrokDomain = "unconvoluted-prepreference-jeraldine.ngrok-free.dev"

# Load .env file
$EnvFile = "$BackendDir\.env"
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -and $_ -notmatch '^\s*#') {
            $parts = $_ -split '=', 2
            if ($parts.Count -eq 2) {
                [Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim(), "Process")
            }
        }
    }
    Write-Host "✓ .env chargé" -ForegroundColor Green
} else {
    Write-Host "⚠ .env introuvable, utilisation des variables système" -ForegroundColor Yellow
}

# Kill old processes
Get-Process -Name "java" -ErrorAction SilentlyContinue | Stop-Process -Force
if (-not $NoNgrok) {
    Get-Process -Name "ngrok" -ErrorAction SilentlyContinue | Stop-Process -Force
}

# Start ngrok
if (-not $NoNgrok) {
    Write-Host "▶ Démarrage ngrok sur https://$NgrokDomain ..." -ForegroundColor Cyan
    Start-Process -WindowStyle Hidden -FilePath $NgrokPath -ArgumentList "http 8000 --domain=$NgrokDomain --log=stdout"
    Start-Sleep -Seconds 3
    Write-Host "✓ ngrok actif" -ForegroundColor Green
}

# Start Spring Boot
Write-Host "▶ Démarrage Spring Boot sur http://localhost:8000 ..." -ForegroundColor Cyan
Set-Location $BackendDir
mvn spring-boot:run
