import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

enum DoseStatus {
  pending('pending'),
  taken('taken'),
  skipped('skipped'),
  missed('missed');

  const DoseStatus(this.databaseValue);
  final String databaseValue;

  static DoseStatus fromDatabase(String value) => switch (value) {
    'pending' => DoseStatus.pending,
    'taken' => DoseStatus.taken,
    'skipped' => DoseStatus.skipped,
    'missed' => DoseStatus.missed,
    _ => throw FormatException('Unknown dose status.'),
  };
}

@immutable
class DoseRecord {
  const DoseRecord({
    required this.id,
    required this.medicationId,
    required this.scheduleId,
    required this.localDate,
    required this.scheduledAtUtc,
    required this.timezoneId,
    required this.medicationName,
    required this.dosageAmount,
    required this.dosageUnit,
    required this.status,
    this.instructions,
    this.takenAtUtc,
    this.confirmedAtUtc,
  });

  final int id;
  final int medicationId;
  final int scheduleId;
  final String localDate;
  final int scheduledAtUtc;
  final String timezoneId;
  final String medicationName;
  final String dosageAmount;
  final String dosageUnit;
  final String? instructions;
  final DoseStatus status;
  final int? takenAtUtc;
  final int? confirmedAtUtc;

  tz.TZDateTime get scheduledAt => tz.TZDateTime.from(
    DateTime.fromMillisecondsSinceEpoch(scheduledAtUtc, isUtc: true),
    tz.getLocation(timezoneId),
  );

  factory DoseRecord.fromRow(Map<String, Object?> row) => DoseRecord(
    id: row['id']! as int,
    medicationId: row['medication_id']! as int,
    scheduleId: row['schedule_id']! as int,
    localDate: row['local_date']! as String,
    scheduledAtUtc: row['scheduled_at_utc']! as int,
    timezoneId: row['timezone_id']! as String,
    medicationName: row['medication_name']! as String,
    dosageAmount: row['dosage_amount']! as String,
    dosageUnit: row['dosage_unit']! as String,
    instructions: row['instructions'] as String?,
    status: DoseStatus.fromDatabase(row['status']! as String),
    takenAtUtc: row['taken_at_utc'] as int?,
    confirmedAtUtc: row['confirmed_at_utc'] as int?,
  );
}

@immutable
class AdherenceSummary {
  const AdherenceSummary({
    required this.total,
    required this.taken,
    required this.skipped,
    required this.missed,
    required this.pending,
  });

  final int total;
  final int taken;
  final int skipped;
  final int missed;
  final int pending;

  double? get rate => total == 0 ? null : taken / total;
}
