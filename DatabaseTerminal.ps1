function Add-Log($msg, $color = 'Blue'){
    $time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$time] " -NoNewline -ForegroundColor Gray
    Write-Host "$msg" -ForegroundColor $color
}

Clear-Host
$databaseRawPath = (Get-CimInstance -ClassName Win32_Service -Filter "Name LIKE '%maria%' OR Name LIKE '%msyql%'").PathName

if($null -eq $databaseRawPath){
    Add-Log "No Database Service Found" "Red"
    Read-Host "Press Enter to exit"
    exit
}

if ($databaseRawPath -match '^"?([^"]+?\.exe)"?') {
    $cleanPath = $Matches[1]
}
Add-Log "Executable found at: $cleanPath"
$databasePath = Split-Path $cleanPath
$command = "Set-Location -Path '$databasePath'"

Start-Process powershell -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -Command `"$command`"" -Verb RunAs
exit
