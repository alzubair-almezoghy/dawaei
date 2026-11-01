import 'package:dawaei/features/settings/models/app_settings.dart';
import 'package:dawaei/features/settings/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_settings_store.dart';

void main() {
  late MemorySettingsStore store;
  late ProviderContainer container;

  setUp(() {
    store = MemorySettingsStore();
    container = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
  });
  tearDown(() => container.dispose());

  test('defaults to Arabic and follows the system theme', () async {
    final settings = await container.read(settingsProvider.future);
    expect(settings.languageCode, 'ar');
    expect(settings.themeMode, ThemeMode.system);
  });

  test('language and theme survive a new provider container', () async {
    await container.read(settingsProvider.future);
    final controller = container.read(settingsProvider.notifier);
    await controller.setLanguage('en');
    await controller.setTheme(ThemeMode.dark);
    final reopened = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(reopened.dispose);
    final restored = await reopened.read(settingsProvider.future);
    expect(restored.languageCode, 'en');
    expect(restored.themeMode, ThemeMode.dark);
  });

  test('medication alert choices persist and can be updated', () async {
    await container.read(settingsProvider.future);
    final controller = container.read(settingsProvider.notifier);
    await controller.setMedicationAlertMode(MedicationAlertMode.standard);
    await controller.setMedicationAlertSound(MedicationAlertSound.system);
    await controller.setMedicationAlertVibration(false);
    await controller.setMedicationAlertsDuringDnd(true);

    final reopened = ProviderContainer(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(reopened.dispose);
    final restored = await reopened.read(settingsProvider.future);
    expect(restored.medicationAlertMode, MedicationAlertMode.standard);
    expect(restored.medicationAlertSound, MedicationAlertSound.system);
    expect(restored.medicationAlertVibration, isFalse);
    expect(restored.medicationAlertsDuringDnd, isTrue);
  });

  test('failed write leaves the last saved state intact', () async {
    await container.read(settingsProvider.future);
    store.failSave = true;
    await expectLater(
      container.read(settingsProvider.notifier).setLanguage('en'),
      throwsStateError,
    );
    expect(container.read(settingsProvider).requireValue.languageCode, 'ar');
    expect(store.value.languageCode, 'ar');
  });

  test('unsupported locales are rejected before persistence', () async {
    await container.read(settingsProvider.future);
    await expectLater(
      container.read(settingsProvider.notifier).setLanguage('xx'),
      throwsArgumentError,
    );
    expect(store.value.languageCode, 'ar');
  });

  test('read failure can recover after explicit retry', () async {
    store.failLoad = true;
    await expectLater(
      container.read(settingsProvider.future),
      throwsStateError,
    );
    store.failLoad = false;
    store.value = const AppSettings(languageCode: 'en');
    container.invalidate(settingsProvider);
    expect((await container.read(settingsProvider.future)).languageCode, 'en');
  });
}
