import 'package:dawaei/app/app.dart';
import 'package:dawaei/core/database/app_database.dart';
import 'package:dawaei/core/notifications/notification_scheduler.dart';
import 'package:dawaei/core/notifications/notification_service.dart';
import 'package:dawaei/features/doses/providers/doses_provider.dart';
import 'package:dawaei/features/doses/models/dose_record.dart';
import 'package:dawaei/features/medicines/models/medication.dart';
import 'package:dawaei/features/medicines/providers/medications_provider.dart';
import 'package:dawaei/features/settings/models/app_settings.dart';
import 'package:dawaei/features/settings/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

import 'support/memory_settings_store.dart';

Future<void> startApp(
  WidgetTester tester,
  MemorySettingsStore store, {
  double textScale = 1,
  List<Medication> medications = const [],
  bool holdAtSplash = false,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        onboardingCompletedProvider.overrideWith((ref) async => true),
        appStartupProvider.overrideWith((ref) async {
          await ref.watch(settingsProvider.future);
          await ref.watch(onboardingCompletedProvider.future);
        }),
        medicationsProvider.overrideWith(
          () => _StaticMedicationsController(medications),
        ),
        notificationSchedulerProvider.overrideWithValue(
          _NoopNotificationScheduler(),
        ),
        adherenceSummaryProvider.overrideWith(
          (ref, range) async => const AdherenceSummary(
            total: 4,
            taken: 3,
            skipped: 1,
            missed: 0,
            pending: 0,
          ),
        ),
        dosesForDateProvider.overrideWith(
          (ref, date) async => _testDoseRows(medications, date),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: const RepaintBoundary(
          key: Key('app-capture'),
          child: DawaeiApp(),
        ),
      ),
    ),
  );
  if (holdAtSplash) {
    await tester.pump();
  } else {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
}

List<DoseRecord> _testDoseRows(List<Medication> medications, DateTime date) {
  final output = <DoseRecord>[];
  var id = 1;
  for (final medication in medications) {
    for (final schedule in medication.schedules) {
      if (schedule.type == MedicationScheduleType.specificDays &&
          !schedule.weekdays.contains(date.weekday)) {
        continue;
      }
      final time = schedule.timeOfDay.split(':');
      final scheduled = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(time[0]),
        int.parse(time[1]),
      );
      output.add(
        DoseRecord(
          id: id,
          medicationId: medication.id ?? id,
          scheduleId: id,
          localDate:
              '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}',
          scheduledAtUtc: scheduled.toUtc().millisecondsSinceEpoch,
          timezoneId: 'Africa/Tripoli',
          medicationName: medication.name,
          dosageAmount: medication.dosageAmount,
          dosageUnit: medication.dosageUnit,
          status: DoseStatus.pending,
        ),
      );
      id++;
    }
  }
  return output;
}

class _StaticMedicationsController extends MedicationsController {
  _StaticMedicationsController(this.medications);
  final List<Medication> medications;

  @override
  Future<List<Medication>> build() async => medications;
}

class _NoopNotificationScheduler extends NotificationScheduler {
  _NoopNotificationScheduler()
    : super(AppDatabase(factory: databaseFactoryFfi), NotificationService());

  @override
  Future<void> reconcile() async {}
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    timezone_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Tripoli'));
  });

  testWidgets('branded splash remains for five seconds then opens the app', (
    tester,
  ) async {
    await startApp(tester, MemorySettingsStore(), holdAtSplash: true);
    expect(find.byKey(const ValueKey('brand-splash')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4900));
    expect(find.byKey(const ValueKey('brand-splash')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('splash assembles the logo and honors reduced motion', (
    tester,
  ) async {
    await startApp(tester, MemorySettingsStore(), holdAtSplash: true);
    var capsule = tester.widget<Opacity>(
      find.byKey(const ValueKey('splash-fragment-capsule')),
    );
    expect(capsule.opacity, 0);
    await tester.pump(const Duration(milliseconds: 1200));
    capsule = tester.widget<Opacity>(
      find.byKey(const ValueKey('splash-fragment-capsule')),
    );
    expect(capsule.opacity, greaterThan(0));

    await tester.pumpWidget(const SizedBox.shrink());
    await startApp(
      tester,
      MemorySettingsStore(),
      holdAtSplash: true,
      disableAnimations: true,
    );
    final scale = tester.widget<ScaleTransition>(
      find.byKey(const ValueKey('splash-logo-scale')),
    );
    final fade = tester.widget<FadeTransition>(
      find.byKey(const ValueKey('splash-final-logo')),
    );
    expect(scale.scale.value, 1);
    expect(fade.opacity.value, 1);
  });

  testWidgets('splash assembly fits a compact phone display', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startApp(tester, MemorySettingsStore(), holdAtSplash: true);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.byKey(const ValueKey('splash-final-logo')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shows the active medication reminder for today', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    await startApp(
      tester,
      MemorySettingsStore(),
      medications: [
        Medication(
          id: 7,
          name: 'Dashboard medicine',
          dosageAmount: '1',
          dosageUnit: 'tablet',
          startDate: today,
          schedules: [
            MedicationSchedule(
              type: MedicationScheduleType.daily,
              timeOfDay: '08:15',
            ),
          ],
        ),
      ],
    );
    expect(find.text('Dashboard medicine'), findsOneWidget);
    expect(find.textContaining('1 tablet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic is RTL and all four destinations open', (tester) async {
    await startApp(tester, MemorySettingsStore());
    expect(find.text('أهلاً بك في دوائي'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(NavigationBar))),
      TextDirection.rtl,
    );
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(find.text('بداية جديدة'), findsOneWidget);
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد جرعات في هذا اليوم'), findsOneWidget);
    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    expect(find.text('دوائي، على راحتك'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'switching language preserves the current tab and changes direction',
    (tester) async {
      final store = MemorySettingsStore();
      await startApp(tester, store);
      await tester.tap(find.byIcon(Icons.tune_rounded).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language-en')));
      await tester.pumpAndSettle();
      expect(find.text('Make yourself at home'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(NavigationBar))),
        TextDirection.ltr,
      );
      expect(store.value.languageCode, 'en');
      await tester.ensureVisible(find.byKey(const Key('theme-dark')));
      await tester.tap(find.byKey(const Key('theme-dark')));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(NavigationBar))).brightness,
        Brightness.dark,
      );
      expect(store.value.themeMode, ThemeMode.dark);
    },
  );

  testWidgets('startup error offers a working retry', (tester) async {
    final store = MemorySettingsStore()..failLoad = true;
    await startApp(tester, store);
    expect(find.byKey(const Key('startup-error-message')), findsOneWidget);
    store.failLoad = false;
    await tester.tap(find.byKey(const Key('startup-retry')));
    await tester.pumpAndSettle();
    expect(find.text('أهلاً بك في دوائي'), findsOneWidget);
  });

  for (final locale in ['ar', 'en']) {
    testWidgets('$locale fits a small screen at large text size', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await startApp(
        tester,
        MemorySettingsStore(AppSettings(languageCode: locale)),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.byType(NavigationBar)),
        ).scale(16),
        32,
      );
      for (final index in [1, 2, 3]) {
        await tester.tap(find.byType(NavigationDestination).at(index));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('privacy opens and back returns to settings', (tester) async {
    await startApp(
      tester,
      MemorySettingsStore(const AppSettings(languageCode: 'en')),
    );
    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Privacy'));
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
    expect(find.text('Your privacy matters'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Make yourself at home'), findsOneWidget);
  });

  testWidgets('failed preference save shows a message and retains Arabic', (
    tester,
  ) async {
    final store = MemorySettingsStore()..failSave = true;
    await startApp(tester, store);
    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-en')));
    await tester.pumpAndSettle();
    expect(find.text('تعذّر حفظ الإعداد. حاول مجدداً.'), findsOneWidget);
    expect(store.value.languageCode, 'ar');
    expect(
      Directionality.of(tester.element(find.byType(NavigationBar))),
      TextDirection.rtl,
    );
  });
}
