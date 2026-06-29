# اپلیکیشن Flutter اپ مشخصات محصول

این پوشه سورس اپلیکیشن است.

برای خروجی گرفتن نیازی نیست روی کامپیوتر Flutter نصب کنید. فایل GitHub Actions در ریشه پروژه خودش Flutter را نصب می‌کند و APK می‌سازد.

فایل اصلی اپلیکیشن:

```text
lib/main.dart
```

در نسخه فعلی، Android platform داخل ZIP قرار داده نشده و در زمان build با دستور زیر ساخته می‌شود:

```text
flutter create --platforms=android --project-name product_specs_app .
```

این کار داخل GitHub Actions خودکار انجام می‌شود.
