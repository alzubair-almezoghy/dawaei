import 'dart:io';

import 'package:dawaei/core/database/app_database.dart';
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
      final time =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
}
