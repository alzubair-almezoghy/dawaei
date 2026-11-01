import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

final databaseFactoryProvider = Provider<DatabaseFactory>(
  (ref) => databaseFactory,
);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(factory: ref.watch(databaseFactoryProvider));
  ref.onDispose(() => unawaited(database.close()));
  return database;
});
