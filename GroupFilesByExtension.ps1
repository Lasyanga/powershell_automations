# Ask user for source and destination paths
$sourcePath = Read-Host "Enter the full path of the source folder"
$destinationPath = Read-Host "Enter the full path of the destination folder"

# Ensure source exists
if (-Not (Test-Path $sourcePath)) {
    Write-Host "Source path does not exist." -ForegroundColor Red
    Read-Host "Press any key to exit"
    exit
}

# Create destination if it doesn't exist
if (-Not (Test-Path $destinationPath)) {
    New-Item -Path $destinationPath -ItemType Directory | Out-Null
}

# Get all files from the source directory
$files = Get-ChildItem -Path $sourcePath -File

foreach ($file in $files) {
    $extension = $file.Extension.TrimStart('.').ToLower()
    if (-not $extension) {
        $extension = "no_extension"
    }

    $targetFolder = Join-Path -Path $destinationPath -ChildPath $extension

    # Create the target folder if it doesn't exist
    if (-Not (Test-Path $targetFolder)) {
        New-Item -Path $targetFolder -ItemType Directory | Out-Null
    }

    # Move the file to the corresponding folder
    $targetFile = Join-Path -Path $targetFolder -ChildPath $file.Name
    Move-Item -Path $file.FullName -Destination $targetFile -Force
}

Write-Host "`nFiles have been grouped by extension." -ForegroundColor Green
Read-Host "`nPress any key to exit"
