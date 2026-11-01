# دوائي — المرحلة الثالثة

هذا مشروع Flutter فعلي داخل هذا المجلد، مش مجرد مقتطفات كود. المكتمل: أساس التطبيق، وقاعدة SQLite بإصدارات migrations، وإدارة الأدوية وجداولها، وواجهة لوحة اليوم وقائمة الأدوية والتفاصيل والإعدادات. تعرض لوحة اليوم جداول التذكير الفعالة لهذا اليوم بترتيب الوقت.

تتضمن هذه النسخة تذكيرات محلية محدودة وسجل جرعات يومياً مع تأكيد التناول أو التخطي. صفحة السجل تعرض ملخصاً أسبوعياً وشهرياً؛ ولا يسجل التطبيق تناول الدواء تلقائياً عند وصول الإشعار.

## 1. افتح المجلد وشغّل الفحوصات

في PowerShell، ادخل للمجلد اللي فيه هذا الملف وpubspec.yaml:

```powershell
flutter --version
flutter pub get
flutter gen-l10n
dart analyze
flutter test --concurrency=1
flutter devices
flutter run -d <android-device-id>
```

استبدل `<android-device-id>` بمعرّف جهاز Android من `flutter devices`. فعّل USB debugging على الهاتف، أو شغّل Android emulator. `pub get` ينزّل الحزم، و`gen-l10n` يولّد كود الترجمة من ARB، و`analyze` يفحص الكود، و`test` يشغّل اختبارات آلية. `run` يبني نسخة debug على الجهاز.

لو Android SDK مش جاهز: افتح Android Studio → SDK Manager وثبّت SDK Platform وBuild Tools وPlatform Tools وCommand-line Tools، ثم `flutter doctor -v` و`flutter doctor --android-licenses` وراجع نتائجهم. [دليل الإعداد الرسمي](https://docs.flutter.dev/platform-integration/android/setup).

المشروع أُنشئ بـ:

```powershell
flutter create --no-pub --platforms=android --org app.dawaei --project-name dawaei outputs/dawaei
```

ومن داخل مجلد المشروع تمت إضافة حزم الأساس باستخدام:

```powershell
flutter pub add flutter_riverpod go_router shared_preferences intl logger
```

flutter_localizations اعتماد من Flutter SDK داخل pubspec.yaml. الإصدارات الفعلية في pubspec.lock؛ احتفظ به مع التطبيق. لا تستخدم dependency_overrides لإجبار حزمة على SDK غير مدعوم.

## 2. وين تلقى كل جزء؟

- `lib/main.dart`: تشغيل التطبيق داخل ProviderScope.
- `lib/app/app.dart`: MaterialApp، تحميل الإعدادات، اللغة والثيم وحالة الخطأ.
- `lib/app/router.dart`: مسارات الصفحات الأربعة وصفحات الخصوصية والتعريف، مع صفحة خطأ للروابط غير المعروفة.
- `lib/app/theme/`: ألوان وتصميم موحّد. أخضر الهوية 009688 والأزرار بأخضر أغمق للتباين.
- `lib/features/home/screens/home_screen.dart`: الواجهة الرئيسية الفارغة وتاريخ اليوم؛ يتجدد عند منتصف الليل والرجوع للتطبيق.
- `lib/features/medicines/screens/medicines_screen.dart`: قائمة الأدوية المحفوظة وحالة القائمة الفارغة.
- `lib/features/medicines/screens/medication_form_screen.dart`: إضافة وتعديل الدواء وجدول المواعيد.
- `lib/features/medicines/screens/medication_details_screen.dart`: التفاصيل والإيقاف والاستئناف والأرشفة.
- `lib/features/medicines/data/medication_repository.dart`: معاملات SQLite وسجل نسخ الجداول.
- `lib/core/database/migrations/`: إنشاء قاعدة البيانات وترقيتها دون حذف البيانات السابقة.
- `lib/features/doses/screens/history_screen.dart`: حالة السجل الفارغ مع توضيح التأكيد الصريح.
- `lib/features/settings/`: نموذج الإعدادات، التخزين المحلي، Riverpod، وواجهات الإعدادات والتعريف.
- `lib/l10n/app_ar.arb` و`app_en.arb`: عدّل النص هنا ثم شغّل `flutter gen-l10n`. لا تعدّل ملفات generated يدوياً.
- `lib/shared/widgets/`: غلاف التنقّل ومكونات الصفحات والحالات الفارغة.
- `lib/core/constants/app_info.dart`: رقم الإصدار؛ يجب أن يطابق pubspec.yaml.
- `lib/core/utils/app_log.dart`: تسجيل أحداث ثابتة في التطوير فقط.
- `android/app/src/main/AndroidManifest.xml`: اسم وأيقونة التطبيق وإعدادات الخصوصية. صلاحيات الإشعارات تُضاف في مرحلتها.
- `test/`: اختبارات الحالة والتنقّل واللغات والثيمات وتكبير النص والتعامل مع الفشل.

المسارات الكاملة لكل ملفات التسليم موجودة في `docs/FILES.ar.md`. الأرشيف المرفق يحتوي ملفات المصدر والـlock والمعاينات، ويستبعد build والكاش وإعدادات الجهاز المحلية.

## 3. كيف تتأكد من النتيجة على الهاتف؟

افتح التطبيق: المفروض يبدأ بالعربية. بدّل بين الصفحات، ثم افتح الإعدادات وغيّر للإنجليزية وتأكد إن الاتجاه تغيّر. اختار الداكن، اقفل التطبيق وافتحه وتأكد إن الاختيارات محفوظة. جرّب وضع الجهاز الداكن مع اختيار «حسب الجهاز». جرّب أكبر خط وTalkBack. افتح الخصوصية ثم ارجع، وتأكد إنك ما زلت في صفحة الإعدادات.

اختبارات الذاكرة تتحقق من منطق حفظ الحالة عبر إعادة إنشاء Providers؛ اختبار plugin الحقيقي واستمرار الإعدادات بعد إغلاق العملية يحتاج جهاز Android. نتائج التنفيذ الفعلية وحدوده موجودة في `docs/VALIDATION.ar.md`.

## 4. القرارات والخطوة القادمة

اقرأ `docs/ARCHITECTURE.ar.md` للتصميم النهائي: العلاقات، حماية السجل القديم، أوقات UTC والمحلية، overdue/missed، منع التكرار، أفق الإشعارات وحدود Android، الحزم، وهيكل كل المراحل.

الخطوة التالية هي إنشاء سجلات الجرعات وحالات taken/skipped/missed وواجهة التاريخ؛ بعدها نضيف الإشعارات المحلية بجدولة محدودة. نتائج الاختبارات وحالة بناء Android الحالية موجودة في `docs/VALIDATION.ar.md`.

راجع `docs/RELEASE.ar.md` قبل النشر. النسخة الحالية ليست جاهزة لـGoogle Play، وترقية SDK والتحقق من متطلبات API 36 واختبارات الأجهزة لازمة قبل الإصدار.
