import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

abstract interface class SettingsStore {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class PreferencesSettingsStore implements SettingsStore {
  PreferencesSettingsStore(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _key = 'dawaei.preferences.v1';

  @override
  Future<AppSettings> load() async {
    // One value avoids partially persisting a language/theme pair.
    final raw = await _preferences.getString(_key);
    final parts = raw?.split(':');
    if (parts == null || parts.length < 2) return const AppSettings();
    final language = {'ar', 'en'}.contains(parts[0]) ? parts[0] : 'ar';
    final theme = switch (parts[1]) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final alertMode = switch (parts.length > 2 ? parts[2] : '') {
      'standard' => MedicationAlertMode.standard,
      _ => MedicationAlertMode.alarm,
    };
    final sound = switch (parts.length > 3 ? parts[3] : '') {
      'system' => MedicationAlertSound.system,
      _ => MedicationAlertSound.dawaei,
    };
    final vibration = parts.length > 4 ? parts[4] != 'false' : true;
    final duringDnd = parts.length > 5 && parts[5] == 'true';
    return AppSettings(
      languageCode: language,
      themeMode: theme,
      medicationAlertMode: alertMode,
      medicationAlertSound: sound,
      medicationAlertVibration: vibration,
      medicationAlertsDuringDnd: duringDnd,
    );
  }

  @override
  Future<void> save(AppSettings settings) => _preferences.setString(
    _key,
    '${settings.languageCode}:${settings.themeMode.name}:'
    '${settings.medicationAlertMode.name}:'
    '${settings.medicationAlertSound.name}:'
    '${settings.medicationAlertVibration}:'
    '${settings.medicationAlertsDuringDnd}',
  );
}
