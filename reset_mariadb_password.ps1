<#
.SYNOPSIS
Safely resets the MariaDB/MySQL root password dynamically.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ======================================================================
# 1. VALIDATION & DISCOVERY
# ======================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "[FATAL] This script requires Administrator privileges."
    exit 1    
}

Write-Host "Scanning for MariaDB/MySQL services..." -ForegroundColor Cyan
$services = Get-CimInstance Win32_Service | Where-Object { ($_.Name -match 'mysql|mariadb') -and ($_.PathName -match 'mysqld\.exe') }

if ($services.Count -eq 0) {
    Write-Error "[FATAL] Could not detect a running MariaDB or MySQL service."
    exit 1
}
if ($services.Count -gt 1) {
    Write-Error "[FATAL] Multiple database services detected. Aborting to prevent cross-instance contamination."
    exit 1
}

$targetService = $services[0]
$svcName = $targetService.Name

# Extract binary path safely using regex
$rawPath = $targetService.PathName -replace '"', ''
if ($rawPath -match '(?i)(^.*mysqld\.exe)') {
    $binPath = $matches[1]
    $binDir  = Split-Path $binPath
} else {
    Write-Error "[FATAL] Could not parse executable path from: $rawPath"
    exit 1
}

Write-Host "Target Service: $svcName"
Write-Host "Binary Dir:     $binDir`n"

# ======================================================================
# 2. CREDENTIAL SETUP
# ======================================================================
$securePass = Read-Host "Enter new root password" -AsSecureString
$plainPass  = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass))
$initFile   = "C:\Windows\Temp\mariadb_reset.sql"

# Generate SQL payload covering local loopbacks and remote wildcard
$sqlPayload = @"
ALTER USER IF EXISTS 'root'@'localhost' IDENTIFIED BY '$plainPass';
ALTER USER IF EXISTS 'root'@'127.0.0.1' IDENTIFIED BY '$plainPass';
ALTER USER IF EXISTS 'root'@'::1' IDENTIFIED BY '$plainPass';
ALTER USER IF EXISTS 'root'@'%' IDENTIFIED BY '$plainPass';
FLUSH PRIVILEGES;
"@

$sqlPayload | Out-File -FilePath $initFile -Encoding Ascii -Force

# ======================================================================
# 3. EXECUTION & CLEANUP
# ======================================================================
$tempProc = $null

try {
    Write-Host "Stopping service [$svcName]..."
    Stop-Service -Name $svcName -Force -WarningAction SilentlyContinue

    Write-Host "Starting temporary standalone instance..."
    $mysqldArgs = @("--init-file=$initFile")
    
    # PassThru captures the exact PID of the process we just spawned
    $tempProc = Start-Process -FilePath "$binPath" -ArgumentList $mysqldArgs -PassThru -WindowStyle Hidden

    Write-Host "Waiting 10 seconds for initialization..."
    Start-Sleep -Seconds 10

    if ($tempProc.HasExited) {
        Write-Error "[FATAL] Temporary instance crashed on startup. Check MariaDB error logs."
        exit 1
    }

    Write-Host "Shutting down temporary instance gracefully..."
    $mysqladminArgs = @("-u", "root", "-p$plainPass", "shutdown")
    $adminProc = Start-Process -FilePath "$binDir\mysqladmin.exe" -ArgumentList $mysqladminArgs -PassThru -Wait -WindowStyle Hidden

} catch {
    Write-Error "An unexpected error occurred: $_"
} finally {
    # Fail-safe: Ensure the temporary process is dead before restarting the service
    if ($null -ne $tempProc -and -not $tempProc.HasExited) {
        Write-Warning "Graceful shutdown failed or hung. Force-terminating PID: $($tempProc.Id)..."
        Stop-Process -Id $tempProc.Id -Force
        Start-Sleep -Seconds 2
    }

    Write-Host "Restarting service [$svcName]..."
    Start-Service -Name $svcName -WarningAction SilentlyContinue

    Write-Host "Cleaning up credential files..."
    if (Test-Path $initFile) {
        Remove-Item -Path $initFile -Force
    }

    # Clear plain text password from memory
    $plainPass = $null
    
    Write-Host "Operation complete." -ForegroundColor Green
}