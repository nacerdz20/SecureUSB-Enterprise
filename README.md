# 🔐 SecureUSB Enterprise

**SecureUSB Enterprise** هو نظام أمني مبني على PowerShell للتحكم في أجهزة USB داخل بيئة Windows، يعتمد على نموذج **Default-Deny** (المنع الافتراضي) مع قائمة سماح للأجهزة المصرح بها.

> 🛡️ موجه إلى المؤسسات التي تعاني من:
> - سرقة البيانات عبر USB
> - استخدام أجهزة غير مصرح بها
> - ضعف تطبيق سياسات الأمن الرقمي

---

## 👨‍💻 إعداد

**Zouaizia Nacer**  
حل موجه للأمن المعلوماتي داخل المؤسسات

---

## 🎯 الهدف

تقليل مخاطر:
- تسريب البيانات
- إدخال برمجيات خبيثة (BadUSB)
- فقدان التحكم في الأجهزة الطرفية

---

## ⚙️ كيف يعمل النظام

النظام يعتمد على:

- 🔒 سياسات Windows Device Installation (Registry/GPO)
- ✅ قائمة سماح (Whitelist) عبر Hardware IDs
- 📊 مراقبة لحظية للأجهزة (USB Monitoring)
- 🔐 إعدادات مشفرة محليًا
- 🚨 وضع طوارئ (Recovery Mode)

---

## 🚀 الميزات

- منع جميع أجهزة USB غير المصرح بها
- السماح فقط للأجهزة المحددة مسبقًا
- تسجيل كل العمليات (Audit Logging)
- تنبيه المستخدم عند إدخال جهاز غير مصرح
- حماية الإعدادات عبر التشفير
- إمكانية استرجاع النظام في حالة الطوارئ

---

## 🖥️ المتطلبات

- Windows 10/11 Pro أو Enterprise
- PowerShell 5.1 أو أحدث
- صلاحيات Administrator

---

## ⚡ التثبيت السريع

```powershell
cd C:\SecureUSB-Deploy
.\Deploy-SecureUSB.ps1 -ApprovedHardwareIDs @(
  "USB\VID_XXXX&PID_XXXX\SERIAL"
)
Restart-Computer
