# 1. Close Microsoft Teams
Write-Host "Closing Microsoft Teams..." -ForegroundColor Cyan
$TeamsProcess = Get-Process -Name "ms-teams" -ErrorAction SilentlyContinue

if ($TeamsProcess) {
    Stop-Process -Name "ms-teams" -Force
    # Give the system a moment to release file locks
    Start-Sleep -Seconds 2
}

# 2. Define the Cache Path
$CachePath = "$env:USERPROFILE\AppData\Local\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams"

# 3. Clear the folder contents
if (Test-Path $CachePath) {
    Write-Host "Clearing Teams cache at: $CachePath" -ForegroundColor Yellow
    # This command deletes files and subfolders while suppressing non-critical errors
    Get-ChildItem -Path $CachePath -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cache clearing process complete." -ForegroundColor Green
} else {
    Write-Warning "Cache folder not found. Please check if the path is correct for your version of Teams."
}

# 4. Restart Teams
Write-Host "Restarting Teams..." -ForegroundColor Cyan
Start-Process "shell:AppsFolder\MSTeams_8wekyb3d8bbwe!MSTeams"

# 5. Wait for user input before closing
Write-Host "`nTask complete. Press any key to close this window..." -ForegroundColor White
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")