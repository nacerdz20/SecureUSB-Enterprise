$ErrorActionPreference = "Stop"
$InstallPath = "C:\SecureUSB"

try {
    $ConfigBytes = [IO.File]::ReadAllBytes("$InstallPath\config.enc")
    $DecryptedBytes = [Security.Cryptography.ProtectedData]::Unprotect($ConfigBytes, $null, 'LocalMachine')
    $Config = [System.Text.Encoding]::UTF8.GetString($DecryptedBytes) | ConvertFrom-Json
    
    # Recovery Mode
    $RecoveryFile = "$InstallPath\recovery.flag"
    if (Test-Path $RecoveryFile) {
        $Content = Get-Content $RecoveryFile -Raw
        if ($Content.Trim() -eq $Config.EmergencyKey) {
            Write-EventLog -LogName Application -Source "SecureUSB" -EventId 9002 -EntryType Information -Message "🚨 وضع الطوارئ مفعل - تم فك القفل"
            Remove-Item $RecoveryFile -Force
            reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions" /f 2>$null
            exit 0
        }
    }

    $RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
    if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }

    # Deny All
    Set-ItemProperty -Path $RegPath -Name "DenyUnspecified" -Value 1 -Type DWord
    
    # Allow Approved Hardware IDs
    $AllowPath = "$RegPath\AllowHardwareIDs"
    if (!(Test-Path $AllowPath)) { New-Item -Path $AllowPath -Force | Out-Null }
    Set-ItemProperty -Path $RegPath -Name "AllowHardwareIDs" -Value 1 -Type DWord
    
    Remove-ItemProperty -Path $AllowPath -Name "*" -ErrorAction SilentlyContinue
    for ($i = 0; $i -lt $Config.ApprovedHardwareIDs.Count; $i++) {
        Set-ItemProperty -Path $AllowPath -Name ($i + 1) -Value $Config.ApprovedHardwareIDs[$i] -Type String
    }

    # Allow HID (Mouse/Keyboard)
    $AllowClass = "$RegPath\AllowDeviceClasses"
    if (!(Test-Path $AllowClass)) { New-Item -Path $AllowClass -Force | Out-Null }
    Set-ItemProperty -Path $RegPath -Name "AllowDeviceClasses" -Value 1 -Type DWord
    Set-ItemProperty -Path $AllowClass -Name "1" -Value "{745A17A0-74D3-11D0-B6FE-00A0C90F57DA}" -Type String
    Set-ItemProperty -Path $AllowClass -Name "2" -Value "{4D36E96B-E325-11CE-BFC1-08002BE10318}" -Type String
    Set-ItemProperty -Path $AllowClass -Name "3" -Value "{4D36E96F-E325-11CE-BFC1-08002BE10318}" -Type String

    # Additional Removable Storage Deny
    $StoragePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices"
    if (!(Test-Path $StoragePath)) {
        New-Item -Path $StoragePath -Force | Out-Null
        New-Item -Path "$StoragePath\{53f56307-b6bf-11d0-94f2-00a0c91efb8b}" -Force | Out-Null
        Set-ItemProperty -Path "$StoragePath\{53f56307-b6bf-11d0-94f2-00a0c91efb8b}" -Name "Deny_Write" -Value 1 -Type DWord
        Set-ItemProperty -Path "$StoragePath\{53f56307-b6bf-11d0-94f2-00a0c91efb8b}" -Name "Deny_Read" -Value 1 -Type DWord
    }

    Write-EventLog -LogName Application -Source "SecureUSB" -EventId 1000 -EntryType Information -Message "✅ SecureUSB: الحماية مفعلة"

} catch {
    Write-EventLog -LogName Application -Source "SecureUSB" -EventId 9999 -EntryType Error -Message "❌ SecureUSB Error: $_"
}
