import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../models/medication.dart';

class MedicationRepository {
  MedicationRepository(this._appDatabase, {int Function()? nowUtc})
    : _nowUtc = nowUtc ?? _systemNowUtc;

  final AppDatabase _appDatabase;
  final int Function() _nowUtc;
  static int _systemNowUtc() => DateTime.now().toUtc().millisecondsSinceEpoch;

  Future<List<Medication>> getAll() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'medications',
      where: 'deleted_at_utc IS NULL',
      orderBy: 'is_active DESC, name COLLATE NOCASE ASC',
    );
    final medications = <Medication>[];
    for (final row in rows) {
      final schedules = await _loadSchedules(db, row['id']! as int);
      medications.add(_medicationFromRow(row, schedules));
    }
    return List.unmodifiable(medications);
  }

  Future<Medication?> getById(int id) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'medications',
      where: 'id = ? AND deleted_at_utc IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _medicationFromRow(rows.first, await _loadSchedules(db, id));
  }

  Future<int> save(Medication medication) async {
    MedicationValidator.validate(medication);
    final now = _nowUtc();
    final db = await _appDatabase.database;
    return db.transaction((txn) async {
      if (medication.recipientId != null) {
        final recipients = await txn.query(
          'care_recipients',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [medication.recipientId],
          limit: 1,
        );
        if (recipients.isEmpty) {
          throw StateError('Care recipient no longer exists.');
        }
      }
      final id = medication.id;
      final storedId =
          id == null
              ? await txn.insert('medications', {
                ..._medicationValues(medication),
                'is_active': 1,
                'created_at_utc': now,
                'updated_at_utc': now,
              })
              : await _updateExisting(txn, id, medication, now);

      await txn.update(
        'medication_schedule_sets',
        {'is_active': 0, 'effective_to_utc': now},
        where: 'medication_id = ? AND is_active = 1',
        whereArgs: [storedId],
      );
      await _insertScheduleSet(
        txn,
        storedId,
        medication.schedules,
        now,
        isActive: medication.isActive,
      );
      return storedId;
    });
  }

  Future<int> _updateExisting(
    Transaction txn,
    int id,
    Medication medication,
    int now,
  ) async {
    final existing = await txn.query(
      'medications',
      columns: ['id'],
      where: 'id = ? AND deleted_at_utc IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isEmpty) throw StateError('Medication no longer exists.');
    await txn.update(
      'medications',
      {..._medicationValues(medication), 'updated_at_utc': now},
      where: 'id = ? AND deleted_at_utc IS NULL',
      whereArgs: [id],
    );
    return id;
  }

  Future<void> setActive(int id, bool active) async {
    final now = _nowUtc();
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      final medication = await txn.query(
        'medications',
        where: 'id = ? AND deleted_at_utc IS NULL',
        whereArgs: [id],
        limit: 1,
      );
      if (medication.isEmpty) throw StateError('Medication no longer exists.');
      if ((medication.first['is_active']! as int) == (active ? 1 : 0)) return;

      if (!active) {
        await txn.update(
          'medication_schedule_sets',
          {'is_active': 0, 'effective_to_utc': now},
          where: 'medication_id = ? AND is_active = 1',
          whereArgs: [id],
        );
      } else {
        final previous = await txn.query(
          'medication_schedule_sets',
          where: 'medication_id = ?',
          whereArgs: [id],
          orderBy: 'effective_from_utc DESC, id DESC',
          limit: 1,
        );
        final previousSetId =
            previous.isEmpty ? null : previous.first['id']! as int;
        final stored =
            previousSetId == null
                ? const <_StoredSchedule>[]
                : await _loadStoredSchedules(txn, previousSetId);
        if (stored.isEmpty) {
          throw StateError('No saved schedule is available to resume.');
        }
        await _insertStoredScheduleSet(txn, id, stored, now);
      }
      await txn.update(
        'medications',
        {'is_active': active ? 1 : 0, 'updated_at_utc': now},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Archives the medication while keeping its schedule and dose foreign keys intact.
  Future<void> archive(int id) async {
    final now = _nowUtc();
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      final updated = await txn.update(
        'medications',
        {'is_active': 0, 'deleted_at_utc': now, 'updated_at_utc': now},
        where: 'id = ? AND deleted_at_utc IS NULL',
        whereArgs: [id],
      );
      if (updated == 0) throw StateError('Medication no longer exists.');
      await txn.update(
        'medication_schedule_sets',
        {'is_active': 0, 'effective_to_utc': now},
        where: 'medication_id = ? AND is_active = 1',
        whereArgs: [id],
      );
    });
  }

  Future<void> _insertScheduleSet(
    DatabaseExecutor txn,
    int medicationId,
    List<MedicationSchedule> schedules,
    int now, {
    required bool isActive,
  }) async {
    final setId = await txn.insert('medication_schedule_sets', {
      'medication_id': medicationId,
      'effective_from_utc': now,
      'is_active': isActive ? 1 : 0,
      'effective_to_utc': isActive ? null : now,
    });
    for (final schedule in schedules) {
      await _insertSchedule(txn, setId, schedule);
    }
  }

  Future<void> _insertStoredScheduleSet(
    DatabaseExecutor txn,
    int medicationId,
    List<_StoredSchedule> schedules,
    int now,
  ) async {
    final setId = await txn.insert('medication_schedule_sets', {
      'medication_id': medicationId,
      'effective_from_utc': now,
      'is_active': 1,
    });
    for (final item in schedules) {
      final scheduleId = await txn.insert('medication_schedules', {
        'schedule_set_id': setId,
        'schedule_type': item.type,
        'time_of_day': item.time,
      });
      for (final day in item.weekdays) {
        await txn.insert('schedule_days', {
          'schedule_id': scheduleId,
          'weekday': day,
        });
      }
    }
  }

  Future<void> _insertSchedule(
    DatabaseExecutor txn,
    int setId,
    MedicationSchedule schedule,
  ) async {
    final scheduleId = await txn.insert('medication_schedules', {
      'schedule_set_id': setId,
      'schedule_type': schedule.type.databaseValue,
      'time_of_day': schedule.timeOfDay,
    });
    for (final day in schedule.weekdays) {
      await txn.insert('schedule_days', {
        'schedule_id': scheduleId,
        'weekday': day,
      });
    }
  }

  Future<List<MedicationSchedule>> _loadSchedules(
    DatabaseExecutor db,
    int medicationId,
  ) async {
    final sets = await db.query(
      'medication_schedule_sets',
      columns: ['id'],
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      orderBy: 'is_active DESC, effective_from_utc DESC, id DESC',
      limit: 1,
    );
    if (sets.isEmpty) return const [];
    final stored = await _loadStoredSchedules(db, sets.first['id']! as int);
    return List.unmodifiable(
      stored.map(
        (row) => MedicationSchedule(
          type: MedicationScheduleType.fromDatabase(row.type),
          timeOfDay: row.time,
          weekdays: row.weekdays.toSet(),
        ),
      ),
    );
  }

  Future<List<_StoredSchedule>> _loadStoredSchedules(
    DatabaseExecutor db,
    int setId,
  ) async {
    final schedules = await db.query(
      'medication_schedules',
      where: 'schedule_set_id = ?',
      whereArgs: [setId],
      orderBy: 'time_of_day ASC, id ASC',
    );
    final values = <_StoredSchedule>[];
    for (final schedule in schedules) {
      final days = await db.query(
        'schedule_days',
        columns: ['weekday'],
        where: 'schedule_id = ?',
        whereArgs: [schedule['id']],
        orderBy: 'weekday ASC',
      );
      values.add(
        _StoredSchedule(
          type: schedule['schedule_type']! as String,
          time: schedule['time_of_day']! as String,
          weekdays: days
              .map((row) => row['weekday']! as int)
              .toList(growable: false),
        ),
      );
    }
    return values;
  }

  static Map<String, Object?> _medicationValues(Medication medication) => {
    'name': medication.name.trim(),
    'dosage_amount': MedicationValidator.normalizeAmount(
      medication.dosageAmount,
    ),
    'dosage_unit': medication.dosageUnit.trim(),
    'medication_form': _nullableTrim(medication.form),
    'start_date': encodeLocalDate(medication.startDate),
    'end_date':
        medication.endDate == null
            ? null
            : encodeLocalDate(medication.endDate!),
    'notes': _nullableTrim(medication.notes),
    'indication': _nullableTrim(medication.indication),
    'image_path': _nullableTrim(medication.imagePath),
    'color_value': medication.colorValue,
    'recipient_id': medication.recipientId,
    'timezone_id': medication.timezoneId,
  };

  static String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static Medication _medicationFromRow(
    Map<String, Object?> row,
    List<MedicationSchedule> schedules,
  ) => Medication(
    id: row['id']! as int,
    name: row['name']! as String,
    dosageAmount: row['dosage_amount']! as String,
    dosageUnit: row['dosage_unit']! as String,
    form: row['medication_form'] as String?,
    startDate: decodeLocalDate(row['start_date']! as String),
    endDate:
        row['end_date'] == null
            ? null
            : decodeLocalDate(row['end_date']! as String),
    notes: row['notes'] as String?,
    indication: row['indication'] as String?,
    imagePath: row['image_path'] as String?,
    colorValue: row['color_value'] as int?,
    recipientId: row['recipient_id'] as int?,
    timezoneId: row['timezone_id']! as String,
    isActive: row['is_active']! as int == 1,
    createdAtUtc: row['created_at_utc']! as int,
    updatedAtUtc: row['updated_at_utc']! as int,
    deletedAtUtc: row['deleted_at_utc'] as int?,
    schedules: schedules,
  );
}

class _StoredSchedule {
  const _StoredSchedule({
    required this.type,
    required this.time,
    required this.weekdays,
  });
  final String type;
  final String time;
  final List<int> weekdays;
}
