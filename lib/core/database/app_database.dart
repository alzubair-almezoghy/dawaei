import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import 'migrations/v1_initial.dart';
import 'migrations/v2_schedule_history.dart';
import 'migrations/v3_notification_jobs.dart';
import 'migrations/v4_care_recipients.dart';
import 'migrations/v5_medication_indication.dart';
import 'migrations/v6_dose_tracking.dart';
import 'migrations/v7_medication_image.dart';

class AppDatabase {
  AppDatabase({DatabaseFactory? factory, this.path})
    : _factory = factory ?? databaseFactory;

  static const schemaVersion = 7;
  static const defaultPath = 'dawaei.db';

  final DatabaseFactory _factory;
  final String? path;
  Future<Database>? _opening;
  bool _closed = false;

  Future<Database> get database async {
    if (_closed) return Future.error(StateError('Database has been closed.'));
    final opening = _opening ??= _open();
    try {
      return await opening;
    } catch (_) {
      if (identical(_opening, opening)) _opening = null;
      rethrow;
    }
  }

  Future<Database> _open() async {
    final databasePath = path ?? p.join(await getDatabasesPath(), defaultPath);
    return _factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          // This PRAGMA returns a row. Android SQLite rejects it via execute.
          await db.rawQuery('PRAGMA busy_timeout = 5000');
        },
        onDowngrade:
            (db, oldVersion, newVersion) =>
                throw StateError(
                  'Database downgrade from $oldVersion to $newVersion is not supported.',
                ),
        onCreate: (db, version) async {
          await createSchemaV1(db);
          await upgradeToV2(db);
          await upgradeToV3(db);
          await upgradeToV4(db);
          await upgradeToV5(db);
          await upgradeToV6(db);
          await upgradeToV7(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 1 && newVersion >= 1) await createSchemaV1(db);
          if (oldVersion < 2 && newVersion >= 2) await upgradeToV2(db);
          if (oldVersion < 3 && newVersion >= 3) await upgradeToV3(db);
          if (oldVersion < 4 && newVersion >= 4) await upgradeToV4(db);
          if (oldVersion < 5 && newVersion >= 5) await upgradeToV5(db);
          if (oldVersion < 6 && newVersion >= 6) await upgradeToV6(db);
          if (oldVersion < 7 && newVersion >= 7) await upgradeToV7(db);
        },
      ),
    );
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final opening = _opening;
    if (opening == null) return;
    await (await opening).close();
  }
}
