import 'package:flutter/material.dart';

enum MedicationAlertMode { standard, alarm }

enum MedicationAlertSound { system, dawaei }

@immutable
class AppSettings {
  const AppSettings({
    this.languageCode = 'ar',
    this.themeMode = ThemeMode.system,
    this.medicationAlertMode = MedicationAlertMode.alarm,
    this.medicationAlertSound = MedicationAlertSound.dawaei,
    this.medicationAlertVibration = true,
    this.medicationAlertsDuringDnd = false,
  });

  final String languageCode;
  final ThemeMode themeMode;
  final MedicationAlertMode medicationAlertMode;
  final MedicationAlertSound medicationAlertSound;
  final bool medicationAlertVibration;
  final bool medicationAlertsDuringDnd;

  Locale get locale => Locale(languageCode);

  AppSettings copyWith({
    String? languageCode,
    ThemeMode? themeMode,
    MedicationAlertMode? medicationAlertMode,
    MedicationAlertSound? medicationAlertSound,
    bool? medicationAlertVibration,
    bool? medicationAlertsDuringDnd,
  }) => AppSettings(
    languageCode: languageCode ?? this.languageCode,
    themeMode: themeMode ?? this.themeMode,
    medicationAlertMode: medicationAlertMode ?? this.medicationAlertMode,
    medicationAlertSound: medicationAlertSound ?? this.medicationAlertSound,
    medicationAlertVibration:
        medicationAlertVibration ?? this.medicationAlertVibration,
    medicationAlertsDuringDnd:
        medicationAlertsDuringDnd ?? this.medicationAlertsDuringDnd,
  );
}
