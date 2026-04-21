param([Parameter(Mandatory=$true)][string]$EmergencyKey)
$InstallPath = "C:\SecureUSB"
$ConfigBytes = [IO.File]::ReadAllBytes("$InstallPath\config.enc")
$DecryptedBytes = [Security.Cryptography.ProtectedData]::Unprotect($ConfigBytes, $null, 'LocalMachine')
$Config = [System.Text.Encoding]::UTF8.GetString($DecryptedBytes) | ConvertFrom-Json

if ($EmergencyKey -eq $Config.EmergencyKey) {
    $EmergencyKey | Out-File -FilePath "$InstallPath\recovery.flag" -Force
    Write-Host "✅ تم إنشاء ملف الاستعادة. أعد تشغيل الجهاز الآن." -ForegroundColor Green
} else {
    Write-Host "❌ مفتاح الطوارئ غير صحيح!" -ForegroundColor Red
}
