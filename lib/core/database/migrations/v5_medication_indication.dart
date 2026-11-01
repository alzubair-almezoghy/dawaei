import 'package:sqflite/sqflite.dart';

/// Stores the optional reason a medication is being taken.
Future<void> upgradeToV5(DatabaseExecutor db) async {
  await db.execute('ALTER TABLE medications ADD COLUMN indication TEXT');
}
