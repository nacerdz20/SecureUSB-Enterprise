[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string[]]$ApprovedHardwareIDs,
    [string]$InstallPath = "C:\SecureUSB",
    [string]$EmergencyKey = ( -join ((65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ }) )
)

# التحقق من الملفات المطلوبة
$RequiredFiles = @('SecureUSB-Lock.ps1', 'USB-Monitor.ps1', 'SecureUSB-Recovery.ps1')
foreach ($file in $RequiredFiles) {
    if (!(Test-Path "$PSScriptRoot\$file")) {
        throw "❌ ملف $file مفقود في المجلد!"
    }
}

# إنشاء المجلد
if (!(Test-Path $InstallPath)) { 
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null 
}

# حماية المجلد
$ACL = Get-Acl $InstallPath
$ACL.SetAccessRuleProtection($true, $false)
$SystemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$ACL.AddAccessRule($SystemRule)
$AuditRule = New-Object System.Security.AccessControl.FileSystemAuditRule("Everyone", "Write,Delete,ChangePermissions", "Success,Failure")
$ACL.AddAuditRule($AuditRule)
Set-Acl $InstallPath $ACL

# حفظ الإعدادات
$Config = @{
    ApprovedHardwareIDs = $ApprovedHardwareIDs
    EmergencyKey = $EmergencyKey
    InstallDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Version = "2.0"
    Checksum = @{}
}

foreach ($file in $RequiredFiles) {
    $Hash = Get-FileHash "$PSScriptRoot\$file" -Algorithm SHA256
    $Config.Checksum[$file] = $Hash.Hash
}

$Json = $Config | ConvertTo-Json -Depth 5
$Bytes = [System.Text.Encoding]::UTF8.GetBytes($Json)
$Encrypted = [Security.Cryptography.ProtectedData]::Protect($Bytes, $null, 'LocalMachine')
[IO.File]::WriteAllBytes("$InstallPath\config.enc", $Encrypted)

# نسخ الملفات
foreach ($file in $RequiredFiles) {
    Copy-Item "$PSScriptRoot\$file" "$InstallPath\" -Force
    attrib +R "$InstallPath\$file"
}

# Event Log
if (-not [System.Diagnostics.EventLog]::SourceExists("SecureUSB")) {
    New-EventLog -LogName "Application" -Source "SecureUSB"
}

# Scheduled Tasks
$ActionLock = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$InstallPath\SecureUSB-Lock.ps1`""
$ActionMonitor = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$InstallPath\USB-Monitor.ps1`""
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -RestartCount 3

Register-ScheduledTask -TaskName "SecureUSB_Lock" -Action $ActionLock -Trigger $Trigger -Principal $Principal -Settings $Settings -Force
Register-ScheduledTask -TaskName "SecureUSB_Monitor" -Action $ActionMonitor -Trigger $Trigger -Principal $Principal -Settings $Settings -Force

Checkpoint-Computer -Description "SecureUSB_Install" -RestorePointType "MODIFY_SETTINGS"

Write-Host "`n✅ تم التثبيت بنجاح!" -ForegroundColor Green
Write-Host "🔑 مفتاح الطوارئ: " -NoNewline; Write-Host $EmergencyKey -ForegroundColor Yellow -BackgroundColor DarkRed
Write-Host "⚠️ احفظ المفتاح في مكان آمن (لن يُعرض مرة أخرى)!" -ForegroundColor Red
Write-Host "`n📋 الأجهزة المعتمدة:" -ForegroundColor Cyan
$ApprovedHardwareIDs | ForEach-Object { Write-Host "   • $_" }
