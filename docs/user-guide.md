# 📘 دليل استخدام SecureUSB Enterprise v2.0

## ⚠️ المتطلبات المسبقة

| المتطلب | التفاصيل |
|---------|----------|
| صلاحيات | حساب Administrator أو SYSTEM |
| نظام التشغيل | Windows 10/11 Pro أو Enterprise (Home محدودة) |
| PowerShell | الإصدار 5.1 أو أحدث |
| USB معتمد | فلاش واحد على الأقل معروف Hardware ID الخاص به |

---

## 🚀 الخطوة 1: التحضير (معرفة Hardware ID)

### 1.1 احصل على Hardware ID للـ USB المعتمد
افتح PowerShell كمسؤول ونفّذ:

```powershell
# عرض جميع أجهزة USB المتصلة مع معرفاتها
Get-PnpDevice -Class USB, DiskDrive, WPD | 
Where-Object { $_.Status -eq 'OK' } | 
Select-Object Name, @{N='HardwareID';E={$_.HardwareID[0]}}, @{N='InstanceID';E={$_.InstanceId}} | 
Format-Table -AutoSize
```

أو للحصول على Serial Number (الطريقة البديلة):
```powershell
Get-WmiObject Win32_DiskDrive | 
Where-Object {$_.InterfaceType -eq "USB"} | 
Select-Object Model, SerialNumber, PNPDeviceID
```

### 1.2 احفظ المعرفات
انسخ القيم التالية في ملف نصي:
- Hardware ID (مثال: USB\VID_0781&PID_5567\4C530001230325109182)
- Serial Number (إذا استخدمت الطريقة الثانية)

---

## 📁 الخطوة 2: تثبيت النظام

### 2.1 التثبيت باستخدام السكربتات
قم بتشغيل `Deploy-SecureUSB.ps1` مع تمرير المعرفات المعتمدة.

```powershell
.\Deploy-SecureUSB.ps1 -ApprovedHardwareIDs @("USB\VID_XXXX&PID_XXXX\SERIAL")
```

---

## 🔍 الخطوة 3: التحقق من النظام

### 3.1 التحقق من المهام المجدولة
```powershell
Get-ScheduledTask -TaskName "SecureUSB*" | Select TaskName, State, LastRunTime
```

### 3.2 التحقق من السجلات
الطريقة 1: Event Viewer
`eventvwr.msc` -> Application → Source: SecureUSB

الطريقة 2: ملف الـ Log
`Get-Content "C:\SecureUSB\usb_audit.log" -Tail 20`

---

## 🆘 الخطوة 4: إدارة الطوارئ

### 4.1 فك القفل في حالة الطوارئ
```powershell
.\SecureUSB-Recovery.ps1 -EmergencyKey "RECOVERY-KEY-HERE"
```

---

## ❌ الخطوة 5: إلغاء التثبيت (Uninstall)

1. إيقاف المهام المجدولة.
2. إزالة مفاتيح Registry.
3. حذف ملفات النظام.
