import 'package:dawaei/features/settings/data/settings_store.dart';
import 'package:dawaei/features/settings/models/app_settings.dart';

class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore([this.value = const AppSettings()]);
  AppSettings value;
  bool failLoad = false;
  bool failSave = false;

  @override
  Future<AppSettings> load() async {
    if (failLoad) throw StateError('load failed');
    return value;
  }

  @override
  Future<void> save(AppSettings settings) async {
    if (failSave) throw StateError('save failed');
    value = settings;
  }
}
