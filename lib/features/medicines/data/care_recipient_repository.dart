import '../../../core/database/app_database.dart';
import '../models/care_recipient.dart';

class CareRecipientRepository {
  CareRecipientRepository(this._database, {int Function()? nowUtc})
    : _nowUtc = nowUtc ?? _systemNowUtc;

  final AppDatabase _database;
  final int Function() _nowUtc;
  static int _systemNowUtc() => DateTime.now().toUtc().millisecondsSinceEpoch;

  Future<List<CareRecipient>> getAll() async {
    final db = await _database.database;
    final rows = await db.query(
      'care_recipients',
      orderBy: 'name COLLATE NOCASE',
    );
    return List.unmodifiable(rows.map(_fromRow));
  }

  Future<int> save(CareRecipient recipient) async {
    final name = recipient.name.trim();
    final relationship = recipient.relationship?.trim();
    if (name.isEmpty || name.length > 80 || (relationship?.length ?? 0) > 60) {
      throw const FormatException('Invalid care recipient details.');
    }
    final db = await _database.database;
    final values = <String, Object?>{
      'name': name,
      'relationship':
          relationship == null || relationship.isEmpty ? null : relationship,
    };
    if (recipient.id == null) {
      return db.insert('care_recipients', {
        ...values,
        'created_at_utc': _nowUtc(),
      });
    }
    final updated = await db.update(
      'care_recipients',
      values,
      where: 'id = ?',
      whereArgs: [recipient.id],
    );
    if (updated == 0) throw StateError('Care recipient no longer exists.');
    return recipient.id!;
  }

  Future<void> delete(int id) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.update(
        'medications',
        {'recipient_id': null},
        where: 'recipient_id = ?',
        whereArgs: [id],
      );
      final removed = await txn.delete(
        'care_recipients',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (removed == 0) throw StateError('Care recipient no longer exists.');
    });
  }

  static CareRecipient _fromRow(Map<String, Object?> row) => CareRecipient(
    id: row['id']! as int,
    name: row['name']! as String,
    relationship: row['relationship'] as String?,
    createdAtUtc: row['created_at_utc']! as int,
  );
}
