import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../data/medication_repository.dart';
import '../data/medication_image_storage.dart';
import '../data/care_recipient_repository.dart';
import '../models/medication.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => MedicationRepository(ref.watch(appDatabaseProvider)),
);

final careRecipientRepositoryProvider = Provider<CareRecipientRepository>(
  (ref) => CareRecipientRepository(ref.watch(appDatabaseProvider)),
);

final medicationImageStorageProvider = Provider<MedicationImageStorage>(
  (ref) => MedicationImageStorage(ref.watch(appDatabaseProvider)),
);

final medicationsProvider =
    AsyncNotifierProvider<MedicationsController, List<Medication>>(
      MedicationsController.new,
      retry: (retryCount, error) => null,
    );

class MedicationsController extends AsyncNotifier<List<Medication>> {
  MedicationRepository get _repository =>
      ref.read(medicationRepositoryProvider);

  @override
  Future<List<Medication>> build() => _repository.getAll();

  Future<int> save(Medication medication) async {
    final id = await _repository.save(medication);
    state = AsyncData(await _repository.getAll());
    await _reconcileNotifications();
    return id;
  }

  Future<void> setActive(int id, bool active) async {
    await _repository.setActive(id, active);
    state = AsyncData(await _repository.getAll());
    await _reconcileNotifications();
  }

  Future<void> archive(int id) async {
    await _repository.archive(id);
    state = AsyncData(await _repository.getAll());
    await _reconcileNotifications();
  }

  Future<void> refresh() async => state = AsyncData(await _repository.getAll());

  Future<void> _reconcileNotifications() async {
    try {
      await ref.read(notificationSchedulerProvider).reconcile();
    } catch (_) {
      // Local medication data remains saved if notification access is unavailable.
    }
  }
}
