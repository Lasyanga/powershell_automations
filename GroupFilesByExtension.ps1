# Files are grouped into category folders by extension, e.g.
#   images/    png, jpg, gif, ...
#   documents/ pdf, docx, xlsx, ...
#   videos/    mp4, mkv, mov, ...
#   archive/   zip, rar, 7z, ...
#   other/     any extension not listed below
# Edit the map to add your own categories or extensions.
$categoryMap = @{
    "images"    = @("png", "jpg", "jpeg", "gif", "bmp", "svg", "webp", "tiff", "ico")
    "documents" = @("pdf", "docx", "xlsx", "pptx", "txt", "md", "csv")
    "videos"    = @("mp4", "mkv", "mov", "avi", "wmv", "flv", "webm", "m4v")
    "archive"   = @("zip", "rar", "7z", "tar", "gz", "bz2")
}

# Reverse lookup: extension -> category
$extensionToCategory = @{}
foreach ($category in $categoryMap.Keys) {
    foreach ($ext in $categoryMap[$category]) {
        $extensionToCategory[$ext] = $category
    }
}

# Ask user for source and destination paths
$sourcePath = Read-Host "Enter the full path of the source folder"
$destinationPath = Read-Host "Enter the full path of the destination folder"

# Ensure source exists and is a folder
if (-Not (Test-Path $sourcePath -PathType Container)) {
    Write-Host "Source path does not exist or is not a folder." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Create destination if it doesn't exist
if (-Not (Test-Path $destinationPath)) {
    New-Item -Path $destinationPath -ItemType Directory | Out-Null
}

# Get all files from the source directory
$files = Get-ChildItem -Path $sourcePath -File

$moved = 0
$skipped = 0

foreach ($file in $files) {
    $extension = $file.Extension.TrimStart('.').ToLower()
    if (-not $extension) {
        $extension = "no_extension"
    }

    $category = "other"
    if ($extensionToCategory.ContainsKey($extension)) {
        $category = $extensionToCategory[$extension]
    }

    $targetFolder = Join-Path -Path (Join-Path -Path $destinationPath -ChildPath $category) -ChildPath $extension

    # Create the target folder if it doesn't exist
    if (-Not (Test-Path $targetFolder)) {
        New-Item -Path $targetFolder -ItemType Directory | Out-Null
    }

    # Move the file, unless a same-named file is already there
    $targetFile = Join-Path -Path $targetFolder -ChildPath $file.Name
    if (Test-Path $targetFile) {
        Write-Host "Skipped (already exists): $category/$extension/$($file.Name)" -ForegroundColor Yellow
        $skipped++
        continue
    }

    try {
        Move-Item -Path $file.FullName -Destination $targetFile -ErrorAction Stop
        $moved++
    } catch {
        Write-Host "Failed to move: $($file.Name) - $($_.Exception.Message)" -ForegroundColor Red
        $skipped++
    }
}

Write-Host "`nMoved $moved file(s), skipped $skipped." -ForegroundColor Green
Read-Host "`nPress Enter to exit"
