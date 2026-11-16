import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../library/domain/sort_order.dart';

/// Preferências guardadas na tabela chave/valor `settings`.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const _lastPlayedBookIdKey = 'lastPlayedBookId';
  static const _librarySortKey = 'librarySort';

  Future<String?> getLastPlayedBookId() => _get(_lastPlayedBookIdKey);

  /// `null` apaga o valor.
  Future<void> setLastPlayedBookId(String? bookId) =>
      _set(_lastPlayedBookIdKey, bookId);

  Future<SortOrder> getLibrarySort() async =>
      _parseSort(await _get(_librarySortKey));

  Stream<SortOrder> watchLibrarySort() =>
      _query(_librarySortKey)
          .watchSingleOrNull()
          .map((row) => _parseSort(row?.value));

  Future<void> setLibrarySort(SortOrder sort) =>
      _set(_librarySortKey, sort.name);

  static SortOrder _parseSort(String? value) => SortOrder.values.firstWhere(
    (s) => s.name == value,
    orElse: () => SortOrder.recent,
  );

  Future<String?> _get(String key) async =>
      (await _query(key).getSingleOrNull())?.value;

  Future<void> _set(String key, String? value) async {
    if (value == null) {
      await (_db.delete(
        _db.settingsEntries,
      )..where((s) => s.key.equals(key))).go();
    } else {
      await _db
          .into(_db.settingsEntries)
          .insertOnConflictUpdate(
            SettingsEntriesCompanion.insert(key: key, value: value),
          );
    }
  }

  SimpleSelectStatement<$SettingsEntriesTable, SettingRow> _query(String key) =>
      _db.select(_db.settingsEntries)..where((s) => s.key.equals(key));
}
