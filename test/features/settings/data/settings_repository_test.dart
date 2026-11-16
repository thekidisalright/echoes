import 'package:echoes/core/database/app_database.dart';
import 'package:echoes/features/library/domain/sort_order.dart';
import 'package:echoes/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/test_database.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = memoryDatabase();
    settings = SettingsRepository(db);
  });

  tearDown(() => db.close());

  test('último livro: grava, troca e apaga', () async {
    expect(await settings.getLastPlayedBookId(), isNull);
    await settings.setLastPlayedBookId('a');
    await settings.setLastPlayedBookId('b');
    expect(await settings.getLastPlayedBookId(), 'b');
    await settings.setLastPlayedBookId(null);
    expect(await settings.getLastPlayedBookId(), isNull);
  });

  test('ordem da biblioteca começa em "recentes" e é observável', () async {
    expect(await settings.getLibrarySort(), SortOrder.recent);
    final expectation = expectLater(
      settings.watchLibrarySort(),
      emitsInOrder([SortOrder.recent, SortOrder.title]),
    );
    await Future<void>.delayed(Duration.zero);
    await settings.setLibrarySort(SortOrder.title);
    await expectation;
    expect(await settings.getLibrarySort(), SortOrder.title);
  });

  test('valor desconhecido no banco vira "recentes"', () async {
    await db
        .into(db.settingsEntries)
        .insert(
          SettingsEntriesCompanion.insert(key: 'librarySort', value: 'xyz'),
        );
    expect(await settings.getLibrarySort(), SortOrder.recent);
  });
}
