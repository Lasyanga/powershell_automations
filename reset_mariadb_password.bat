@echo off
setlocal

:: 1. Enforce Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [FATAL] Administrator privileges required.
    pause
    exit /b 1
)

:: ======================================================================
:: DYNAMIC DISCOVERY & MULTIPLE INSTANCE PROTECTION
:: ======================================================================
echo Scanning for MariaDB/MySQL services...

:: PowerShell: Count matches (abort if >1), strip quotes, strip arguments safely
set "PS_CMD=$svcs = Get-CimInstance Win32_Service | Where-Object {($_.Name -match 'mysql|mariadb') -and ($_.PathName -match 'mysqld\.exe')}; if($svcs.Count -eq 0){exit 1}; if($svcs.Count -gt 1){ Write-Host 'MULTIPLE_INSTANCES'; exit 0 }; $p = $svcs[0].PathName -replace [char]34, '' -replace '(?i)\.exe\s+.*', '.exe'; $b = Split-Path $p; Write-Host ('{0}*{1}' -f $svcs[0].Name, $b)"

for /f "tokens=1,2 delims=*" %%A in ('powershell -NoProfile -Command "%PS_CMD%"') do (
    if "%%A"=="MULTIPLE_INSTANCES" (
        echo [FATAL] Multiple MariaDB/MySQL services detected.
        echo Aborting to prevent resetting the wrong database instance.
        pause
        exit /b 1
    )
    set "SERVICE_NAME=%%A"
    set "BIN_DIR=%%B"
)

if not defined SERVICE_NAME (
    echo [FATAL] Could not detect a running MariaDB or MySQL service.
    pause
    exit /b 1
)

echo Found Service: %SERVICE_NAME%
echo Found Bin Dir: %BIN_DIR%

:: ======================================================================
:: EXECUTION & HOST SPECIFICITY
:: ======================================================================
set INIT_FILE="C:\Windows\Temp\mariadb_reset.sql"
set /p NEW_PASS="Enter new root password: "

:: Cover all common local loopback interfaces (Requires MariaDB 10.1.3+)
echo ALTER USER IF EXISTS 'root'@'localhost' IDENTIFIED BY '%NEW_PASS%'; > %INIT_FILE%
echo ALTER USER IF EXISTS 'root'@'127.0.0.1' IDENTIFIED BY '%NEW_PASS%'; >> %INIT_FILE%
echo ALTER USER IF EXISTS 'root'@'::1' IDENTIFIED BY '%NEW_PASS%'; >> %INIT_FILE%
echo ALTER USER IF EXISTS 'root'@'%%' IDENTIFIED BY '%NEW_PASS%'; >> %INIT_FILE%
echo FLUSH PRIVILEGES; >> %INIT_FILE%

echo Stopping %SERVICE_NAME% service...
net stop "%SERVICE_NAME%"

echo Starting temporary instance to apply the password...
start "MariaDB Password Reset" /B "%BIN_DIR%\mysqld.exe" --init-file=%INIT_FILE%

:: Give the database time to spin up and execute the file
timeout /t 10 /nobreak >nul

echo Shutting down temporary instance...
"%BIN_DIR%\mysqladmin.exe" -u root -p"%NEW_PASS%" shutdown

:: ======================================================================
:: FAIL-SAFE: ORPHANED PROCESS CLEANUP
:: ======================================================================
:: If mysqladmin failed to shut down the database, force-kill ONLY the 
:: specific temporary instance we just spawned to release the file locks.
powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object {$_.Name -eq 'mysqld.exe' -and $_.CommandLine -match 'mariadb_reset\.sql'} | Invoke-CimMethod -MethodName Terminate | Out-Null"

echo Starting %SERVICE_NAME% service...
net start "%SERVICE_NAME%"

:: Clean up
del %INIT_FILE%

echo Password reset complete.
endlocal
pause