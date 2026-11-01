import 'package:sqflite/sqflite.dart';

/// Records when a schedule revision stopped applying, without rewriting it.
Future<void> upgradeToV2(DatabaseExecutor db) async {
  await db.execute(
    'ALTER TABLE medication_schedule_sets ADD COLUMN effective_to_utc INTEGER',
  );
  await db.execute('''
    CREATE INDEX idx_schedule_sets_effective_history
    ON medication_schedule_sets(medication_id, effective_from_utc, effective_to_utc)
  ''');
}
