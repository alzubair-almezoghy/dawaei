import 'package:sqflite/sqflite.dart';

/// Stable, bounded Android notification IDs are allocated from these rows.
/// One row represents one schedule occurrence; dose history is stored separately
/// in dose_records.
Future<void> upgradeToV3(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE notification_jobs (
      id INTEGER PRIMARY KEY AUTOINCREMENT
        CHECK (id BETWEEN 1 AND 2147483647),
      occurrence_key TEXT NOT NULL UNIQUE,
      medication_id INTEGER NOT NULL REFERENCES medications(id) ON DELETE RESTRICT,
      schedule_id INTEGER NOT NULL REFERENCES medication_schedules(id) ON DELETE RESTRICT,
      local_date TEXT NOT NULL,
      scheduled_at_utc INTEGER NOT NULL,
      timezone_id TEXT NOT NULL,
      medication_name TEXT NOT NULL,
      dosage_amount TEXT NOT NULL,
      dosage_unit TEXT NOT NULL,
      is_scheduled INTEGER NOT NULL DEFAULT 0 CHECK (is_scheduled IN (0, 1)),
      created_at_utc INTEGER NOT NULL,
      updated_at_utc INTEGER NOT NULL,
      UNIQUE (schedule_id, local_date)
    )
  ''');
  await db.execute(
    'CREATE INDEX idx_notification_jobs_scheduled ON notification_jobs(scheduled_at_utc)',
  );
}
