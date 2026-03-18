# ================================
# VS Code Cache Cleanup Script
# ================================

Write-Host "Closing VS Code if running..." -ForegroundColor Yellow
Get-Process Code -ErrorAction SilentlyContinue | Stop-Process -Force

$paths = @(
    "$env:APPDATA\Code\Cache",
    "$env:APPDATA\Code\CachedData",
    "$env:APPDATA\Code\GPUCache",
    "$env:APPDATA\Code\User\workspaceStorage"
)

Write-Host "`nCleaning VS Code cache folders..." -ForegroundColor Cyan

foreach ($path in $paths) {
    if (Test-Path $path) {
        Write-Host "Deleting: $path" -ForegroundColor Green
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "Not found: $path" -ForegroundColor DarkGray
    }
}

Write-Host "`nVS Code cache cleanup complete." -ForegroundColor Magenta
