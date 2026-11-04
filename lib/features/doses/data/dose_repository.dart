import 'package:sqflite/sqflite.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_ids.dart';
import '../models/dose_record.dart';

class DoseRepository {
  DoseRepository(this._database, {int Function()? nowUtc})
    : _nowUtc = nowUtc ?? _systemNowUtc;

  final AppDatabase _database;
  final int Function() _nowUtc;
  static const unconfirmedGrace = Duration(hours: 2);

  static int _systemNowUtc() => DateTime.now().toUtc().millisecondsSinceEpoch;

  Future<List<DoseRecord>> getForDate(DateTime requestedDate) async {
    final date = DateTime(
      requestedDate.year,
      requestedDate.month,
      requestedDate.day,
    );
    final localDate = _encodeDate(date);
    final db = await _database.database;
    final candidates = await db.rawQuery(
      '''
      SELECT m.id AS medication_id, m.name AS medication_name,
        m.dosage_amount, m.dosage_unit, m.medication_form, m.notes,
        m.timezone_id, m.start_date, m.end_date,
        sets.id AS schedule_set_id, sets.effective_from_utc,
        sets.effective_to_utc,
        NOT EXISTS (
          SELECT 1 FROM medication_schedule_sets previous_sets
          WHERE previous_sets.medication_id = m.id
            AND previous_sets.effective_from_utc < sets.effective_from_utc
        ) AS is_initial_schedule,
        s.id AS schedule_id, s.schedule_type,
        s.time_of_day
      FROM medications m
      JOIN medication_schedule_sets sets ON sets.medication_id = m.id
      JOIN medication_schedules s ON s.schedule_set_id = sets.id
      WHERE m.start_date <= ? AND (m.end_date IS NULL OR m.end_date >= ?)
      ORDER BY s.time_of_day, m.id
    ''',
      [localDate, localDate],
    );
    final dayRows = await db.rawQuery(
      '''
      SELECT sd.schedule_id, sd.weekday FROM schedule_days sd
      JOIN medication_schedules s ON s.id = sd.schedule_id
      JOIN medication_schedule_sets sets ON sets.id = s.schedule_set_id
      WHERE sets.medication_id IN (
        SELECT id FROM medications WHERE start_date <= ?
          AND (end_date IS NULL OR end_date >= ?)
      )
    ''',
      [localDate, localDate],
    );
    final weekdays = <int, Set<int>>{};
    for (final row in dayRows) {
      (weekdays[row['schedule_id']! as int] ??= <int>{}).add(
        row['weekday']! as int,
      );
    }

    await db.transaction((txn) async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      if (date == todayDate) {
        // A medication edit replaces its active schedule set. Drop today's
        // unconfirmed dose snapshots from superseded sets so the dashboard
        // shows the new times instead of the old schedule.
        await txn.rawDelete(
          '''
          DELETE FROM dose_records
          WHERE local_date = ? AND status = 'pending'
            AND schedule_id IN (
              SELECT s.id
              FROM medication_schedules s
              JOIN medication_schedule_sets sets ON sets.id = s.schedule_set_id
              WHERE sets.is_active = 0
            )
          ''',
          [localDate],
        );
      }
      for (final row in candidates) {
        final type = row['schedule_type']! as String;
        if (type == 'specific_days' &&
            !(weekdays[row['schedule_id']! as int] ?? const {}).contains(
              date.weekday,
            )) {
          continue;
        }
        final timezoneId = row['timezone_id']! as String;
        final location = tz.getLocation(
          timezoneId == 'system' ? tz.local.name : timezoneId,
        );
        final parts = (row['time_of_day']! as String).split(':');
        final scheduled = tz.TZDateTime(
          location,
          date.year,
          date.month,
          date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        final scheduledUtc = scheduled.millisecondsSinceEpoch;
        final effectiveFrom = row['effective_from_utc']! as int;
        final effectiveTo = row['effective_to_utc'] as int?;
        final isInitialSchedule = row['is_initial_schedule']! as int == 1;
        final isToday = date == todayDate;
        if ((scheduledUtc < effectiveFrom && !(isToday && isInitialSchedule)) ||
            (effectiveTo != null && scheduledUtc >= effectiveTo)) {
          continue;
        }
        await txn.insert('dose_records', {
          'medication_id': row['medication_id'],
          'schedule_id': row['schedule_id'],
          'local_date': localDate,
          'scheduled_at_utc': scheduledUtc,
          'timezone_id': location.name,
          'utc_offset_minutes': scheduled.timeZoneOffset.inMinutes,
          'medication_name': row['medication_name'],
          'dosage_amount': row['dosage_amount'],
          'dosage_unit': row['dosage_unit'],
          'medication_form': row['medication_form'],
          'instructions': row['notes'],
          'status_recorded_at_utc': _nowUtc(),
          'created_at_utc': _nowUtc(),
          'updated_at_utc': _nowUtc(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        final inserted = await txn.query(
          'dose_records',
          columns: ['id'],
          where: 'schedule_id = ? AND local_date = ?',
          whereArgs: [row['schedule_id'], localDate],
          limit: 1,
        );
        if (inserted.isNotEmpty) {
          final id = inserted.single['id']! as int;
          final hasEvent = await txn.query(
            'dose_status_events',
            columns: ['id'],
            where: 'dose_record_id = ?',
            whereArgs: [id],
            limit: 1,
          );
          if (hasEvent.isEmpty) {
            await txn.insert('dose_status_events', {
              'dose_record_id': id,
              'new_status': 'pending',
              'recorded_at_utc': _nowUtc(),
              'event_type': 'scheduled',
            });
          }
        }
      }
      final cutoff = _nowUtc() - unconfirmedGrace.inMilliseconds;
      final overdue = await txn.query(
        'dose_records',
        columns: ['id', 'status'],
        where:
            "local_date = ? AND status IN ('pending', 'postponed') AND COALESCE(postponed_until_utc, scheduled_at_utc) <= ?",
        whereArgs: [localDate, cutoff],
      );
      for (final dose in overdue) {
        final id = dose['id']! as int;
        final oldStatus = dose['status']! as String;
        await txn.update(
          'dose_records',
          {
            'status': 'unconfirmed',
            'postponed_until_utc': null,
            'status_recorded_at_utc': _nowUtc(),
            'updated_at_utc': _nowUtc(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        await txn.insert('dose_status_events', {
          'dose_record_id': id,
          'previous_status': oldStatus,
          'new_status': 'unconfirmed',
          'recorded_at_utc': _nowUtc(),
          'event_type': 'grace_period_expired',
        });
      }
    });

    final rows = await db.query(
      'dose_records',
      where: 'local_date = ?',
      whereArgs: [localDate],
      orderBy: 'scheduled_at_utc ASC, id ASC',
    );
    return rows.map(DoseRecord.fromRow).toList(growable: false);
  }

  Future<DoseRecord?> findDoseForAlarm({
    required int medicationId,
    int? notificationId,
  }) async {
    final db = await _database.database;
    if (notificationId != null &&
        notificationId >= postponedNotificationIdBase) {
      final doseId = notificationId - postponedNotificationIdBase;
      final rows = await db.query(
        'dose_records',
        where: 'id = ? AND medication_id = ?',
        whereArgs: [doseId, medicationId],
        limit: 1,
      );
      return rows.isEmpty ? null : DoseRecord.fromRow(rows.single);
    }

    if (notificationId != null) {
      var rows = await db.rawQuery(
        '''
        SELECT d.* FROM dose_records d
        JOIN notification_jobs n
          ON n.schedule_id = d.schedule_id AND n.local_date = d.local_date
        WHERE n.id = ? AND d.medication_id = ? LIMIT 1
      ''',
        [notificationId, medicationId],
      );
      if (rows.isEmpty) {
        await getForDate(DateTime.now());
        rows = await db.rawQuery(
          '''
          SELECT d.* FROM dose_records d
          JOIN notification_jobs n
            ON n.schedule_id = d.schedule_id AND n.local_date = d.local_date
          WHERE n.id = ? AND d.medication_id = ? LIMIT 1
        ''',
          [notificationId, medicationId],
        );
      }
      if (rows.isNotEmpty) return DoseRecord.fromRow(rows.single);
    }

    final doses = await getForDate(DateTime.now());
    final now = _nowUtc();
    final matches =
        doses
            .where(
              (dose) =>
                  dose.medicationId == medicationId &&
                  dose.scheduledAtUtc <=
                      now + const Duration(minutes: 5).inMilliseconds &&
                  dose.status != DoseStatus.taken &&
                  dose.status != DoseStatus.skipped,
            )
            .toList()
          ..sort(
            (a, b) => (a.scheduledAtUtc - now).abs().compareTo(
              (b.scheduledAtUtc - now).abs(),
            ),
          );
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> setStatus(int id, DoseStatus status) async {
    if (status == DoseStatus.missed ||
        status == DoseStatus.unconfirmed ||
        status == DoseStatus.postponed) {
      throw ArgumentError.value(
        status,
        'status',
        'Use system transition or postponeDose.',
      );
    }
    final db = await _database.database;
    final now = _nowUtc();
    await db.transaction((txn) async {
      final rows = await txn.query(
        'dose_records',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Dose record not found.');
      }
      final row = rows.single;
      if ((row['scheduled_at_utc']! as int) > now) {
        throw StateError('A future dose cannot be confirmed.');
      }
      final previous = row['status']! as String;
      if (previous == status.databaseValue) return;
      await txn.update(
        'dose_records',
        {
          'status': status.databaseValue,
          'taken_at_utc': status == DoseStatus.taken ? now : null,
          'confirmed_at_utc': now,
          'status_recorded_at_utc': now,
          'postponed_until_utc': null,
          'updated_at_utc': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.insert('dose_status_events', {
        'dose_record_id': id,
        'previous_status': previous,
        'new_status': status.databaseValue,
        'recorded_at_utc': now,
        'event_type':
            previous == 'taken' || previous == 'skipped'
                ? 'correction'
                : 'user_confirmation',
      });
    });
  }

  Future<void> postponeDose(int id, DateTime untilUtc) async {
    final db = await _database.database;
    final now = _nowUtc();
    final until = untilUtc.toUtc().millisecondsSinceEpoch;
    if (until <= now) {
      throw ArgumentError('Postponed time must be in the future.');
    }
    await db.transaction((txn) async {
      final rows = await txn.query(
        'dose_records',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Dose record not found.');
      }
      final row = rows.single;
      if ((row['scheduled_at_utc']! as int) > now) {
        throw StateError('A future dose cannot be postponed.');
      }
      final previous = row['status']! as String;
      if (previous == 'taken' || previous == 'skipped') {
        throw StateError('This dose is already closed.');
      }
      await txn.update(
        'dose_records',
        {
          'status': 'postponed',
          'taken_at_utc': null,
          'confirmed_at_utc': now,
          'status_recorded_at_utc': now,
          'postponed_until_utc': until,
          'updated_at_utc': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.insert('dose_status_events', {
        'dose_record_id': id,
        'previous_status': previous,
        'new_status': 'postponed',
        'recorded_at_utc': now,
        'event_type': 'postponed',
        'postponed_until_utc': until,
      });
    });
  }

  Future<List<Map<String, Object?>>> eventsForDose(int id) async {
    final db = await _database.database;
    return db.query(
      'dose_status_events',
      where: 'dose_record_id = ?',
      whereArgs: [id],
      orderBy: 'recorded_at_utc ASC, id ASC',
    );
  }

  Future<AdherenceSummary> summary(DateTime start, DateTime end) async {
    var day = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final through = last.isAfter(todayDate) ? todayDate : last;
    while (!day.isAfter(through)) {
      await getForDate(day);
      day = day.add(const Duration(days: 1));
    }
    final rows = await (await _database.database).rawQuery(
      '''
      SELECT status, COUNT(*) AS count FROM dose_records
      WHERE local_date BETWEEN ? AND ? AND scheduled_at_utc <= ? GROUP BY status
    ''',
      [_encodeDate(start), _encodeDate(through), _nowUtc()],
    );
    final counts = <String, int>{
      for (final row in rows) row['status']! as String: row['count']! as int,
    };
    return AdherenceSummary(
      total: counts.values.fold(0, (sum, count) => sum + count),
      taken: counts['taken'] ?? 0,
      skipped: counts['skipped'] ?? 0,
      missed: counts['missed'] ?? 0,
      pending: counts['pending'] ?? 0,
      postponed: counts['postponed'] ?? 0,
      unconfirmed: (counts['unconfirmed'] ?? 0) + (counts['missed'] ?? 0),
    );
  }

  String _encodeDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
