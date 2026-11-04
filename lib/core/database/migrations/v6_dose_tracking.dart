import 'package:sqflite/sqflite.dart';

/// Adds auditable dose states while retaining every existing dose snapshot.
Future<void> upgradeToV6(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE dose_records_v6 (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      medication_id INTEGER NOT NULL REFERENCES medications(id) ON DELETE RESTRICT,
      schedule_id INTEGER NOT NULL REFERENCES medication_schedules(id) ON DELETE RESTRICT,
      local_date TEXT NOT NULL,
      scheduled_at_utc INTEGER NOT NULL,
      timezone_id TEXT NOT NULL,
      utc_offset_minutes INTEGER NOT NULL,
      medication_name TEXT NOT NULL,
      dosage_amount TEXT NOT NULL,
      dosage_unit TEXT NOT NULL,
      medication_form TEXT,
      instructions TEXT,
      status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'taken', 'postponed', 'skipped', 'unconfirmed', 'missed')),
      taken_at_utc INTEGER,
      confirmed_at_utc INTEGER,
      status_recorded_at_utc INTEGER,
      postponed_until_utc INTEGER,
      created_at_utc INTEGER NOT NULL,
      updated_at_utc INTEGER NOT NULL,
      CHECK ((status = 'taken' AND taken_at_utc IS NOT NULL)
        OR (status != 'taken' AND taken_at_utc IS NULL)),
      UNIQUE (schedule_id, local_date)
    )
  ''');
  await db.execute('''
    INSERT INTO dose_records_v6 (
      id, medication_id, schedule_id, local_date, scheduled_at_utc,
      timezone_id, utc_offset_minutes, medication_name, dosage_amount,
      dosage_unit, medication_form, instructions, status, taken_at_utc,
      confirmed_at_utc, status_recorded_at_utc, created_at_utc, updated_at_utc
    )
    SELECT id, medication_id, schedule_id, local_date, scheduled_at_utc,
      timezone_id, utc_offset_minutes, medication_name, dosage_amount,
      dosage_unit, medication_form, instructions,
      CASE WHEN status = 'missed' THEN 'unconfirmed' ELSE status END,
      taken_at_utc, confirmed_at_utc, COALESCE(confirmed_at_utc, updated_at_utc),
      created_at_utc, updated_at_utc
    FROM dose_records
  ''');
  await db.execute('DROP TABLE dose_records');
  await db.execute('ALTER TABLE dose_records_v6 RENAME TO dose_records');
  await db.execute(
    'CREATE INDEX idx_doses_scheduled_at ON dose_records(scheduled_at_utc)',
  );
  await db.execute(
    'CREATE INDEX idx_doses_date_status ON dose_records(local_date, status)',
  );
  await db.execute(
    'CREATE INDEX idx_doses_medication ON dose_records(medication_id)',
  );
  await db.execute('''
    CREATE TABLE dose_status_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      dose_record_id INTEGER NOT NULL REFERENCES dose_records(id) ON DELETE CASCADE,
      previous_status TEXT,
      new_status TEXT NOT NULL,
      recorded_at_utc INTEGER NOT NULL,
      event_type TEXT NOT NULL,
      postponed_until_utc INTEGER
    )
  ''');
  await db.execute('''
    INSERT INTO dose_status_events (dose_record_id, previous_status, new_status, recorded_at_utc, event_type)
    SELECT id, NULL, status, COALESCE(status_recorded_at_utc, created_at_utc), 'migration_snapshot'
    FROM dose_records
  ''');
  await db.execute(
    'CREATE INDEX idx_dose_events_recorded ON dose_status_events(dose_record_id, recorded_at_utc)',
  );
}
