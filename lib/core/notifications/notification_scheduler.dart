import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';
import '../database/database_providers.dart';
import '../../features/medicines/models/medication.dart';
import '../../features/settings/data/settings_store.dart';
import '../../features/settings/models/app_settings.dart';
import '../../features/settings/providers/settings_provider.dart';
import 'notification_service.dart';

const notificationHorizonDays = 7;
const maxScheduledMedicationNotifications = 200;

class ReminderScheduleSource {
  const ReminderScheduleSource({
    required this.medicationId,
    required this.scheduleId,
    required this.medicationName,
    required this.dosageAmount,
    required this.dosageUnit,
    required this.startDate,
    required this.endDate,
    required this.timezoneId,
    required this.scheduleType,
    required this.timeOfDay,
    required this.weekdays,
  });

  final int medicationId;
  final int scheduleId;
  final String medicationName;
  final String dosageAmount;
  final String dosageUnit;
  final String startDate;
  final String? endDate;
  final String timezoneId;
  final String scheduleType;
  final String timeOfDay;
  final Set<int> weekdays;
}

class PlannedNotification {
  const PlannedNotification({
    required this.occurrenceKey,
    required this.medicationId,
    required this.scheduleId,
    required this.localDate,
    required this.timezoneId,
    required this.scheduledAt,
    required this.medicationName,
    required this.dosageAmount,
    required this.dosageUnit,
  });

  final String occurrenceKey;
  final int medicationId;
  final int scheduleId;
  final String localDate;
  final String timezoneId;
  final tz.TZDateTime scheduledAt;
  final String medicationName;
  final String dosageAmount;
  final String dosageUnit;
}

abstract final class NotificationOccurrencePlanner {
  static List<PlannedNotification> plan({
    required List<ReminderScheduleSource> sources,
    required DateTime nowUtc,
    required String deviceTimezoneId,
    int horizonDays = notificationHorizonDays,
    int limit = maxScheduledMedicationNotifications,
  }) {
    if (horizonDays < 1 || limit < 1) return const [];
    final results = <PlannedNotification>[];
    for (final source in sources) {
      final timezoneId =
          source.timezoneId == 'system' ? deviceTimezoneId : source.timezoneId;
      final location = tz.getLocation(timezoneId);
      final hour = int.parse(source.timeOfDay.substring(0, 2));
      final minute = int.parse(source.timeOfDay.substring(3, 5));
      final localNow = tz.TZDateTime.from(nowUtc.toUtc(), location);

      for (var offset = 0; offset < horizonDays; offset++) {
        final date = DateTime.utc(
          localNow.year,
          localNow.month,
          localNow.day + offset,
        );
        final localDate = encodeLocalDate(date);
        if (localDate.compareTo(source.startDate) < 0 ||
            (source.endDate != null &&
                localDate.compareTo(source.endDate!) > 0)) {
          continue;
        }
        if (source.scheduleType == 'specific_days' &&
            !source.weekdays.contains(date.weekday)) {
          continue;
        }
        // timezone's TZDateTime policy maps a nonexistent wall time forward
        // across a DST gap and selects one instant for a repeated wall time.
        final scheduledAt = tz.TZDateTime(
          location,
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
        if (!scheduledAt.isAfter(localNow)) continue;
        results.add(
          PlannedNotification(
            occurrenceKey: '${source.scheduleId}|$localDate',
            medicationId: source.medicationId,
            scheduleId: source.scheduleId,
            localDate: localDate,
            timezoneId: timezoneId,
            scheduledAt: scheduledAt,
            medicationName: source.medicationName,
            dosageAmount: source.dosageAmount,
            dosageUnit: source.dosageUnit,
          ),
        );
      }
    }
    results.sort((a, b) {
      final time = a.scheduledAt.compareTo(b.scheduledAt);
      if (time != 0) return time;
      final name = a.medicationName.compareTo(b.medicationName);
      return name != 0 ? name : a.scheduleId.compareTo(b.scheduleId);
    });
    return List.unmodifiable(results.take(limit));
  }
}

class NotificationScheduler {
  NotificationScheduler(
    this._database,
    this._notifications, {
    SettingsStore? settingsStore,
    int Function()? nowUtc,
  }) : _settingsStore = settingsStore,
       _nowUtc = nowUtc ?? _systemNowUtc;

  final AppDatabase _database;
  final NotificationService _notifications;
  final SettingsStore? _settingsStore;
  final int Function() _nowUtc;

  static int _systemNowUtc() => DateTime.now().toUtc().millisecondsSinceEpoch;

  Future<void> reconcile() async {
    await _notifications.initialize();
    final now = DateTime.fromMillisecondsSinceEpoch(_nowUtc(), isUtc: true);
    final deviceZone = await _notifications.refreshDeviceTimezone();
    final sourceRows = await _loadSources();
    AppSettings alertSettings;
    try {
      alertSettings = await _settingsStore?.load() ?? const AppSettings();
    } catch (_) {
      alertSettings = const AppSettings();
    }
    final planned = NotificationOccurrencePlanner.plan(
      sources: sourceRows,
      nowUtc: now,
      deviceTimezoneId: deviceZone,
    );
    final db = await _database.database;
    final current = await db.query('notification_jobs');
    final desiredKeys = planned.map((item) => item.occurrenceKey).toSet();
    final stale = current.where(
      (row) => !desiredKeys.contains(row['occurrence_key']! as String),
    );

    // Cancel before deleting the registry row. If cancellation fails, keep the
    // row so the next foreground reconciliation can safely retry it.
    for (final row in stale) {
      await _notifications.cancel(row['id']! as int);
    }

    await db.transaction((txn) async {
      if (stale.isNotEmpty) {
        await txn.delete(
          'notification_jobs',
          where:
              'occurrence_key IN (${List.filled(stale.length, '?').join(',')})',
          whereArgs: stale.map((row) => row['occurrence_key']).toList(),
        );
      }
      for (final item in planned) {
        final values = _jobValues(item, now.millisecondsSinceEpoch);
        await txn.insert(
          'notification_jobs',
          values,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        final updateValues = Map<String, Object?>.from(values)
          ..remove('created_at_utc');
        await txn.update(
          'notification_jobs',
          updateValues,
          where: 'occurrence_key = ?',
          whereArgs: [item.occurrenceKey],
        );
      }
    });

    final canNotify = await _notifications.notificationsEnabled();
    if (!canNotify) {
      await _markUnscheduled(db, planned);
      return;
    }
    final exact = await _notifications.canScheduleExact();
    for (final item in planned) {
      final rows = await db.query(
        'notification_jobs',
        columns: ['id'],
        where: 'occurrence_key = ?',
        whereArgs: [item.occurrenceKey],
        limit: 1,
      );
      if (rows.isEmpty) continue;
      final id = rows.single['id']! as int;
      try {
        await _notifications.schedule(
          id: id,
          medicationName: item.medicationName,
          dosageAmount: item.dosageAmount,
          dosageUnit: item.dosageUnit,
          medicationId: item.medicationId,
          at: item.scheduledAt,
          exact: exact,
          alertSettings: alertSettings,
        );
        await db.update(
          'notification_jobs',
          {'is_scheduled': 1, 'updated_at_utc': _nowUtc()},
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (_) {
        await db.update(
          'notification_jobs',
          {'is_scheduled': 0, 'updated_at_utc': _nowUtc()},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
  }

  Future<List<ReminderScheduleSource>> _loadSources() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
      SELECT m.id AS medication_id, m.name AS medication_name,
        m.dosage_amount, m.dosage_unit, m.start_date, m.end_date,
        m.timezone_id, s.id AS schedule_id, s.schedule_type, s.time_of_day
      FROM medications m
      JOIN medication_schedule_sets sets
        ON sets.medication_id = m.id AND sets.is_active = 1
      JOIN medication_schedules s ON s.schedule_set_id = sets.id
      WHERE m.is_active = 1 AND m.deleted_at_utc IS NULL
      ORDER BY s.time_of_day ASC, m.id ASC
    ''');
    if (rows.isEmpty) return const [];
    final scheduleIds = rows.map((row) => row['schedule_id']! as int).toList();
    final days = await db.query(
      'schedule_days',
      columns: ['schedule_id', 'weekday'],
      where:
          'schedule_id IN (${List.filled(scheduleIds.length, '?').join(',')})',
      whereArgs: scheduleIds,
    );
    final weekdays = <int, Set<int>>{};
    for (final day in days) {
      (weekdays[day['schedule_id']! as int] ??= <int>{}).add(
        day['weekday']! as int,
      );
    }
    return rows
        .map((row) {
          final scheduleId = row['schedule_id']! as int;
          return ReminderScheduleSource(
            medicationId: row['medication_id']! as int,
            scheduleId: scheduleId,
            medicationName: row['medication_name']! as String,
            dosageAmount: row['dosage_amount']! as String,
            dosageUnit: row['dosage_unit']! as String,
            startDate: row['start_date']! as String,
            endDate: row['end_date'] as String?,
            timezoneId: row['timezone_id']! as String,
            scheduleType: row['schedule_type']! as String,
            timeOfDay: row['time_of_day']! as String,
            weekdays: weekdays[scheduleId] ?? const {},
          );
        })
        .toList(growable: false);
  }

  Future<void> _markUnscheduled(
    Database db,
    List<PlannedNotification> planned,
  ) async {
    for (final item in planned) {
      await db.update(
        'notification_jobs',
        {'is_scheduled': 0, 'updated_at_utc': _nowUtc()},
        where: 'occurrence_key = ?',
        whereArgs: [item.occurrenceKey],
      );
    }
  }

  Map<String, Object?> _jobValues(PlannedNotification item, int now) => {
    'occurrence_key': item.occurrenceKey,
    'medication_id': item.medicationId,
    'schedule_id': item.scheduleId,
    'local_date': item.localDate,
    'scheduled_at_utc': item.scheduledAt.millisecondsSinceEpoch,
    'timezone_id': item.timezoneId,
    'medication_name': item.medicationName,
    'dosage_amount': item.dosageAmount,
    'dosage_unit': item.dosageUnit,
    'is_scheduled': 0,
    'created_at_utc': now,
    'updated_at_utc': now,
  };
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (ref) => NotificationScheduler(
    ref.watch(appDatabaseProvider),
    ref.watch(notificationServiceProvider),
    settingsStore: ref.watch(settingsStoreProvider),
  ),
);
