$x_code = @"
using System;
using System.Runtime.InteropServices;

public class KeyboardReset {
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);

    private const byte VK_LSHIFT = 0xA0;
    private const byte VK_RSHIFT = 0xA1;
    private const uint KEYEVENTF_KEYUP = 0x0002;

    public static void ResetShift() {
        // Send Key Up for Left Shift
        keybd_event(VK_LSHIFT, 0, KEYEVENTF_KEYUP, 0);
        // Send Key Up for Right Shift
        keybd_event(VK_RSHIFT, 0, KEYEVENTF_KEYUP, 0);
    }
}
"@

# Define completion message with prefix
$x_finish_msg = "Shift key states have been reset. Press Enter to close..."

try {
    Add-Type -TypeDefinition $x_code -ErrorAction SilentlyContinue
    [KeyboardReset]::ResetShift()
    
    Write-Host $x_finish_msg -ForegroundColor Green
}
catch {
    Write-Host "Error: Could not reset keyboard state." -ForegroundColor Red
}

# Halt code: Waits for user input before closing
Read-Host