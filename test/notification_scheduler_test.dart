import 'dart:io';

import 'package:dawaei/core/database/app_database.dart';
import 'package:dawaei/core/notifications/notification_scheduler.dart';
import 'package:dawaei/core/notifications/notification_service.dart';
import 'package:dawaei/features/medicines/data/medication_repository.dart';
import 'package:dawaei/features/medicines/models/medication.dart';
import 'package:dawaei/features/settings/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late Directory directory;
  late AppDatabase appDatabase;

  setUpAll(() {
    sqfliteFfiInit();
    timezone_data.initializeTimeZones();
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dawaei-notifications-');
    appDatabase = AppDatabase(
      factory: databaseFactoryFfi,
      path: p.join(directory.path, 'test.db'),
    );
  });

  tearDown(() async {
    await appDatabase.close();
    await directory.delete(recursive: true);
  });

  test(
    'plans local daily and weekday occurrences in time order and caps the horizon',
    () {
      final zone = tz.getLocation('Africa/Tripoli');
      final now = tz.TZDateTime(zone, 2026, 10, 26, 7).toUtc();
      final sources = [
        _source(scheduleId: 1, medicationId: 10, name: 'Daily', time: '08:00'),
        _source(
          scheduleId: 2,
          medicationId: 11,
          name: 'Twice weekly',
          time: '09:30',
          type: 'specific_days',
          weekdays: {1, 5},
        ),
      ];

      final planned = NotificationOccurrencePlanner.plan(
        sources: sources,
        nowUtc: now,
        deviceTimezoneId: 'Africa/Tripoli',
      );
      expect(planned, hasLength(9));
      expect(planned.first.localDate, '2026-10-26');
      expect(planned.first.medicationName, 'Daily');
      expect(planned.last.localDate, '2026-11-01');
      expect(planned.map((item) => item.occurrenceKey).toSet(), hasLength(9));
      expect(
        NotificationOccurrencePlanner.plan(
          sources: sources,
          nowUtc: now,
          deviceTimezoneId: 'Africa/Tripoli',
          limit: 3,
        ),
        hasLength(3),
      );
    },
  );

  test(
    'normalizes a daylight-saving gap and chooses one repeated wall time',
    () {
      final zone = tz.getLocation('America/New_York');
      final spring = NotificationOccurrencePlanner.plan(
        sources: [_source(scheduleId: 1, medicationId: 1, time: '02:30')],
        nowUtc: tz.TZDateTime(zone, 2026, 3, 8, 0).toUtc(),
        deviceTimezoneId: 'America/New_York',
        horizonDays: 1,
      );
      expect(spring.single.scheduledAt.hour, 3);
      expect(spring.single.scheduledAt.minute, 30);

      final autumn = NotificationOccurrencePlanner.plan(
        sources: [_source(scheduleId: 2, medicationId: 1, time: '01:30')],
        nowUtc: tz.TZDateTime(zone, 2026, 11, 1, 0).toUtc(),
        deviceTimezoneId: 'America/New_York',
        horizonDays: 1,
      );
      expect(autumn, hasLength(1));
      expect(
        autumn.single.scheduledAt.timeZoneOffset,
        const Duration(hours: -4),
      );
    },
  );

  test(
    'allocates stable unique ids, replaces pending work and cancels on pause',
    () async {
      final repository = MedicationRepository(
        appDatabase,
        nowUtc: () => _nowUtc,
      );
      final medicationId = await repository.save(
        Medication(
          name: 'Reminder medicine',
          dosageAmount: '1',
          dosageUnit: 'tablet',
          startDate: DateTime(2026, 10, 26),
          schedules: [
            MedicationSchedule(
              type: MedicationScheduleType.daily,
              timeOfDay: '08:00',
            ),
          ],
        ),
      );
      final notifications = _FakeNotificationService();
      final scheduler = NotificationScheduler(
        appDatabase,
        notifications,
        nowUtc: () => _nowUtc,
      );

      await scheduler.reconcile();
      final db = await appDatabase.database;
      final firstPass = await db.query('notification_jobs', orderBy: 'id ASC');
      expect(firstPass, hasLength(7));
      expect(firstPass.map((row) => row['id']).toSet(), hasLength(7));
      expect(firstPass.every((row) => row['is_scheduled'] == 1), isTrue);
      final ids = firstPass.map((row) => row['id']! as int).toSet();

      await scheduler.reconcile();
      expect(await db.query('notification_jobs'), hasLength(7));
      expect(notifications.scheduledIds.skip(7).toSet(), ids);

      await repository.setActive(medicationId, false);
      await scheduler.reconcile();
      expect(await db.query('notification_jobs'), isEmpty);
      expect(notifications.canceledIds.toSet(), ids);
    },
  );
}

ReminderScheduleSource _source({
  required int scheduleId,
  required int medicationId,
  String name = 'Medicine',
  required String time,
  String type = 'daily',
  Set<int> weekdays = const {},
  String startDate = '2026-01-01',
  String? endDate,
}) => ReminderScheduleSource(
  medicationId: medicationId,
  scheduleId: scheduleId,
  medicationName: name,
  dosageAmount: '1',
  dosageUnit: 'tablet',
  startDate: startDate,
  endDate: endDate,
  timezoneId: 'system',
  scheduleType: type,
  timeOfDay: time,
  weekdays: weekdays,
);

const _nowUtc = 1792990800000; // 2026-10-26 05:00 UTC (07:00 in Tripoli).

class _FakeNotificationService extends NotificationService {
  final scheduledIds = <int>[];
  final canceledIds = <int>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<String> refreshDeviceTimezone() async => 'Africa/Tripoli';

  @override
  Future<bool> notificationsEnabled() async => true;

  @override
  Future<bool> canScheduleExact() async => false;

  @override
  Future<void> schedule({
    required int id,
    required String medicationName,
    required String dosageAmount,
    required String dosageUnit,
    required int medicationId,
    int? doseRecordId,
    required tz.TZDateTime at,
    required bool exact,
    required AppSettings alertSettings,
  }) async {
    scheduledIds.add(id);
  }

  @override
  Future<void> cancel(int id) async => canceledIds.add(id);
}
