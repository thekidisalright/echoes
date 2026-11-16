import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Banco SQLite do app (`echoes.sqlite` no diretório de suporte).
///
/// Passe um [QueryExecutor] para usar outro banco, como
/// `NativeDatabase.memory()` nos testes.
@DriftDatabase(
  tables: [
    Sources,
    Books,
    Chapters,
    ProgressEntries,
    Bookmarks,
    SettingsEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _open() => driftDatabase(
    name: 'echoes',
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationSupportDirectory,
    ),
  );
}
