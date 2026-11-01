import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../data/dose_repository.dart';
import '../models/dose_record.dart';

final doseRepositoryProvider = Provider<DoseRepository>(
  (ref) => DoseRepository(ref.watch(appDatabaseProvider)),
);

final dosesForDateProvider = FutureProvider.autoDispose
    .family<List<DoseRecord>, DateTime>((ref, date) {
      return ref.watch(doseRepositoryProvider).getForDate(date);
    });

final adherenceSummaryProvider = FutureProvider.autoDispose
    .family<AdherenceSummary, DateTimeRange>((ref, range) {
      return ref.watch(doseRepositoryProvider).summary(range.start, range.end);
    });
