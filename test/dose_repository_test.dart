import 'dart:io';

import 'package:dawaei/core/database/app_database.dart';
import 'package:dawaei/core/notifications/notification_ids.dart';
import 'package:dawaei/features/doses/data/dose_repository.dart';
import 'package:dawaei/features/doses/models/dose_record.dart';
import 'package:dawaei/features/medicines/data/medication_repository.dart';
import 'package:dawaei/features/medicines/models/medication.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late Directory directory;
  late AppDatabase database;
  late MedicationRepository medications;

  setUpAll(() {
    sqfliteFfiInit();
    timezone_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Tripoli'));
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dawaei-doses-');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: p.join(directory.path, 'dawaei.db'),
    );
    medications = MedicationRepository(
      database,
      nowUtc:
          () =>
              DateTime.now()
                  .subtract(const Duration(minutes: 3))
                  .toUtc()
                  .millisecondsSinceEpoch,
    );
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'creates one dose per occurrence and saves explicit confirmation',
    () async {
      final now = DateTime.now();
      final scheduledTime = now.subtract(const Duration(minutes: 2));
      final time =
          '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
      final id = await medications.save(
        Medication(
          name: 'Test medicine',
          dosageAmount: '1',
          dosageUnit: 'tablet',
          startDate: DateTime(now.year, now.month, now.day),
          schedules: [
            MedicationSchedule(
              type: MedicationScheduleType.daily,
              timeOfDay: time,
            ),
          ],
        ),
      );
      final repository = DoseRepository(database);
      final first = await repository.getForDate(now);
      expect(first, hasLength(1));
      expect(first.single.medicationId, id);
      expect(first.single.status, DoseStatus.pending);
      final db = await database.database;
      final notificationId = await db.insert('notification_jobs', {
        'occurrence_key':
            '${first.single.scheduleId}|${first.single.localDate}',
        'medication_id': first.single.medicationId,
        'schedule_id': first.single.scheduleId,
        'local_date': first.single.localDate,
        'scheduled_at_utc': first.single.scheduledAtUtc,
        'timezone_id': first.single.timezoneId,
        'medication_name': first.single.medicationName,
        'dosage_amount': first.single.dosageAmount,
        'dosage_unit': first.single.dosageUnit,
        'created_at_utc': DateTime.now().toUtc().millisecondsSinceEpoch,
        'updated_at_utc': DateTime.now().toUtc().millisecondsSinceEpoch,
      });
      expect(
        (await repository.findDoseForAlarm(
          medicationId: id,
          notificationId: notificationId,
        ))?.id,
        first.single.id,
      );

      await repository.setStatus(first.single.id, DoseStatus.taken);
      final repeated = await repository.getForDate(now);
      expect(repeated, hasLength(1));
      expect(repeated.single.status, DoseStatus.taken);
      expect(repeated.single.takenAtUtc, isNotNull);
      final summary = await repository.summary(now, now);
      expect(summary.total, 1);
      expect(summary.taken, 1);
      expect(summary.rate, 1);
    },
  );

  test('does not allow confirming a future occurrence', () async {
    final now = DateTime.now();
    final future = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 5,
    );
    final id = await medications.save(
      Medication(
        name: 'Future medicine',
        dosageAmount: '1',
        dosageUnit: 'tablet',
        startDate: DateTime(now.year, now.month, now.day),
        schedules: [
          MedicationSchedule(
            type: MedicationScheduleType.daily,
            timeOfDay:
                '${future.hour.toString().padLeft(2, '0')}:${future.minute.toString().padLeft(2, '0')}',
          ),
        ],
      ),
    );
    expect(id, greaterThan(0));
    final dose = (await DoseRepository(database).getForDate(now)).single;
    await expectLater(
      DoseRepository(database).setStatus(dose.id, DoseStatus.taken),
      throwsStateError,
    );
  });

  test(
    'postpone keeps one dose, audits transitions, and taken closes it',
    () async {
      final now = DateTime.now();
      final scheduledTime = now.subtract(const Duration(minutes: 2));
      final time =
          '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';
      await medications.save(
        Medication(
          name: 'Postpone medicine',
          dosageAmount: '1',
          dosageUnit: 'tablet',
          startDate: DateTime(now.year, now.month, now.day),
          schedules: [
            MedicationSchedule(
              type: MedicationScheduleType.daily,
              timeOfDay: time,
            ),
          ],
        ),
      );
      final repository = DoseRepository(database);
      final dose = (await repository.getForDate(now)).single;
      final postponedUntil = DateTime.now().toUtc().add(
        const Duration(minutes: 30),
      );
      await repository.postponeDose(dose.id, postponedUntil);
      expect(
        (await repository.findDoseForAlarm(
          medicationId: dose.medicationId,
          notificationId: postponedNotificationIdBase + dose.id,
        ))?.id,
        dose.id,
      );
      final postponed = (await repository.getForDate(now)).single;
      expect(postponed.status, DoseStatus.postponed);
      expect(
        postponed.postponedUntilUtc,
        postponedUntil.millisecondsSinceEpoch,
      );
      expect(
        await (await database.database).rawQuery(
          'SELECT COUNT(*) AS n FROM dose_records',
        ),
        everyElement(containsPair('n', 1)),
      );
      await repository.postponeDose(
        dose.id,
        postponedUntil.add(const Duration(minutes: 15)),
      );
      await repository.setStatus(dose.id, DoseStatus.taken);
      final finalDose = (await repository.getForDate(now)).single;
      expect(finalDose.status, DoseStatus.taken);
      expect(finalDose.postponedUntilUtc, isNull);
      expect(
        (await repository.eventsForDose(dose.id)).map((e) => e['new_status']),
        ['pending', 'postponed', 'postponed', 'taken'],
      );
    },
  );

  test(
    'fresh migration preserves existing dose schema and creates event table',
    () async {
      final db = await database.database;
      final version =
          (await db.rawQuery('PRAGMA user_version')).single['user_version'];
      expect(version, AppDatabase.schemaVersion);
      expect(
        await db.query(
          'sqlite_master',
          where: "type = 'table' AND name = ?",
          whereArgs: ['dose_status_events'],
        ),
        hasLength(1),
      );
    },
  );
}
