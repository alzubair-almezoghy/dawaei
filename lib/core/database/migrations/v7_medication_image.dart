import 'package:sqflite/sqflite.dart';

/// Stores an app-private relative path for an optional medication photo.
Future<void> upgradeToV7(DatabaseExecutor db) async {
  await db.execute('ALTER TABLE medications ADD COLUMN image_path TEXT');
}
