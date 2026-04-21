# Installation Guide

## 1. جمع Hardware ID

```powershell
Get-PnpDevice -Class USB, DiskDrive | Select Name, HardwareID
```

## 2. التثبيت

```powershell
.\Deploy-SecureUSB.ps1 -ApprovedHardwareIDs @("ID")
```

## 3. إعادة التشغيل

```powershell
Restart-Computer
```
