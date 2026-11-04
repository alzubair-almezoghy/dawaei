import 'dart:io';

import 'package:dawaei/core/database/app_database.dart';
import 'package:dawaei/core/database/migrations/v1_initial.dart';
import 'package:dawaei/features/medicines/data/medication_repository.dart';
import 'package:dawaei/features/medicines/models/medication.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directory;
  late AppDatabase appDatabase;
  late MedicationRepository repository;
  var clock = DateTime.utc(2026, 10, 28, 9).millisecondsSinceEpoch;

  setUpAll(() => sqfliteFfiInit());

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dawaei-db-');
    appDatabase = AppDatabase(
      factory: databaseFactoryFfi,
      path: p.join(directory.path, 'test.db'),
    );
    repository = MedicationRepository(appDatabase, nowUtc: () => clock);
    clock += 1000;
  });

  tearDown(() async {
    await appDatabase.close();
    await directory.delete(recursive: true);
  });

  test(
    'creates and edits a medication with multiple weekday schedules',
    () async {
      final id = await repository.save(_sample());
      final created = await repository.getById(id);
      expect(created, isNotNull);
      expect(created!.name, 'Vitamin D');
      expect(created.dosageAmount, '2.5');
      expect(created.schedules, hasLength(2));
      expect(created.schedules.first.weekdays, {1, 3, 5});

      final updated = Medication(
        id: id,
        name: 'Vitamin D3',
        dosageAmount: '1',
        dosageUnit: 'tablet',
        startDate: DateTime(2026, 10, 29),
        schedules: [
          MedicationSchedule(
            type: MedicationScheduleType.daily,
            timeOfDay: '10:30',
          ),
        ],
      );
      await repository.save(updated);
      final reread = await repository.getById(id);
      expect(reread!.name, 'Vitamin D3');
      expect(reread.schedules.single.timeOfDay, '10:30');
    },
  );

  test(
    'persists, replaces, and removes the optional medication image path',
    () async {
      final id = await repository.save(
        _sample().copyWith(imagePath: 'medication_images/first.jpg'),
      );
      expect(
        (await repository.getById(id))!.imagePath,
        'medication_images/first.jpg',
      );

      final medication = (await repository.getById(id))!;
      await repository.save(
        medication.copyWith(imagePath: 'medication_images/replacement.png'),
      );
      expect(
        (await repository.getById(id))!.imagePath,
        'medication_images/replacement.png',
      );

      final replaced = (await repository.getById(id))!;
      await repository.save(replaced.copyWith(clearImagePath: true));
      expect((await repository.getById(id))!.imagePath, isNull);
    },
  );

  test(
    'schedule edits preserve old dose references and prevent duplicates',
    () async {
      final id = await repository.save(_sample());
      final db = await appDatabase.database;
      final scheduleRows = await db.query('medication_schedules', limit: 1);
      final scheduleId = scheduleRows.single['id']! as int;
      final originalDose = {
        'medication_id': id,
        'schedule_id': scheduleId,
        'local_date': '2026-10-28',
        'scheduled_at_utc': clock,
        'timezone_id': 'Europe/Tripoli',
        'utc_offset_minutes': 120,
        'medication_name': 'Vitamin D',
        'dosage_amount': '2.5',
        'dosage_unit': 'mg',
        'medication_form': null,
        'instructions': null,
        'status': 'pending',
        'taken_at_utc': null,
        'confirmed_at_utc': null,
        'created_at_utc': clock,
        'updated_at_utc': clock,
      };
      await db.insert('dose_records', originalDose);
      await expectLater(
        db.insert('dose_records', originalDose),
        throwsA(isA<DatabaseException>()),
      );

      final current = (await repository.getById(id))!;
      await repository.save(
        current.copyWith(
          schedules: [
            MedicationSchedule(
              type: MedicationScheduleType.daily,
              timeOfDay: '14:00',
            ),
          ],
        ),
      );
      expect(
        (await db.query('dose_records')).single['medication_name'],
        'Vitamin D',
      );
      expect(
        await db.query(
          'medication_schedules',
          where: 'id = ?',
          whereArgs: [scheduleId],
        ),
        hasLength(1),
      );
      expect(
        (await repository.getById(id))!.schedules.single.timeOfDay,
        '14:00',
      );
    },
  );

  test(
    'pause and resume clone the saved schedule; archive keeps history',
    () async {
      final id = await repository.save(_sample());
      final before = await appDatabase.database;
      final scheduleId =
          (await before.query('medication_schedules')).first['id']! as int;
      await before.insert('dose_records', {
        'medication_id': id,
        'schedule_id': scheduleId,
        'local_date': '2026-10-28',
        'scheduled_at_utc': clock,
        'timezone_id': 'Europe/Tripoli',
        'utc_offset_minutes': 120,
        'medication_name': 'Vitamin D',
        'dosage_amount': '2.5',
        'dosage_unit': 'mg',
        'status': 'pending',
        'created_at_utc': clock,
        'updated_at_utc': clock,
      });

      await repository.setActive(id, false);
      final paused = (await repository.getById(id))!;
      expect(paused.isActive, isFalse);
      expect(paused.schedules, hasLength(2));
      await repository.setActive(id, true);
      final resumed = (await repository.getById(id))!;
      expect(resumed.isActive, isTrue);
      expect(resumed.schedules, hasLength(2));

      await repository.archive(id);
      expect(await repository.getById(id), isNull);
      expect(await before.query('dose_records'), hasLength(1));
      expect(await repository.getAll(), isEmpty);
    },
  );

  test(
    'rejects invalid amounts, dates, duplicate times and empty weekdays',
    () async {
      final invalids = [
        _sample(dosageAmount: '0'),
        _sample(endDate: DateTime(2026, 10, 27)),
        _sample(
          schedules: [
            MedicationSchedule(
              type: MedicationScheduleType.daily,
              timeOfDay: '08:00',
            ),
            MedicationSchedule(
              type: MedicationScheduleType.daily,
              timeOfDay: '08:00',
            ),
          ],
        ),
        _sample(
          schedules: [
            MedicationSchedule(
              type: MedicationScheduleType.specificDays,
              timeOfDay: '08:00',
            ),
          ],
        ),
      ];
      for (final invalid in invalids) {
        expect(
          () => MedicationValidator.validate(invalid),
          throwsA(isA<MedicationValidationException>()),
        );
      }
      expect(MedicationValidator.normalizeAmount('٢٫٥'), '2.5');
    },
  );

  test('upgrades a version one database without dropping data', () async {
    final path = p.join(directory.path, 'migration.db');
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async => createSchemaV1(db),
      ),
    );
    await old.insert('medications', {
      'name': 'Legacy medicine',
      'dosage_amount': '1',
      'dosage_unit': 'mg',
      'start_date': '2026-10-28',
      'timezone_id': 'system',
      'is_active': 1,
      'created_at_utc': clock,
      'updated_at_utc': clock,
    });
    await old.close();
    final upgraded = AppDatabase(factory: databaseFactoryFfi, path: path);
    final db = await upgraded.database;
    expect((await db.query('medications')).single['name'], 'Legacy medicine');
    expect((await db.query('medications')).single['image_path'], isNull);
    final columns = await db.rawQuery(
      'PRAGMA table_info(medication_schedule_sets)',
    );
    expect(
      columns.any((column) => column['name'] == 'effective_to_utc'),
      isTrue,
    );
    expect(await db.query('notification_jobs'), isEmpty);
    expect(await db.getVersion(), AppDatabase.schemaVersion);
    await upgraded.close();
  });
}

Medication _sample({
  String dosageAmount = '2.5',
  DateTime? endDate,
  List<MedicationSchedule>? schedules,
}) => Medication(
  name: 'Vitamin D',
  dosageAmount: dosageAmount,
  dosageUnit: 'mg',
  startDate: DateTime(2026, 10, 28),
  endDate: endDate,
  schedules:
      schedules ??
      [
        MedicationSchedule(
          type: MedicationScheduleType.specificDays,
          timeOfDay: '08:00',
          weekdays: {1, 3, 5},
        ),
        MedicationSchedule(
          type: MedicationScheduleType.daily,
          timeOfDay: '20:00',
        ),
      ],
);
