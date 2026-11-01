import 'package:sqflite/sqflite.dart';

/// Adds local care-recipient profiles and an optional medication association.
/// Existing medications remain associated with the signed-in/current user.
Future<void> upgradeToV4(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE care_recipients (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 80),
      relationship TEXT CHECK (relationship IS NULL OR length(relationship) <= 60),
      created_at_utc INTEGER NOT NULL
    )
  ''');
  await db.execute('ALTER TABLE medications ADD COLUMN recipient_id INTEGER');
  await db.execute(
    'CREATE INDEX idx_medications_recipient ON medications(recipient_id)',
  );
}
