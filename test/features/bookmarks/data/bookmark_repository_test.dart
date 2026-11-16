import 'package:echoes/core/database/app_database.dart';
import 'package:echoes/features/bookmarks/data/bookmark_repository.dart';
import 'package:echoes/features/library/data/library_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late BookmarkRepository bookmarks;

  setUp(() async {
    db = memoryDatabase();
    clock = FakeClock();
    bookmarks = BookmarkRepository(db, clock: clock.call);
    await LibraryRepository(db, clock: clock.call).saveScannedSource(
      folder('tree:a', [
        book('dir:1', [chapter('f:1'), chapter('f:2')]),
        book('dir:2', [chapter('g:1')]),
      ]),
    );
  });

  tearDown(() => db.close());

  test('lista os marcadores do livro, mais recentes primeiro', () async {
    await bookmarks.add('dir:1', 'f:1', const Duration(seconds: 1));
    clock.tick();
    await bookmarks.add('dir:1', 'f:2', const Duration(seconds: 2));
    await bookmarks.add('dir:2', 'g:1', const Duration(seconds: 3));

    final list = await bookmarks.watchByBook('dir:1').first;
    expect([for (final b in list) b.position.inSeconds], [2, 1]);
    expect(list.first.createdAt, clock.now);
  });

  test('remover atualiza o stream', () async {
    final id = await bookmarks.add('dir:1', 'f:1', Duration.zero);
    final expectation = expectLater(
      bookmarks.watchByBook('dir:1').map((l) => l.length),
      emitsInOrder([1, 0]),
    );
    await Future<void>.delayed(Duration.zero);
    await bookmarks.remove(id);
    await expectation;
  });
}
