import 'package:flutter/foundation.dart';

enum MedicationScheduleType {
  daily('daily'),
  specificDays('specific_days');

  const MedicationScheduleType(this.databaseValue);
  final String databaseValue;

  static MedicationScheduleType fromDatabase(String value) => switch (value) {
    'daily' => MedicationScheduleType.daily,
    'specific_days' => MedicationScheduleType.specificDays,
    _ => throw FormatException('Unknown medication schedule type.'),
  };
}

@immutable
class MedicationSchedule {
  MedicationSchedule({
    required this.type,
    required this.timeOfDay,
    Set<int> weekdays = const {},
  }) : weekdays = Set.unmodifiable(weekdays);

  /// Local wall-clock time, stored as zero-padded HH:mm.
  final String timeOfDay;
  final MedicationScheduleType type;

  /// ISO weekdays: Monday=1 through Sunday=7.
  final Set<int> weekdays;

  MedicationSchedule copyWith({
    String? timeOfDay,
    MedicationScheduleType? type,
    Set<int>? weekdays,
  }) => MedicationSchedule(
    type: type ?? this.type,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    weekdays: weekdays ?? this.weekdays,
  );
}

@immutable
class Medication {
  Medication({
    this.id,
    required this.name,
    required this.dosageAmount,
    required this.dosageUnit,
    this.form,
    required this.startDate,
    this.endDate,
    this.notes,
    this.indication,
    this.colorValue,
    this.recipientId,
    this.timezoneId = 'system',
    this.isActive = true,
    this.createdAtUtc,
    this.updatedAtUtc,
    this.deletedAtUtc,
    List<MedicationSchedule> schedules = const [],
  }) : schedules = List.unmodifiable(schedules);

  final int? id;
  final String name;

  /// Display text only; no dose conversion or medical calculations are done.
  final String dosageAmount;
  final String dosageUnit;
  final String? form;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final String? indication;
  final int? colorValue;

  /// Null associates this medication with the current user's own treatment.
  final int? recipientId;

  /// 'system' means the device's current local timezone; IANA id is resolved later.
  final String timezoneId;
  final bool isActive;
  final int? createdAtUtc;
  final int? updatedAtUtc;
  final int? deletedAtUtc;
  final List<MedicationSchedule> schedules;

  bool get isArchived => deletedAtUtc != null;

  Medication copyWith({
    String? name,
    String? dosageAmount,
    String? dosageUnit,
    String? form,
    bool clearForm = false,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    String? notes,
    bool clearNotes = false,
    String? indication,
    bool clearIndication = false,
    int? colorValue,
    int? recipientId,
    bool clearRecipient = false,
    MedicationScheduleType? scheduleType,
    Set<int>? weekdays,
    List<MedicationSchedule>? schedules,
    bool? isActive,
  }) => Medication(
    id: id,
    name: name ?? this.name,
    dosageAmount: dosageAmount ?? this.dosageAmount,
    dosageUnit: dosageUnit ?? this.dosageUnit,
    form: clearForm ? null : form ?? this.form,
    startDate: startDate ?? this.startDate,
    endDate: clearEndDate ? null : endDate ?? this.endDate,
    notes: clearNotes ? null : notes ?? this.notes,
    indication: clearIndication ? null : indication ?? this.indication,
    colorValue: colorValue ?? this.colorValue,
    recipientId: clearRecipient ? null : recipientId ?? this.recipientId,
    timezoneId: timezoneId,
    isActive: isActive ?? this.isActive,
    createdAtUtc: createdAtUtc,
    updatedAtUtc: updatedAtUtc,
    deletedAtUtc: deletedAtUtc,
    schedules:
        schedules ??
        this.schedules
            .map(
              (schedule) =>
                  schedule.copyWith(type: scheduleType, weekdays: weekdays),
            )
            .toList(),
  );
}

class MedicationValidationException implements Exception {
  const MedicationValidationException(this.field, this.messageKey);
  final String field;
  final String messageKey;

  @override
  String toString() => 'MedicationValidationException($field, $messageKey)';
}

abstract final class MedicationValidator {
  static const _timePattern = r'^(?:[01]\d|2[0-3]):[0-5]\d$';
  static final _amountPattern = RegExp(r'^\d+(?:[.,]\d{1,3})?$');

  static String normalizeAmount(String value) =>
      value
          .replaceAllMapped(
            RegExp('[٠-٩]'),
            (match) => String.fromCharCode(
              match.group(0)!.codeUnitAt(0) - 0x0660 + 0x30,
            ),
          )
          .replaceAllMapped(
            RegExp('[۰-۹]'),
            (match) => String.fromCharCode(
              match.group(0)!.codeUnitAt(0) - 0x06f0 + 0x30,
            ),
          )
          .replaceAll('٫', '.')
          .trim();

  static void validate(Medication medication) {
    final name = medication.name.trim();
    if (name.isEmpty || name.length > 100) {
      throw const MedicationValidationException(
        'name',
        'invalidMedicationName',
      );
    }
    final amount = normalizeAmount(medication.dosageAmount);
    if (!_amountPattern.hasMatch(amount) ||
        (double.tryParse(amount.replaceAll(',', '.')) ?? 0) <= 0) {
      throw const MedicationValidationException(
        'dosageAmount',
        'invalidDosageAmount',
      );
    }
    if (medication.dosageUnit.trim().isEmpty ||
        medication.dosageUnit.trim().length > 24) {
      throw const MedicationValidationException(
        'dosageUnit',
        'invalidDosageUnit',
      );
    }
    final startDate = DateTime(
      medication.startDate.year,
      medication.startDate.month,
      medication.startDate.day,
    );
    final endDate =
        medication.endDate == null
            ? null
            : DateTime(
              medication.endDate!.year,
              medication.endDate!.month,
              medication.endDate!.day,
            );
    if (endDate != null && endDate.isBefore(startDate)) {
      throw const MedicationValidationException(
        'startDate',
        'invalidMedicationDates',
      );
    }
    if ((medication.notes?.length ?? 0) > 1000) {
      throw const MedicationValidationException('notes', 'notesTooLong');
    }
    // An empty schedule list is an intentional as-needed medication with no
    // alarm. Scheduled medications are initialized with at least one draft in
    // MedicationFormScreen.
    final times = <String>{};
    for (final schedule in medication.schedules) {
      if (!RegExp(_timePattern).hasMatch(schedule.timeOfDay) ||
          !times.add(schedule.timeOfDay)) {
        throw const MedicationValidationException(
          'schedules',
          'invalidOrDuplicateTime',
        );
      }
      if (schedule.type == MedicationScheduleType.daily &&
          schedule.weekdays.isNotEmpty) {
        throw const MedicationValidationException(
          'weekdays',
          'invalidDailyDays',
        );
      }
      if (schedule.type == MedicationScheduleType.specificDays &&
          (schedule.weekdays.isEmpty ||
              schedule.weekdays.any((day) => day < 1 || day > 7))) {
        throw const MedicationValidationException(
          'weekdays',
          'selectAtLeastOneDay',
        );
      }
    }
    if (medication.colorValue != null &&
        (medication.colorValue! < 0 || medication.colorValue! > 0xffffffff)) {
      throw const MedicationValidationException(
        'colorValue',
        'invalidMedicationColor',
      );
    }
  }
}

String encodeLocalDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime decodeLocalDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) throw FormatException('Invalid stored local date.');
  final date = DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
  if (encodeLocalDate(date) != value) {
    throw FormatException('Invalid stored local date.');
  }
  return date;
}
