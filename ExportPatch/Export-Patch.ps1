[CmdletBinding()]
param (
    [string]$ConfigFile = "projects.txt"
)

# 1. Load and validate projects configuration
if (-not (Test-Path -Path $ConfigFile)) {
    Write-Error "Configuration file '$ConfigFile' not found. Create it with one repository path per line."
    exit 1
}

$projects = Get-Content -Path $ConfigFile | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -Path $_) }

if ($projects.Count -eq 0) {
    Write-Error "No valid project directories found in '$ConfigFile'."
    exit 1
}

# 2. Select Project Directory
Write-Host "--- Select Project Repository ---" -ForegroundColor Cyan
for ($i = 0; $i -lt $projects.Count; $i++) {
    Write-Host "[$($i + 1)]$($projects[$i])"
}

$projChoice = Read-Host "Select project number (1-$($projects.Count))"
if (-not [int]::TryParse($projChoice, [ref]$null) -or [int]$projChoice -lt 1 -or [int]$projChoice -gt $projects.Count) {
    Write-Error "Invalid project selection."
    exit 1
}
$repo = $projects[[int]$projChoice - 1]

# 3. Select Search Type
Write-Host "`n--- Select Git Search Mode ---" -ForegroundColor Cyan
Write-Host "[1] Search Commit Message (--grep)"
Write-Host "[2] Specific Commit Hash or Range (e.g., a1b2c3d or HEAD~1..HEAD)"

$modeChoice = Read-Host "Select mode (1-2)"
$searchTerm = ""
$gitArgs = @("-C", $repo, "log", "--name-only", "--pretty=format:")

switch ($modeChoice) {
    "1" {
        $searchTerm = Read-Host "Enter grep term (e.g., B3814)"
        if ([string]::IsNullOrWhiteSpace($searchTerm)) { Write-Error "Grep term required."; exit 1 }
        $gitArgs += "--grep=$searchTerm"
    }
    "2" {
        $searchTerm = Read-Host "Enter Commit Hash or Range (e.g., 7a8f9b2 or main..feature)"
        if ([string]::IsNullOrWhiteSpace($searchTerm)) { Write-Error "Commit identifier required."; exit 1 }
        $gitArgs += $searchTerm
    }
    default {
        Write-Error "Invalid mode selected."
        exit 1
    }
}

# Sanitize term for directory naming
$folderName = $searchTerm -replace '[\\/:*?"<>|]', '_'

# 4. Destination Directory Setup
$defaultDest = Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath "hosting_patch\$folderName"
Write-Host "`nDefault Destination: $defaultDest" -ForegroundColor Yellow
$customDest = Read-Host "Press ENTER to use default, or enter custom destination path"

$dest = if ([string]::IsNullOrWhiteSpace($customDest)) { $defaultDest } else {$customDest }

# 5. Retrieve changed files
Write-Host "`nQuerying Git repository..." -ForegroundColor Green
$rawFiles = & git @gitArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "Git command failed. Check search inputs or repository state."
    exit $LASTEXITCODE
}

$files = $rawFiles | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

if ($null -eq $files -or $files.Count -eq 0) {
    Write-Warning "No files found matching criteria '$searchTerm' in repository: $repo"
    exit 0
}

# 6. Copy Files Maintaining Directory Tree
$copiedCount = 0
$missingCount = 0

foreach ($relPath in $files) {
    $srcPath = Join-Path -Path $repo -ChildPath $relPath
    $dstPath = Join-Path -Path $dest -ChildPath $relPath

    if (Test-Path -Path $srcPath -PathType Leaf) {
        $parentDir = Split-Path -Path $dstPath -Parent
        if (-not (Test-Path -Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        Copy-Item -Path $srcPath -Destination $dstPath -Force
        Write-Host "Copied: $relPath" -ForegroundColor Gray
        $copiedCount++
    } else {
        Write-Warning "Skipped (File missing or deleted on disk): $relPath"
        $missingCount++
    }
}

# 7. Optional ZIP Compression
$archivePath = $null
if ($copiedCount -gt 0 -and (Test-Path -Path $dest)) {
    Write-Host "`n--- Compression ---" -ForegroundColor Cyan
    $compressAnswer = Read-Host "Compress '$folderName' to a .zip file? (y/n)"

    if ($compressAnswer -match '^(y|yes)$') {
        $archivePath = "$dest.zip"

        # Prefer 7-Zip if available; otherwise fall back to native Compress-Archive
        $sevenZPath = $null
        $sevenZCmd = Get-Command 7z -ErrorAction SilentlyContinue
        if ($sevenZCmd) {
            $sevenZPath = $sevenZCmd.Source
        } else {
            foreach ($candidate in @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe")) {
                if (Test-Path -Path $candidate) { $sevenZPath = $candidate; break }
            }
        }

        if ($sevenZPath) {
            Write-Host "Using 7-Zip: $sevenZPath" -ForegroundColor Green
            & $sevenZPath a -tzip $archivePath "$dest" -y | Out-Null
            if ($LASTEXITCODE -ne 0) {
                Write-Error "7-Zip failed with exit code $LASTEXITCODE."
                exit $LASTEXITCODE
            }
        } else {
            Write-Host "7-Zip not found. Using native Compress-Archive." -ForegroundColor Yellow
            Compress-Archive -Path $dest -DestinationPath $archivePath -CompressionLevel Optimal -Force
        }

        Write-Host "Archive created: $archivePath" -ForegroundColor Green
    }
}

Write-Host "`n--- Summary ---" -ForegroundColor Cyan
Write-Host "Destination : $dest"
Write-Host "Copied      : $copiedCount file(s)"
Write-Host "Skipped     : $missingCount file(s)"
if (-not [string]::IsNullOrWhiteSpace($archivePath)) { Write-Host "Archive     : $archivePath" }