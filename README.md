# AppMaster — متجر تطبيقات بديل

<p align="center">
  <img src="docs/icon.png" width="120" alt="AppMaster"/>
</p>

<p align="center">
  <strong>تطبيق AppMaster — متجر التطبيقات البديل المفتوح المصدر</strong><br/>
  بناه <a href="https://t.me/auuua1">عباس عقيل</a> لقناة <a href="https://t.me/Appmasster">AppMaster</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17%2B-blue" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange" />
  <img src="https://img.shields.io/badge/SwiftUI-5-green" />
  <img src="https://img.shields.io/github/workflow/status/appmaster-dev/AppMaster/Build%20AppMaster%20IPA" />
</p>

---

## المميزات

| الميزة | الوصف |
|---|---|
| 🎮 أقسام تلقائية | الألعاب، التواصل الاجتماعي، التصميم، الأفلام، الأدوات |
| 🔗 مصادر متعددة | دعم AltStore JSON + AppMaster JSON |
| 📦 تثبيت IPA | من رابط أو ملف محلي عبر itms-services |
| 🔐 شهادة شخصية | P12 + Mobileprovision لكل مستخدم |
| 📱 عرض UDID | مثل AltStore تماماً |
| 🌍 6 لغات | العربية، الإنجليزية، الروسية، الصينية، الألمانية، الفارسية |
| 🎯 Cinemana | استبدال Bundle ID تلقائي عند التثبيت |

---

## البناء عبر GitHub Actions

### بدون Xcode / Mac محلي:

1. **Fork** هذا المستودع
2. اذهب إلى **Actions** → **Build AppMaster IPA**
3. اضغط **Run workflow**

### للبناء الموقّع (IPA حقيقي):

أضف هذه **Secrets** في إعدادات المستودع (Settings → Secrets and variables → Actions):

| Secret | الوصف |
|---|---|
| `CERTIFICATE_P12_BASE64` | ملف P12 مُشفَّر بـ Base64 |
| `CERTIFICATE_PASSWORD` | كلمة مرور ملف P12 |
| `PROVISIONING_PROFILE_BASE64` | ملف `.mobileprovision` مُشفَّر بـ Base64 |

> يجب أن يطابق نوع الـ provisioning profile خيار **Export method** عند تشغيل الـ workflow يدويًا (`ad-hoc`، `development`، أو `app-store`). معرف الفريق يُستخرَج تلقائيًا من الملف.

**تحويل الملفات إلى Base64 (على macOS):**
```bash
base64 -i MyCertificate.p12 | pbcopy
base64 -i MyApp.mobileprovision | pbcopy
```

### بناء IPA غير موقّع (بدون أسرار Apple) ثم التوقيع عندك

إذا أردت **ملف IPA فقط** من GitHub ثم **توقّعه بنفسك** على جهازك بأداتك وشهادتك:

1. من **Actions** اختر سير العمل **Build Unsigned IPA** ثم **Run workflow**.
2. بعد النجاح نزّل الـ artifact **AppMaster-unsigned-ipa** (الملف `AppMaster-unsigned.ipa`).
3. على جهازك استخدم أداة توقيع/تثبيت تدعم IPA (مثل **Sideloadly** أو **AltStore** أو أي أداة تستخدم **شهادتك وملف الـ provisioning**)، وحمّل هذا الـ IPA إليها ثم وقّع وثبّت.

> هذا المسار **لا يحتاج** أسرار `CERTIFICATE_*` أو `PROVISIONING_PROFILE_*` في GitHub. التوقيع النهائي يكون **عندك** وليس على سيرفر GitHub.

---

## هيكل المشروع

```
./
├── .github/workflows/
│   ├── build.yml              ← IPA موقّع (يتطلب أسرار Apple)
│   └── build-unsigned-ipa.yml ← IPA غير موقّع للتوقيع لاحقًا عندك
├── CI-unsigned.xcconfig       ← إعدادات بناء بدون توقيع (لـ CI فقط)
├── AppMaster.xcodeproj/
│   └── project.pbxproj
├── AppMaster/
│   ├── App/
│   │   ├── AppMasterApp.swift
│   │   └── AppState.swift
│   ├── Models/
│   │   └── Models.swift
│   ├── Services/
│   │   ├── StorageService.swift
│   │   ├── SourceService.swift
│   │   └── IPAInstaller.swift     ← شرط Cinemana هنا
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── Home/
│   │   │   ├── HomeView.swift
│   │   │   └── AppDetailView.swift
│   │   ├── Categories/
│   │   │   └── BrowseCategoriesView.swift
│   │   ├── Sources/
│   │   │   └── SourcesView.swift
│   │   ├── Install/
│   │   │   └── LibraryView.swift
│   │   └── Settings/
│   │       └── SettingsView.swift
│   ├── Resources/Localizations/
│   │   ├── ar.lproj/
│   │   ├── en.lproj/
│   │   ├── ru.lproj/
│   │   ├── zh-Hans.lproj/
│   │   ├── de.lproj/
│   │   └── fa.lproj/
│   ├── Assets.xcassets/
│   └── Info.plist
└── sources.json               ← ملف المصادر الرسمي
```

---

## إضافة تطبيقات للمتجر

عدّل ملف `sources.json` مباشرة. لكل تطبيق:

```json
{
  "id": "com.example.app",
  "name": "اسم التطبيق",
  "bundleID": "com.example.app",
  "version": "1.0.0",
  "description": "وصف التطبيق",
  "iconURL": "https://example.com/icon.png",
  "downloadURL": "https://example.com/app.ipa",
  "category": "games",
  "developer": "اسم المطور",
  "size": 50000000
}
```

**قيم `category` المتاحة:**
- `games` — الألعاب
- `social` — التواصل الاجتماعي  
- `design` — التصميم
- `entertainment` — الأفلام والمسلسلات
- `tools` — الأدوات
- `productivity` — الإنتاجية

---

## شرط Cinemana

أي تطبيق اسمه أو Bundle ID يحتوي على `cinemana` سيتم استبدال Bundle ID الخاص به تلقائياً بـ Bundle ID الشهادة المضافة عند التثبيت. هذا يضمن عمل التطبيق مع أي شهادة.

---

## التواصل

| | |
|---|---|
| 📣 القناة | [@Appmasster](https://t.me/Appmasster) |
| 👨‍💻 المطور | [@auuua1](https://t.me/auuua1) |

---

<p align="center">هذا التطبيق مُلك لقناة AppMaster</p>
