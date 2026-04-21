$InstallPath = "C:\SecureUSB"
$LogPath = "$InstallPath\usb_audit.log"

function Write-SecureLog($Type, $Message, $DeviceInfo) {
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    
    $Details = @{ Time=$Timestamp; User=$User; Type=$Type; Message=$Message; Device=$DeviceInfo } | ConvertTo-Json -Compress
    Add-Content -Path $LogPath -Value "[$Timestamp] [$Type] $Message"
    
    $EventID = switch ($Type) { "BLOCKED" { 9001 } "AUTHORIZED" { 9002 } "BADUSB" { 9100 } default { 9000 } }
    Write-EventLog -LogName Application -Source "SecureUSB" -EventId $EventID -EntryType Warning -Message $Details
}

$Query = @"
SELECT * FROM __InstanceCreationEvent WITHIN 2 
WHERE TargetInstance ISA 'Win32_PnPEntity' 
AND (TargetInstance.PNPClass = 'DiskDrive' OR TargetInstance.PNPClass = 'USB')
"@

Register-WmiEvent -Query $Query -Action {
    $Device = $Event.SourceEventArgs.NewEvent.TargetInstance
    $DeviceID = $Device.DeviceID
    
    if ($DeviceID -match "USBSTOR" -or $Device.Name -match "USB.*Storage") {
        $Serial = "UNKNOWN"
        try {
            $Disk = Get-WmiObject Win32_DiskDrive | Where-Object { $DeviceID -like "*$($DeviceID.Split('\')[-1])*" }
            if ($Disk) { $Serial = $Disk.SerialNumber.Trim() }
        } catch {}
        
        Write-SecureLog -Type "BLOCKED" -Message "🚫 USB محظور: $($Device.Name)" -DeviceInfo @{ID=$DeviceID; Serial=$Serial}
        msg * "⚠️ تم منع USB غير مصرح به: $($Device.Name)`nرقم الجهاز: $Serial`nاتصل بقسم IT"
    }
}

while ($true) {
    Start-Sleep -Seconds 10
    if (!(Get-ScheduledTask "SecureUSB_Monitor" -ErrorAction SilentlyContinue)) { break }
}
