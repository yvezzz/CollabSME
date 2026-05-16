param(
    [string]$ApiUrl = "https://unconvoluted-prepreference-jeraldine.ngrok-free.dev/api/",
    [string]$WsUrl = "wss://unconvoluted-prepreference-jeraldine.ngrok-free.dev/"
)

Write-Host "=== Build Flutter Web ===" -ForegroundColor Cyan
flutter build web --release `
    --dart-define=API_BASE_URL=$ApiUrl `
    --dart-define=WS_BASE_URL=$WsUrl

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "=== Deploy to Firebase ===" -ForegroundColor Cyan
firebase deploy --only hosting

if ($LASTEXITCODE -eq 0) {
    Write-Host "=== Deployed successfully! ===" -ForegroundColor Green
}
