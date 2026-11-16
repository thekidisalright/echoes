import 'package:echoes/core/database/app_database.dart';
import 'package:echoes/features/bookmarks/data/bookmark_repository.dart';
import 'package:echoes/features/import/domain/import_mode.dart';
import 'package:echoes/features/library/data/library_repository.dart';
import 'package:echoes/features/library/domain/library_source.dart';
import 'package:echoes/features/library/domain/sort_order.dart';
import 'package:echoes/features/player/data/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late LibraryRepository library;
  late ProgressRepository progress;
  late BookmarkRepository bookmarks;

  setUp(() {
    db = memoryDatabase();
    clock = FakeClock();
    library = LibraryRepository(db, clock: clock.call);
    progress = ProgressRepository(db, clock: clock.call);
    bookmarks = BookmarkRepository(db, clock: clock.call);
  });

  tearDown(() => db.close());

  group('saveScannedSource', () {
    test('salva origem, livros e capítulos na ordem do escaneamento', () async {
      await library.saveScannedSource(
        folder('tree:a', [
          book(
            'dir:1',
            [
              chapter('f:1', durationMs: 1000),
              chapter('f:2', durationMs: 2500),
            ],
            title: 'Misery',
            author: 'Stephen King',
            coverPath: '/covers/1.jpg',
          ),
        ]),
      );

      final b = (await library.getBook('dir:1'))!;
      expect(b.title, 'Misery');
      expect(b.author, 'Stephen King');
      expect(b.coverPath, '/covers/1.jpg');
      expect(b.chapterCount, 2);
      expect(b.totalDuration, const Duration(milliseconds: 3500));
      expect(b.createdAt, clock.now);

      final chapters = await library.chaptersOf('dir:1');
      expect([for (final c in chapters) c.id], ['f:1', 'f:2']);
      expect([for (final c in chapters) c.sortOrder], [0, 1]);

      final sources = await library.watchSources().first;
      expect(sources, hasLength(1));
      expect(sources.single.kind, SourceKind.folder);
      expect(sources.single.importMode, ImportMode.booksInFolders);
      expect(sources.single.bookCount, 1);
      expect(sources.single.available, isTrue);
    });

    test('livro sem nenhuma duração fica com duração total nula', () async {
      await library.saveScannedSource(
        folder('tree:a', [
          book('dir:1', [chapter('f:1')]),
        ]),
      );
      expect((await library.getBook('dir:1'))!.totalDuration, isNull);
    });

    test(
      'reimportação preserva edições, lastPlayedAt, createdAt e progresso',
      () async {
        await library.saveScannedSource(
          folder('tree:a', [
            book('dir:1', [chapter('f:1'), chapter('f:2')], title: 'Antigo'),
          ]),
        );
        final created = clock.now;
        await library.updateBookDetails(
          'dir:1',
          title: ' Meu título ',
          author: 'Eu',
          coverPath: '/covers/custom.jpg',
        );
        clock.tick();
        await progress.saveProgress(
          'dir:1',
          'f:2',
          const Duration(seconds: 42),
        );
        await progress.touchLastPlayed('dir:1');
        final played = clock.now;

        clock.tick();
        await library.saveScannedSource(
          folder('tree:a', [
            book(
              'dir:1',
              [chapter('f:1'), chapter('f:2'), chapter('f:3')],
              title: 'Novo',
              author: 'Autor das tags',
              coverPath: '/covers/scanned.jpg',
            ),
          ]),
        );

        final b = (await library.getBook('dir:1'))!;
        expect(b.scannedTitle, 'Novo');
        expect(b.scannedAuthor, 'Autor das tags');
        expect(b.scannedCoverPath, '/covers/scanned.jpg');
        expect(b.title, 'Meu título');
        expect(b.author, 'Eu');
        expect(b.coverPath, '/covers/custom.jpg');
        expect(b.chapterCount, 3);
        expect(b.createdAt, created);
        expect(b.lastPlayedAt, played);

        final p = (await progress.getProgress('dir:1'))!;
        expect(p.chapterId, 'f:2');
        expect(p.position, const Duration(seconds: 42));
      },
    );

    test('remove livros e capítulos que não vieram no escaneamento', () async {
      await library.saveScannedSource(
        folder('tree:a', [
          book('dir:1', [chapter('f:1'), chapter('f:2')]),
          book('dir:2', [chapter('f:3')]),
        ]),
      );
      await library.saveScannedSource(
        folder('tree:a', [
          book('dir:1', [chapter('f:2'), chapter('f:4')]),
        ]),
      );

      expect(await library.getBook('dir:2'), isNull);
      expect(await library.chaptersOf('dir:2'), isEmpty);
      final chapters = await library.chaptersOf('dir:1');
      expect([for (final c in chapters) c.id], ['f:2', 'f:4']);
      expect([for (final c in chapters) c.sortOrder], [0, 1]);
    });

    test('não mexe em livros de outras origens', () async {
      await library.saveScannedSource(
        folder('tree:a', [
          book('dir:a', [chapter('a:1')]),
        ]),
      );
      await library.saveScannedSource(
        folder('tree:b', [
          book('dir:b', [chapter('b:1')]),
        ]),
      );
      await library.saveScannedSource(folder('tree:a', []));

      expect(await library.getBook('dir:a'), isNull);
      expect(await library.getBook('dir:b'), isNotNull);
    });

    test(
      'progresso de capítulo removido volta ao primeiro capítulo, posição 0',
      () async {
        await library.saveScannedSource(
          folder('tree:a', [
            book('dir:1', [chapter('f:1'), chapter('f:2'), chapter('f:3')]),
            book('dir:2', [chapter('g:1'), chapter('g:2')]),
          ]),
        );
        await progress.saveProgress('dir:1', 'f:3', const Duration(minutes: 5));
        await progress.saveProgress('dir:2', 'g:2', const Duration(minutes: 7));
        await bookmarks.add('dir:1', 'f:3', const Duration(minutes: 1));
        await bookmarks.add('dir:1', 'f:2', const Duration(minutes: 2));

        clock.tick();
        await library.saveScannedSource(
          folder('tree:a', [
            book('dir:1', [chapter('f:0'), chapter('f:2')]),
            book('dir:2', [chapter('g:1'), chapter('g:2')]),
          ]),
        );

        final moved = (await progress.getProgress('dir:1'))!;
        expect(moved.chapterId, 'f:0');
        expect(moved.position, Duration.zero);
        expect(moved.updatedAt, clock.now);

        final kept = (await progress.getProgress('dir:2'))!;
        expect(kept.chapterId, 'g:2');
        expect(kept.position, const Duration(minutes: 7));

        final marks = await bookmarks.watchByBook('dir:1').first;
        expect([for (final m in marks) m.chapterId], ['f:2']);
      },
    );
  });

  test('remover origem apaga livros, capítulos, progresso e marcadores '
      '(cascade)', () async {
    await library.saveScannedSource(
      folder('tree:a', [
        book('dir:1', [chapter('f:1')]),
      ]),
    );
    await progress.saveProgress('dir:1', 'f:1', const Duration(seconds: 3));
    await bookmarks.add('dir:1', 'f:1', const Duration(seconds: 1));

    await library.removeSource('tree:a');

    expect(await library.getBook('dir:1'), isNull);
    expect(await library.chaptersOf('dir:1'), isEmpty);
    expect(await progress.getProgress('dir:1'), isNull);
    expect(await bookmarks.watchByBook('dir:1').first, isEmpty);
    expect(await db.select(db.chapters).get(), isEmpty);
    expect(await db.select(db.progressEntries).get(), isEmpty);
    expect(await db.select(db.bookmarks).get(), isEmpty);
    expect(await library.watchSources().first, isEmpty);
  });

  group('edição do livro', () {
    setUp(
      () => library.saveScannedSource(
        folder('tree:a', [
          book(
            'dir:1',
            [chapter('f:1')],
            title: 'Original',
            author: 'Autor',
            coverPath: '/covers/a.jpg',
          ),
        ]),
      ),
    );

    test('capa nula mantém a capa personalizada atual', () async {
      await library.updateBookDetails(
        'dir:1',
        title: 'A',
        author: '',
        coverPath: '/covers/c1.jpg',
      );
      await library.updateBookDetails('dir:1', title: 'B', author: '');
      final b = (await library.getBook('dir:1'))!;
      expect(b.title, 'B');
      expect(b.author, '');
      expect(b.coverPath, '/covers/c1.jpg');
    });

    test('título vazio é recusado', () {
      expect(
        () => library.updateBookDetails('dir:1', title: '  ', author: ''),
        throwsArgumentError,
      );
    });

    test('restaurar volta aos dados da importação', () async {
      await library.updateBookDetails(
        'dir:1',
        title: 'Editado',
        author: 'Outro',
        coverPath: '/covers/c.jpg',
      );
      await library.resetBookDetails('dir:1');
      final b = (await library.getBook('dir:1'))!;
      expect(b.hasCustomDetails, isFalse);
      expect(b.title, 'Original');
      expect(b.author, 'Autor');
      expect(b.coverPath, '/covers/a.jpg');
    });
  });

  group('watchLibrary', () {
    setUp(() async {
      await library.saveScannedSource(
        folder('tree:a', [
          book('dir:1', [chapter('a')], title: 'Livro 10', author: 'Zé'),
          book('dir:2', [chapter('b')], title: 'livro 2', author: 'Ana'),
          book('dir:3', [chapter('c')], title: 'Ébano', author: 'Ana'),
        ]),
      );
    });

    test('ordena por título em ordem natural', () async {
      final list = await library.watchLibrary(sort: SortOrder.title).first;
      expect(
        [for (final s in list) s.book.title],
        ['Ébano', 'livro 2', 'Livro 10'],
      );
    });

    test('ordena por mais recentes; não tocados por último', () async {
      clock.tick();
      await progress.touchLastPlayed('dir:2');
      clock.tick();
      await progress.touchLastPlayed('dir:3');
      final list = await library.watchLibrary().first;
      expect([for (final s in list) s.book.id], ['dir:3', 'dir:2', 'dir:1']);
    });

    test(
      'busca em título e autor exibidos, sem diferenciar maiúsculas',
      () async {
        await library.updateBookDetails('dir:1', title: 'Outro', author: 'Zé');
        expect([
          for (final s in await library.watchLibrary(query: 'ANA').first)
            s.book.id,
        ], unorderedEquals(['dir:2', 'dir:3']));
        expect(
          [
            for (final s in await library.watchLibrary(query: 'ébano').first)
              s.book.id,
          ],
          ['dir:3'],
        );
        expect(await library.watchLibrary(query: 'Livro 10').first, isEmpty);
        expect(
          (await library.watchLibrary(query: 'outro').first).single.book.id,
          'dir:1',
        );
      },
    );

    test('expõe a disponibilidade da origem', () async {
      await library.setSourceAvailability('tree:a', available: false);
      final list = await library.watchLibrary().first;
      expect(list.every((s) => !s.sourceAvailable), isTrue);
    });

    test('emite de novo quando o banco muda', () async {
      final stream = library.watchLibrary(sort: SortOrder.title);
      final expectation = expectLater(
        stream.map((l) => l.length),
        emitsInOrder([3, 4]),
      );
      await Future<void>.delayed(Duration.zero);
      await library.saveScannedSource(
        folder('tree:b', [
          book('dir:b', [chapter('x')]),
        ]),
      );
      await expectation;
    });
  });

  group('watchContinueListening', () {
    test(
      'até 3 livros tocados, mais recentes primeiro, com progresso',
      () async {
        await library.saveScannedSource(
          folder('tree:a', [
            for (var i = 1; i <= 5; i++)
              book('dir:$i', [
                chapter('$i:1', durationMs: 60000),
                chapter('$i:2', durationMs: 30000),
                chapter('$i:3', durationMs: 10000),
              ]),
          ]),
        );
        for (final id in ['dir:1', 'dir:2', 'dir:3', 'dir:4']) {
          clock.tick();
          await progress.touchLastPlayed(id);
        }
        await progress.saveProgress('dir:4', '4:3', const Duration(seconds: 5));

        final list = await library.watchContinueListening().first;
        expect([for (final s in list) s.book.id], ['dir:4', 'dir:3', 'dir:2']);

        final p = list.first.progress!;
        expect(p.chapterIndex, 2);
        expect(p.elapsedBeforeChapter, const Duration(seconds: 90));
        expect(list.first.fractionListened, closeTo(95 / 100, 1e-9));
        expect(list[1].progress, isNull);
        expect(list[1].fractionListened, 0);
      },
    );

    test('sem durações, a fração usa o índice do capítulo', () async {
      await library.saveScannedSource(
        folder('tree:a', [
          book('dir:1', [
            chapter('f:1'),
            chapter('f:2'),
            chapter('f:3'),
            chapter('f:4'),
          ]),
        ]),
      );
      await progress.touchLastPlayed('dir:1');
      await progress.saveProgress('dir:1', 'f:2', const Duration(minutes: 1));
      final summary = (await library.watchContinueListening().first).single;
      expect(summary.fractionListened, 0.25);
    });
  });

  test('chapterUrisOutside lista só capítulos de outras origens', () async {
    await library.saveScannedSource(
      folder('tree:a', [
        book('dir:a', [chapter('a:1'), chapter('a:2')]),
      ]),
    );
    await library.saveScannedSource(
      folder('tree:b', [
        book('dir:b', [chapter('b:1')]),
      ]),
    );
    expect(await library.chapterUrisOutside('tree:a'), {'b:1'});
    expect(await library.chapterUrisOutside('tree:new'), {'a:1', 'a:2', 'b:1'});
  });

  test('coverPathsInUse reúne capas escaneadas e personalizadas', () async {
    await library.saveScannedSource(
      folder('tree:a', [
        book('dir:1', [chapter('f:1')], coverPath: '/c/1.jpg'),
        book('dir:2', [chapter('f:2')]),
      ]),
    );
    await library.updateBookDetails(
      'dir:2',
      title: 'x',
      author: '',
      coverPath: '/c/custom.png',
    );
    expect(await library.coverPathsInUse(), {'/c/1.jpg', '/c/custom.png'});
  });

  test('getSource devolve modo e contagem de livros', () async {
    await library.saveScannedSource(
      folder('tree:a', [
        book('tree:a', [chapter('f:1')]),
      ], mode: ImportMode.oneBook),
    );
    final source = (await library.getSource('tree:a'))!;
    expect(source.importMode, ImportMode.oneBook);
    expect(source.bookCount, 1);
    expect(await library.getSource('nada'), isNull);
  });
}
