import 'package:sqflite/sqflite.dart';

/// First on-disk schema. Changes ship as new versioned migrations.
Future<void> createSchemaV1(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE medications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 100),
      dosage_amount TEXT NOT NULL CHECK (length(trim(dosage_amount)) BETWEEN 1 AND 24),
      dosage_unit TEXT NOT NULL CHECK (length(trim(dosage_unit)) BETWEEN 1 AND 24),
      medication_form TEXT,
      start_date TEXT NOT NULL,
      end_date TEXT,
      timezone_id TEXT NOT NULL DEFAULT 'system',
      notes TEXT CHECK (notes IS NULL OR length(notes) <= 1000),
      color_value INTEGER,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      deleted_at_utc INTEGER,
      created_at_utc INTEGER NOT NULL,
      updated_at_utc INTEGER NOT NULL,
      CHECK (end_date IS NULL OR end_date >= start_date)
    )
  ''');
  await db.execute('''
    CREATE TABLE medication_schedule_sets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      medication_id INTEGER NOT NULL REFERENCES medications(id) ON DELETE RESTRICT,
      effective_from_utc INTEGER NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
    )
  ''');
  await db.execute('''
    CREATE UNIQUE INDEX idx_schedule_sets_one_active
    ON medication_schedule_sets(medication_id) WHERE is_active = 1
  ''');
  await db.execute('''
    CREATE INDEX idx_schedule_sets_medication_history
    ON medication_schedule_sets(medication_id, effective_from_utc DESC)
  ''');
  await db.execute('''
    CREATE TABLE medication_schedules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      schedule_set_id INTEGER NOT NULL
        REFERENCES medication_schedule_sets(id) ON DELETE RESTRICT,
      schedule_type TEXT NOT NULL CHECK (schedule_type IN ('daily', 'specific_days')),
      time_of_day TEXT NOT NULL CHECK (
        length(time_of_day) = 5 AND
        substr(time_of_day, 1, 2) BETWEEN '00' AND '23' AND
        substr(time_of_day, 4, 2) BETWEEN '00' AND '59' AND
        substr(time_of_day, 3, 1) = ':'
      ),
      UNIQUE (schedule_set_id, time_of_day)
    )
  ''');
  await db.execute('''
    CREATE TABLE schedule_days (
      schedule_id INTEGER NOT NULL
        REFERENCES medication_schedules(id) ON DELETE RESTRICT,
      weekday INTEGER NOT NULL CHECK (weekday BETWEEN 1 AND 7),
      PRIMARY KEY (schedule_id, weekday)
    )
  ''');
  await db.execute('''
    CREATE TABLE dose_records (
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
        CHECK (status IN ('pending', 'taken', 'skipped', 'missed')),
      taken_at_utc INTEGER,
      confirmed_at_utc INTEGER,
      created_at_utc INTEGER NOT NULL,
      updated_at_utc INTEGER NOT NULL,
      CHECK ((status = 'taken' AND taken_at_utc IS NOT NULL)
        OR (status != 'taken' AND taken_at_utc IS NULL)),
      UNIQUE (schedule_id, local_date)
    )
  ''');
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
    CREATE INDEX idx_medications_visible ON medications(is_active, deleted_at_utc)
  ''');
}
