import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/app_log.dart';
import '../data/settings_store.dart';
import '../models/app_settings.dart';

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => PreferencesSettingsStore(SharedPreferencesAsync()),
);

final settingsProvider = AsyncNotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
  retry: (retryCount, error) => null,
);

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    try {
      return await ref.watch(settingsStoreProvider).load();
    } catch (_) {
      AppLog.preferencesLoadFailed();
      rethrow;
    }
  }

  Future<void> setLanguage(String code) async {
    if (!{'ar', 'en'}.contains(code)) {
      throw ArgumentError.value(code, 'code', 'Unsupported language');
    }
    await _save(state.requireValue.copyWith(languageCode: code));
  }

  Future<void> setTheme(ThemeMode mode) =>
      _save(state.requireValue.copyWith(themeMode: mode));

  Future<void> setMedicationAlertMode(MedicationAlertMode mode) =>
      _save(state.requireValue.copyWith(medicationAlertMode: mode));

  Future<void> setMedicationAlertSound(MedicationAlertSound sound) =>
      _save(state.requireValue.copyWith(medicationAlertSound: sound));

  Future<void> setMedicationAlertVibration(bool enabled) =>
      _save(state.requireValue.copyWith(medicationAlertVibration: enabled));

  Future<void> setMedicationAlertsDuringDnd(bool enabled) =>
      _save(state.requireValue.copyWith(medicationAlertsDuringDnd: enabled));

  Future<void> _save(AppSettings settings) async {
    try {
      await ref.read(settingsStoreProvider).save(settings);
      state = AsyncData(settings);
    } catch (_) {
      // Keep the last persisted preference visible when a write fails.
      AppLog.preferencesSaveFailed();
      rethrow;
    }
  }
}
