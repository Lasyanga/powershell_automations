param (
    [string]$source = "",
    [string]$target = "",
    [string]$date   = (Get-Date -Format "yyyy-MM-dd")
)

# Prompt for source if not provided
if (-not $source) {
    $source = Read-Host "Enter source directory path"
}

# Prompt for target if not provided
if (-not $target) {
    $target = Read-Host "Enter target directory path"
}

# Prompt for date, showing today as default
$inputDate = Read-Host "Enter date to filter by (yyyy-MM-dd) [default: $date]"
if ($inputDate) {
    $date = $inputDate
}

# Validate paths
if (-not (Test-Path $source)) {
    Write-Host "ERROR: Source path does not exist: $source" -ForegroundColor Red
    exit 1
}

# Parse and validate date
try {
    $filterDate = [datetime]::ParseExact($date, "yyyy-MM-dd", $null).Date
} catch {
    Write-Host "ERROR: Invalid date format. Please use yyyy-MM-dd." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Source : $source"       -ForegroundColor Cyan
Write-Host "Target : $target"       -ForegroundColor Cyan
Write-Host "Date   : $filterDate"   -ForegroundColor Cyan
Write-Host ""

# Find the latest modified file on the given date
$files = Get-ChildItem -Path $source -Recurse -File |
    Where-Object { $_.LastWriteTime.Date -ge $filterDate} 
   # | Sort-Object LastWriteTime -Descending |
   # Select-Object -First 1

if (-not $files) {
    Write-Host "No files found modified on $date in: $source" -ForegroundColor Yellow
    exit 0
}

$files | ForEach-Object {
    $relativePath = $_.FullName.Substring($source.TrimEnd('\').Length).TrimStart('\')
    $destination  = Join-Path $target $relativePath
    $destDir      = Split-Path $destination -Parent

    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    Copy-Item -Path $_.FullName -Destination $destination -Force
    Write-Host "Copied : $($_.FullName)" -ForegroundColor Green
    Write-Host "    To : $destination"   -ForegroundColor Green
}

Write-Host ""
Write-Host "Done." -ForegroundColor White

Write-Host "`nTask complete. Press any key to close this window..." -ForegroundColor White
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")