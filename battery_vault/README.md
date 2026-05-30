# 🔋 Battery Vault - خزنة البطارية

تطبيق احترافي لتحسين البطارية مع خزنة سرية مخفية

## ✨ المميزات

- 🔋 مراقبة البطارية في الوقت الحقيقي
- ⚡ تحسين وتعزيز البطارية
- 🔐 **خزنة سرية** (اضغط على أيقونة البطارية 5 مرات)
- 📸 حفظ الصور والفيديوهات بشكل مشفر
- 📝 ملاحظات سرية
- 🌍 دعم العربية والإنجليزية
- 💰 إعلانات Unity Ads
- 🎨 Material 3 Design

## 🚀 إعداد المشروع

### 1. المتطلبات
- Flutter 3.22.0+
- Android Studio / VS Code
- Java 17

### 2. تثبيت الحزم
```bash
flutter pub get
flutter gen-l10n
```

### 3. إضافة الخطوط
ضع ملفات الخطوط في `assets/fonts/`:
- `Cairo-Regular.ttf`
- `Cairo-Bold.ttf`
- `Cairo-SemiBold.ttf`

يمكن تحميلها من: https://fonts.google.com/specimen/Cairo

### 4. إعداد Unity Ads
1. سجل في https://unity.com/solutions/unity-ads
2. أنشئ مشروع جديد
3. انسخ الـ Game ID
4. ضعه في `lib/services/ads_service.dart`

### 5. بناء التطبيق
```bash
# Debug
flutter build apk --debug

# Release (يحتاج keystore)
flutter build apk --release
flutter build appbundle --release
```

## 🔐 الخزنة السرية

للوصول للخزنة: **اضغط على أيقونة البطارية 5 مرات متتالية**

في أول مرة ستُطلب منك إنشاء رمز PIN من 6 أرقام.

## ☁️ Codemagic CI/CD

1. افتح https://codemagic.io
2. أضف المستودع
3. اختر `codemagic.yaml` كإعداد
4. أضف المتغيرات:
   - `UNITY_GAME_ID`
   - `CM_KEYSTORE_PASSWORD`
   - `CM_KEY_PASSWORD`
   - `CM_KEY_ALIAS`

## 📁 هيكل المشروع

```
lib/
├── main.dart                 # نقطة الدخول + Theme
├── l10n/
│   ├── app_en.arb           # النصوص الإنجليزية
│   └── app_ar.arb           # النصوص العربية
├── screens/
│   ├── home_screen.dart     # الشاشة الرئيسية + Navigation
│   ├── battery_screen.dart  # شاشة البطارية
│   ├── vault_screen.dart    # شاشة الخزنة السرية
│   └── settings_screen.dart # الإعدادات
├── services/
│   ├── battery_service.dart # خدمة البطارية
│   ├── vault_service.dart   # خدمة الخزنة
│   └── ads_service.dart     # خدمة الإعلانات
└── widgets/
    ├── battery_icon_widget.dart
    └── tip_card_widget.dart
```
