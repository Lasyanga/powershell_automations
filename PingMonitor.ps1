# --- Settings ---
$HostToPing = "8.8.8.8" 
$HighLatencyThreshold = 100 
$UpdateInterval = 1 
$BeepFrequency = 800  # Hertz
$BeepDuration = 200   # Milliseconds

Clear-Host
$Host.UI.RawUI.WindowTitle = "ping monitor"
Write-Host "Monitoring Latency to $HostToPing (Ctrl+C to stop)" -ForegroundColor Cyan
Write-Host "--------------------------------------------------"

while ($true) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    try {
        # -Count 1 ensures we get one result. -ErrorAction Stop forces it into the catch block if the host is unreachable.
        $ping = Test-Connection -ComputerName $HostToPing -Count 1 -ErrorAction Stop
        
        # Pulling the time property (compatible with PS 5.1 and PS 7)
        $time = $ping.ResponseTime
        if ($null -eq $time) { $time = $ping.Latency }

        # Logic check: If $time is still null or the status isn't "Success", treat it as a timeout
        if ($null -eq $time -or $time -eq 0) {
	    [Console]::Beep($BeepFrequency, $BeepDuration) # BEEP!
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
            Write-Host "Request Timed Out (No Latency Data)" -ForegroundColor Red
        } 
        else {
            $Color = if ($time -gt $HighLatencyThreshold) { "Yellow" } else { "Green" }
            
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
            Write-Host "Reply from $HostToPing : " -NoNewline
            Write-Host "time=$($time)ms" -ForegroundColor $Color
        }
    }
    catch {
	[Console]::Beep($BeepFrequency, $BeepDuration) # BEEP!
        Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
        Write-Host "Request Timed Out / Network Down" -ForegroundColor Red
    }

    Start-Sleep -Seconds $UpdateInterval
}