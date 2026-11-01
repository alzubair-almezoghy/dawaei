# دوائي — القرارات المعمارية وخطة التنفيذ

تاريخ المراجعة: 28 أكتوبر 2026. اكتملت مراحل الأساس وإدارة الأدوية والواجهة والتذكيرات وسجل الجرعات (1–5). المرحلة السادسة تشمل اختبار Android الفعلي وتجهيز الإصدار، وما زالت مطلوبة.

## حالة التنفيذ الفعلية حتى Phase 5

- `AppDatabase` يستخدم `sqflite` مع `schemaVersion = 3`، foreign keys، وترقيات متسلسلة من v1 إلى v3 دون destructive downgrade. أضيف `effective_to_utc` في v2 وسجل `notification_jobs` في v3.
- `medications` يخزن الاسم والكمية كوصف نصي والوحدة والشكل والتواريخ والتعليمات واللون والمنطقة الزمنية والحالة وتواريخ UTC.
- نسخ الجداول محفوظة في `medication_schedule_sets`. كل تعديل ينهي النسخة الفعالة ويضيف نسخة جديدة؛ `medication_schedules` يخزن كل ساعة منفصلة و` schedule_days` يطبع أيام الأسبوع ISO. الإيقاف ينهي النسخة؛ الاستئناف ينسخ آخر جدول محفوظ إلى نسخة فعالة.
- `dose_records` يشير إلى medication وschedule مع `ON DELETE RESTRICT`، ويحفظ snapshot الاسم والكمية والوحدة والشكل والتعليمات. يمنع `UNIQUE(schedule_id, local_date)` تكرار نفس الموعد المحلي. `DoseRepository` يولد اليوم عند فتح لوحة اليوم أو يوم في السجل، ويحترم تاريخ نسخة الجدول وtimezone، ويحدث pending إلى missed فقط بعد نهاية اليوم المحلي.
- واجهات Phase 2 توفر إضافة وتعديل وتفاصيل وإيقاف واستئناف وأرشفة ناعمة. الحذف يحتفظ بمفاتيح السجل، فلا تُزال المعلومات التاريخية المرتبطة.
- لوحة اليوم تعرض عدد الجرعات وتأكيدات تناولها، ويمكن تأكيد الجرعة أو تسجيل تخطيها بعد حلول موعدها. سجل التاريخ يتيح التنقل اليومي وعرض ملخص أسبوعي أو شهري. النسبة هي taken ÷ الجرعات التي حل موعدها فقط، ولا تحول الإشعارات الجرعة إلى taken.
- اختبارات SQLite تشمل CRUD، حماية مراجع الجرعات عند تعديل الجدول، منع التكرار، pause/resume، الأرشفة، تأكيد الحالات، ومنع تأكيد جرعة مستقبلية، والترقية من v1 إلى v3 في sqflite_common_ffi.

الحزم الحالية تشمل `sqflite` و`path` للمسار المحلي؛ إعدادات التطبيق تبقى في SharedPreferences. حزم المناطق الزمنية والإشعارات مستخدمة في planner وnotification service. تكامل الإشعارات native لم يُختبر على Android بعد.

## 1. النطاق والقرارات

تطبيق Android يعمل offline، دون حساب أو backend أو Firebase. لغة البداية العربية، مع الإنجليزية. البيانات الصحية لا تخرج من التطبيق. لا توجد توصيات جرعات أو تشخيصات.

المشروع بدأ في مجلد فارغ. Flutter المثبّت 3.29.2 stable وDart 3.7.2. نستخدم إصدارات مستقرة يحلّها Pub لهذا SDK ونثبت الحل في `pubspec.lock`. هذا لا يعني أن النسخ المختارة هي الأحدث عالمياً. ترقية SDK وفحص Android 16 شرط قبل النشر، ولا نعدّل تثبيت المستخدم العام تلقائياً.

المعرّف المبدئي `app.dawaei.dawaei`. لا نملك دليلاً على ملكية نطاق dawaei.app أو توفر المعرّف في Play. يجب اعتماد هوية الناشر قبل أول رفع، لأن تغيير applicationId بعد النشر يعني تطبيقاً مختلفاً. الحد الأدنى المختار Android 7 / API 24.

لا نطلب اسم المستخدم في الأساس: الترحيب عام، ويمكن إضافة اسم محلي اختياري لاحقاً. خط النظام يدعم العربية ويعمل دون تنزيل؛ إضافة Cairo أو Tajawal لاحقاً تتطلب تضمين ملف الخط وترخيصه.

## 2. فصل المسؤوليات

المسار المعتاد: Screen → Riverpod Controller/Provider → Repository → SQLite.

- Screen: العرض، إدخال المستخدم، رسائل التحميل والخطأ، والتنقّل.
- Widget: عنصر مرئي قابل لإعادة الاستخدام، دون SQL أو استدعاءات Android مباشرة.
- Provider: حقن الاعتماديات وتحديث الحالة عند تغيّر البيانات. نستخدم Notifier/AsyncNotifier دون code generation في هذه المرحلة لتقليل أدوات البناء.
- Repository: المعاملات والتحويل بين نماذج Dart وصفوف SQLite.
- RecurrenceEngine: منطق Dart مستقل عن الواجهة؛ يأخذ ساعة قابلة للحقن ومنطقة IANA ونطاق تواريخ ويعيد occurrences.
- NotificationScheduler: يطابق الجرعات المستقبلية المطلوبة مع إشعارات Android.
- NotificationService: غلاف حول flutter_local_notifications يمكن استبداله في الاختبارات.

SQLite هو مصدر الحقيقة للأدوية والجرعات. SharedPreferencesAsync يحفظ إعدادات غير حساسة فقط. لا نخزن الحالة الصحية في SharedPreferences. نستخدم logger لأسماء أحداث ثابتة في debug فقط؛ لا نمرر أسماء أدوية أو نصوص أخطاء خام أو SQL يحتوي بيانات صحية.

## 3. التصميم الأولي المقترح (مرجع تاريخي فقط)

المخطط التفصيلي في هذا القسم مرجع تاريخي لما قبل التنفيذ. مصدر الحقيقة للمخطط الحالي هو قسم «حالة التنفيذ الفعلية حتى Phase 5» في أعلى الملف؛ الجداول ونمط النسخ الفعالة تغيّرا قبل كتابة migrations.

```text
medications 1 ───── N medication_schedules 1 ───── N dose_records
     │                                                │
     └────────────────────── 1 ───── N ────────────────┘
dose_records 1 ───── 0..1 notification_jobs
```

قاعدة واحدة `dawaei.db` مع version وmigrations داخل `core/database/migrations/`. تفعيل `PRAGMA foreign_keys = ON` في onConfigure. جميع عمليات تعديل الدواء وجدوله تكون في transaction واحدة. التغييرات في Android تأتي بعد commit عبر reconciliation قابل لإعادة التنفيذ.

**medications**

- `id INTEGER PRIMARY KEY AUTOINCREMENT`.
- `name`, `dosage_amount`, `dosage_unit`: TEXT NOT NULL مع تحقق من النص غير الفارغ. الجرعة تبقى نصاً؛ لا نحسب وصفة طبية.
- `medication_form`, `notes`, `color_value`.
- `start_date`, `end_date`: تاريخ مدني `YYYY-MM-DD`، البداية مشمولة والنهاية مشمولة؛ النهاية لا تسبق البداية.
- `is_active INTEGER CHECK (is_active IN (0,1))`, `deleted_at_utc` للأرشفة.
- `created_at_utc`, `updated_at_utc`: INTEGER milliseconds since epoch.

**medication_schedules**

- `id INTEGER PRIMARY KEY AUTOINCREMENT`، `medication_id` foreign key مع ON DELETE RESTRICT.
- `schedule_group_id`: يجمع مراجعات نفس الموعد المنطقي.
- `schedule_type`: CHECK ضمن `daily`, `multiple_daily`, `weekdays`.
- `minute_of_day INTEGER CHECK (minute_of_day BETWEEN 0 AND 1439)`؛ صف مستقل لكل وقت.
- `weekdays_mask INTEGER`: أيام ISO، الاثنين=1 إلى الأحد=7. غير صفري لنوع weekdays؛ كل الأيام للنوع اليومي.
- `effective_from_utc`, `effective_to_utc`: نطاق فعالية نصف مفتوح `[from,to)`.
- `is_enabled INTEGER CHECK (is_enabled IN (0,1))`.
- فهرس على medication_id ونطاق الفعالية. نرفض الوقت المكرر داخل نفس مجموعة الدواء والأيام المتطابقة.

**dose_records**

- `id INTEGER PRIMARY KEY AUTOINCREMENT`.
- `medication_id`, `schedule_id`: مفاتيح خارجية ON DELETE RESTRICT؛ لا نحذف مرجع سجل تاريخي.
- `local_date TEXT`, `scheduled_at_utc INTEGER`, `timezone_id TEXT`, `utc_offset_minutes INTEGER`.
- snapshots: `medication_name`, `dosage_amount`, `dosage_unit`, `medication_form`, `instructions`، للحفاظ على النص كما كان عند الموعد.
- `status TEXT CHECK (status IN ('pending','taken','skipped','missed'))`.
- `taken_at_utc`, `confirmed_at_utc`, `created_at_utc`, `updated_at_utc`.
- `UNIQUE(schedule_id, local_date)` يمنع تكرار occurrence. صف schedule يمثل وقتاً واحداً والساعة المكررة في DST تُنفّذ مرة واحدة.
- فهارس على `scheduled_at_utc`, `(local_date,status)`, `medication_id`.
- CHECK: taken_at مطلوب فقط عند status=taken. التحديث إلى taken/skipped يتم بفعل صريح من المستخدم، وبشكل idempotent.

**notification_jobs**

- `dose_id` PRIMARY KEY وforeign key؛ نستخدمه أيضاً كمعرّف Android إذا كان ضمن 31-bit موجب.
- `desired_state`, `applied_state`, `updated_at_utc`, `last_attempt_at_utc`.
- تخزين نية الإضافة/الإلغاء داخل transaction يتيح إصلاح الفشل بين SQLite وAndroid. لا توجد transaction واحدة تجمع النظامين.
- عدم استخدام hash الاسم أو الوقت كمعرّف؛ AUTOINCREMENT لا يعيد استخدام المعرّفات. عند اقتراب الحد الأقصى نرفض التخطيط برسالة واضحة بدلاً من collision.

المخطط أعلاه تصميم موثّق، وليس قاعدة بيانات منفّذة في المرحلة الأولى. SQL والقيود الدقيقة واختبارات migration تُضاف معاً في المرحلة الثانية. لا نستخدم destructive migration عند فشل الترقية؛ نحتفظ بالملف ونعرض مسار استعادة.

## 4. توليد الجرعات والحفاظ على التاريخ

1. نقرأ الجداول الفعالة ضمن تاريخ الدواء وأيام الأسبوع.
2. نكوّن موعد TZDateTime من التاريخ المحلي وminute_of_day.
3. نحفظ occurrence في transaction باستخدام INSERT OR IGNORE على المفتاح الفريد؛ نقرأ السجل الموجود عند التكرار.
4. نولّد المستقبل لأفق الإشعارات فقط، ونولّد التاريخ منذ آخر reconciliation على دفعات محدودة الحجم. لا نعتبر الجرعات القديمة قبل إنشاء الجدول مستحقة.
5. عند تعديل الاسم أو الجرعة: تبقى snapshots الماضية كما هي؛ نعيد بناء pending المستقبلية فقط.
6. عند تغيير الوقت: نغلق نسخة الجدول القديمة في لحظة التعديل، وننشئ نسخة جديدة فعالة من تلك اللحظة. لا نعيد إنشاء جرعات قبلها، ونلغي الوظائف المستقبلية للنسخة القديمة.
7. pause/delete: إلغاء الإشعارات المستقبلية وإزالة occurrences المستقبلية غير المؤكدة من حساب المستحق، مع حفظ كل الماضي. resume يبدأ من لحظة الاستئناف؛ لا ينتج جرعات وهمية أثناء الإيقاف.
8. حذف دواء من القائمة هو أرشفة مع تأكيد وإيضاح أن السجل محفوظ. حذف جميع البيانات خيار مستقل نهائي مع تأكيد، ويلغي الإشعارات أولاً.

تحديث pending المستقبلية عند تغيير timezone لا يعيد تأكيد جرعة سبق تسجيلها. المفتاح المحلي لا يضم اسم المنطقة لتجنّب تكرار الجرعة لنفس اليوم عند السفر. الوقائع الماضية وconfirmed لا تُعاد كتابتها. يجب اختبار عبور خط التاريخ الدولي ضمن مراجعة السفر.

## 5. الزمن وحالات الجرعات

- الوقت اليومي يتبع **ساعة الجهاز المحلية** عند السفر، وليس فاصلاً ثابتاً مثل «كل 24 ساعة». لا ندعم في الإصدار الأول جداول كل N ساعة.
- نخزّن المناطق كأسماء IANA مثل Africa/Tripoli؛ ليست offsets ثابتة.
- timestamps: UTC milliseconds. تواريخ البداية/النهاية والأيام: تواريخ محلية صريحة.
- DST spring gap: ننقل الموعد بقدر الفجوة إلى أول وقت مقابل موجود بعد القفزة، ونوضح التعديل للمستخدم. DST overlap: أول ظهور للوقت فقط. نتحقق صراحة من سلوك مكتبة timezone بالاختبارات؛ لا نعتمد على normalization ضمني.
- قبل الوقت: pending. بعد الوقت وحتى نهاية اليوم المحلي المحدد للجرعة: pending مع شارة «متأخرة». عند نهاية اليوم في المنطقة المسجلة: missed إذا لم يوجد تأكيد.
- missed تعني «لم تُؤكد»، ولا تعني إثبات عدم تناول الدواء. يمكن تصحيحها يدوياً مع حفظ وقت التأكيد، ودون توصية بتناول جرعة متأخرة.
- adherence اليومي = taken / الجرعات المستحقة حتى الآن؛ الجرعات المستقبلية لا تدخل المقام. skipped وmissed وpending المتأخرة تدخل المقام. لا نعرض 100% عند مقام صفر؛ نعرض «لا توجد جرعات مستحقة».
- الأسبوع والشهر: مجموع taken ÷ مجموع المستحق في النطاق، وليس متوسط النسب اليومية. فترات التقارير تعتمد local_date المحفوظ.

## 6. التذكيرات — المرحلة الرابعة

الأفق: أقرب 7 أيام أو 200 إشعار، أيهما يبلغ الحد أولاً، مرتبة زمنياً على مستوى كل الأدوية. هذا سقف احترازي للمنتج، وليس ادعاء أن كل أجهزة Android لها الحد نفسه. لو الكثافة قصّرت الأفق نعرض آخر تاريخ مغطّى بوضوح.

التجديد عند: فتح التطبيق، العودة للمقدمة، تعديل دواء، تأكيد جرعة، تغيير إعدادات الإشعارات أو المنطقة الزمنية المكتشف عند العودة. لا نعتمد على callback Flutter عند وصول إشعار. لا يوجد تنفيذ دوري مضمون في الخلفية؛ لو ظل التطبيق مغلقاً بعد نهاية الأفق فقد تتوقف التذكيرات. يلزم تحذير داخل التطبيق واختبار قابلية هذه السياسة قبل اعتمادها تجارياً. إضافة WorkManager مستقبلاً تحسين best-effort وليست ضماناً.

المطابقة: مقارنة desired jobs مع pendingNotificationRequests، إلغاء القديم ثم جدولة الناقص بالمعرّف الثابت نفسه؛ إعادة المحاولة آمنة بعد crash. عند الخطأ نعرض تدهور تغطية الإشعارات ولا ندّعي أن الجدولة نجحت.

- Android 13+: طلب POST_NOTIFICATIONS في سياق واضح، والتعامل مع الرفض.
- Android 12+: عند الحاجة للدقة نطلب SCHEDULE_EXACT_ALARM باختيار المستخدم؛ إن رُفضت أو سُحبت نستخدم inexactAllowWhileIdle مع توضيح احتمال التأخير.
- لا نعلن USE_EXACT_ALARM أو full-screen intent أو صلاحية تجاوز البطارية تلقائياً. سياسة Play تقيّد USE_EXACT_ALARM.
- إعداد receivers الخاصة بالحزمة، RECEIVE_BOOT_COMPLETED وMY_PACKAGE_REPLACED حسب الوثائق للنسخة المختارة. استعادة boot تستعيد الأفق المحفوظ فقط؛ لا تجدده للأبد. force-stop يلغي التسليم حتى إعادة فتح التطبيق وفق سلوك Android؛ بعض الشركات أكثر تقييداً.
- تغير timezone أثناء إغلاق التطبيق لا يضمن إعادة بناء wall-clock alarms فوراً؛ هذا قيد يجب إظهاره واختباره. نفحص المنطقة عند الاستئناف ونصالح المستقبل فقط.
- قناة notifications بخصوصية lock-screen افتراضية private ومحتوى public عام؛ تفاصيل الدواء داخل الجهاز بعد الفتح. معاينة محتوى حساس opt-in لاحقاً.
- payload بمعرّف dose فقط، دون اسم أو جرعة. عند النقر: استعادة البيانات ثم الانتقال `/doses/:id`؛ إذا أُلغي الموعد نعرض حالة مفهومة. يدعم المسار فتحاً بارداً وفتحاً أثناء التشغيل.
- لا أزرار تأكيد في الخلفية في الإصدار الأول. النقر يفتح التطبيق؛ taken لا تُسجّل تلقائياً.

## 7. الخصوصية

لا INTERNET permission في manifest الرئيسي، ولا شبكة أو telemetry في كود التطبيق. manifest debug/profile يحتوي INTERNET لأدوات Flutter فقط. بيانات التطبيق معزولة بصلاحيات Android؛ SQLite وpreferences ليستا تشفيراً على مستوى التطبيق. لا نَدّعي حماية على جهاز مخترق أو غير مقفل.

allowBackup=false، استبعاد full backup القديم، واستبعادات cloud/device-transfer في dataExtractionRules للأنظمة الحديثة. السلوك الفعلي يُراجع على الأجهزة المستهدفة. مسح البيانات داخل التطبيق مع إلغاء الإشعارات ضمن مرحلة التخزين؛ في الأساس يوجد شرح لطريقة Clear storage من Android.

## 8. الملفات الحالية والهيكل النهائي

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme/app_colors.dart
    theme/app_theme.dart
  core/
    database/app_database.dart
    database/migrations/{v1_initial,v2_schedule_history,v3_notification_jobs}.dart
    notifications/{notification_service,notification_scheduler}.dart
    constants/app_info.dart
    utils/app_log.dart
  features/
    home/screens/home_screen.dart
    medicines/screens/medicines_screen.dart
    medicines/screens/medication_form_screen.dart
    medicines/screens/medication_details_screen.dart
    medicines/data/medication_repository.dart
    medicines/providers/medications_provider.dart
    medicines/models/medication.dart
    doses/screens/history_screen.dart
    doses/data/dose_repository.dart
    doses/providers/doses_provider.dart
    doses/models/dose_record.dart
    settings/
      models/app_settings.dart
      data/settings_store.dart
      providers/settings_provider.dart
      screens/settings_screen.dart
      screens/information_screen.dart
  l10n/
    app_ar.arb
    app_en.arb
    generated/                  # ناتج flutter gen-l10n
  shared/widgets/
    app_shell.dart
    page_content.dart
    empty_state.dart
test/
  app_test.dart
  dose_repository_test.dart
  medication_repository_test.dart
  notification_scheduler_test.dart
  settings_controller_test.dart
  support/memory_settings_store.dart
```

## 9. الحزم

| الحزمة | الغرض | متى |
| --- | --- | --- |
| flutter_riverpod | الحالة وحقن الاعتماديات | المرحلة 1 |
| go_router | مسارات مستقلة وstateful bottom navigation | المرحلة 1 |
| flutter_localizations | اتجاه النص وترجمة عناصر Flutter | المرحلة 1 |
| intl | التواريخ والأرقام حسب اللغة | المرحلة 1 |
| shared_preferences | إعدادات اللغة والثيم فقط، Async API | المرحلة 1 |
| logger | أحداث تطوير عامة، معطّل في release | المرحلة 1 |
| sqflite | SQLite والمعاملات والمهاجرات | المرحلة 2 |
| timezone | تكرار المواعيد وفق IANA وDST | المرحلة 2 |
| flutter_timezone | اكتشاف منطقة الجهاز؛ يعيد TimezoneInfo في الوثائق الحديثة | المرحلة 4 |
| flutter_local_notifications | إشعارات Android المحلية | المرحلة 4 |
| flutter_test / flutter_lints | الاختبارات والتحليل | المرحلة 1 |
| sqflite_common_ffi + integration_test | اختبار SQL على المضيف والتحقق على Android | المرحلة 2 |

لا نثبّت plugins أصلية قبل مرحلة استخدامها لتجنّب صلاحيات أو إعدادات Gradle غير مكتملة. تُراجع النسخة وAPI لكل حزمة عند إضافتها. النسخ المحلولة الفعلية موجودة في pubspec.lock، والقيود المباشرة في pubspec.yaml.

## 10. خطة التسليم ومعايير القبول

1. **الأساس:** مشروع Android، Riverpod، التنقّل بأربع وجهات، ترجمة ARB، RTL/LTR، الثيمات، إعدادات محفوظة، حالات تحميل وخطأ، أسماء وأيقونة أولية. قبول: analyze واختبارات الحالة والواجهات. لا وظائف أدوية أو تذكيرات بعد.
2. **البيانات:** schema + migration tests + models + repositories + recurrence + CRUD مع add/edit قابلين للاستخدام. اختبار duplicate وpause/delete وsnapshots وDST. قبول: بيانات محفوظة بعد إعادة الفتح واختبار Android SQL.
3. **الواجهات الكاملة:** dashboard فعلي، form مع تحقق، تفاصيل، active/paused، date/time pickers، حذف بتأكيد وdata reset. قبول: مسارات CRUD كاملة وإتاحة عند تكبير النص.
4. **التذكيرات — مكتملة برمجياً:** permissions، channels، الخصوصية، bounded planner، فتح التطبيق من الإشعار، واستعادة boot/update. اختبار الأجهزة الفعلية ما زال مطلوباً.
5. **السجل — مكتمل برمجياً:** تأكيد taken/skipped، pending/overdue/missed، اختيار اليوم، وملخص أسبوعي وشهري. اختبارات SQL والواجهة ناجحة؛ اختبار Android الفعلي ما زال مطلوباً.
6. **النهائي — قيد الإنجاز:** مراجعة الأمان والإتاحة، ترقية SDK/target، توقيع release، AAB، سياسة خصوصية منشورة، Data Safety وHealth declaration، واختبار مغلق ومراجعة سياسة Play.

هذه مراحل عمل وليست تقديراً زمنياً مضللاً. الإشعارات واختلافات أجهزة Android تتطلب وقت اختبار مستقل، ولا ننقل build تأسيسي إلى production باعتباره تطبيقاً مكتملاً.

## 11. الاختبارات

تلقائياً: validation، CRUD، migrations من قاعدة قديمة seeded، foreign keys وCHECK/UNIQUE، immutable history، daily/multiple/weekday recurrence، end dates، pause/resume، idempotent planner/cancellation، rollback عند الفشل، taken/skipped، adherence، DST gap/overlap، السفر، RTL/LTR، تكبير النص، التنقّل وحفظ الإعدادات.

على Android فعلي: permission deny/revoke، exact/inexact وDoze، force-stop، reboot، update، background/terminated notification tap، lock screen، battery saver، timezone change أثناء الإغلاق، تطبيقات الشركات، upgrade ومحو البيانات. نختبر Android 7 كحد أدنى، 12 و13 و14 و16، وأجهزة Pixel/Samsung وغيرها حسب المتاح. المحاكاة لا تثبت تسليم الإشعارات على جهاز حقيقي.

## 12. مراجع موثوقة تمت مراجعتها

- [Flutter Android setup](https://docs.flutter.dev/platform-integration/android/setup)
- [Riverpod](https://riverpod.dev/docs/introduction/getting_started)
- [go_router](https://pub.dev/packages/go_router)
- [SharedPreferencesAsync](https://pub.dev/packages/shared_preferences)
- [sqflite](https://pub.dev/packages/sqflite)
- [flutter_local_notifications setup and limitations](https://pub.dev/packages/flutter_local_notifications)
- [flutter_timezone](https://pub.dev/packages/flutter_timezone)
- [Flutter Android release](https://docs.flutter.dev/deployment/android)
- [Exact alarm policy](https://support.google.com/googleplay/android-developer/answer/16558241?hl=en)
- [Target SDK policy](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en-sg)
- [Health declaration](https://support.google.com/googleplay/android-developer/answer/14738291?hl=en)
- [Health app privacy requirements](https://support.google.com/googleplay/android-developer/answer/18258653?hl=en-GB)
