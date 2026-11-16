import 'package:echoes/core/metadata/metadata_reader.dart';
import 'package:echoes/core/storage/storage_gateway.dart';
import 'package:echoes/features/import/data/library_scanner.dart';
import 'package:echoes/features/import/domain/import_mode.dart';
import 'package:echoes/features/import/domain/import_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_metadata_reader.dart';
import '../../../fakes/fake_storage_gateway.dart';

const root = 'tree:raiz';

void main() {
  late FakeStorageGateway storage;
  late FakeMetadataReader metadata;
  late LibraryScanner scanner;

  setUp(() {
    storage = FakeStorageGateway()..permissions.add(root);
    metadata = FakeMetadataReader();
    scanner = LibraryScanner(storage, metadata);
  });

  Future<List<BookScan>> scan(
    ImportMode mode, {
    Set<String> skip = const {},
    List<ImportProgress>? progress,
  }) => scanner.scanFolder(
    rootUri: root,
    rootName: 'Audiobooks',
    sourceId: root,
    mode: mode,
    skipUris: skip,
    onProgress: progress?.add,
  );

  List<String> chapterNames(BookScan b) => [
    for (final c in b.book.chapters) c.uri.split('/').last,
  ];

  group('árvore aninhada', () {
    setUp(() {
      storage
        ..addFile(root, 'intro.mp3')
        ..addFile(root, 'Livro B/CD 10/01.mp3')
        ..addFile(root, 'Livro B/CD 2/01.mp3')
        ..addFile(root, 'Livro B/CD 2/02.mp3')
        ..addFile(root, 'Livro A/capitulo.m4b')
        ..addFile(root, 'Livro A/notas.txt')
        ..addFile(root, 'Sem audio/capa.jpg');
    });

    test('cada pasta com áudio vira um livro, em ordem natural', () async {
      final progress = <ImportProgress>[];
      final books = await scan(ImportMode.booksInFolders, progress: progress);

      expect(
        [for (final b in books) b.book.title],
        ['Audiobooks', 'Livro A', 'CD 2', 'CD 10'],
      );
      expect(books.first.book.id, root);
      expect(books[1].book.id, '$root/Livro A');
      expect(chapterNames(books[2]), ['01.mp3', '02.mp3']);
      expect(chapterNames(books[1]), ['capitulo.m4b']);
      expect(
        [
          for (final p in progress.cast<ImportReadingFolder>())
            '${p.current}/${p.total}',
        ],
        ['1/4', '2/4', '3/4', '4/4'],
      );
    });

    test('pasta inteira vira um livro, ordenado por pasta e faixa', () async {
      final progress = <ImportProgress>[];
      final books = await scan(ImportMode.oneBook, progress: progress);

      expect(books, hasLength(1));
      final book = books.single.book;
      expect(book.id, root);
      expect(book.title, 'Audiobooks');
      expect(
        [for (final c in book.chapters) c.uri],
        [
          '$root/intro.mp3',
          '$root/Livro A/capitulo.m4b',
          '$root/Livro B/CD 2/01.mp3',
          '$root/Livro B/CD 2/02.mp3',
          '$root/Livro B/CD 10/01.mp3',
        ],
      );
      expect(progress.single, isA<ImportReadingFiles>());
      expect((progress.single as ImportReadingFiles).count, 5);
      expect((books.single.cover! as FolderImageCover).image.name, 'capa.jpg');
    });
  });

  test('pasta sem áudio não gera livro', () async {
    storage.addFile(root, 'capa.jpg');
    expect(await scan(ImportMode.booksInFolders), isEmpty);
    expect(await scan(ImportMode.oneBook), isEmpty);
  });

  group('ordem das faixas', () {
    test('numeradas pelo número, depois o resto em ordem natural', () async {
      for (final name in [
        'Epílogo.mp3',
        '10 - Fim.mp3',
        '2 - Meio.mp3',
        'Track 1.mp3',
        'Apêndice 2.mp3',
        'apêndice 10.mp3',
      ]) {
        storage.addFile(root, name);
      }
      final book = (await scan(ImportMode.booksInFolders)).single;
      expect(chapterNames(book), [
        'Track 1.mp3',
        '2 - Meio.mp3',
        '10 - Fim.mp3',
        'Apêndice 2.mp3',
        'apêndice 10.mp3',
        'Epílogo.mp3',
      ]);
    });

    test('sem número, ordem natural', () async {
      for (final name in ['parte10.mp3', 'parte2.mp3', 'Parte1.mp3']) {
        storage.addFile(root, name);
      }
      final book = (await scan(ImportMode.booksInFolders)).single;
      expect(chapterNames(book), ['Parte1.mp3', 'parte2.mp3', 'parte10.mp3']);
    });
  });

  group('título, autor e capítulos', () {
    test('usa as tags quando existem', () async {
      final a = storage.addFile(root, 'Livro/01_o_comeco.mp3');
      final b = storage.addFile(root, 'Livro/02.mp3');
      metadata.byUri[a] = const AudioFileMetadata(
        title: 'O começo',
        album: 'Misery',
        artist: 'Narrador',
        albumArtist: 'Stephen King',
        trackNumber: 7,
        duration: Duration(minutes: 3),
      );
      metadata.byUri[b] = const AudioFileMetadata(
        duration: Duration(minutes: 2),
      );

      final book = (await scan(ImportMode.booksInFolders)).single.book;
      expect(book.title, 'Misery');
      expect(book.author, 'Stephen King');
      expect(book.totalDuration, const Duration(minutes: 5));
      expect(book.chapters[0].title, 'O começo');
      expect(book.chapters[0].trackNumber, 7);
      expect(book.chapters[1].title, '02');
      expect(book.chapters[1].trackNumber, 2);
    });

    test('autor cai para artist; título cai para o nome da pasta', () async {
      final a = storage.addFile(root, 'A Guerra/01 - Prólogo.mp3');
      metadata.byUri[a] = const AudioFileMetadata(artist: 'G. R. R. Martin');
      final book = (await scan(ImportMode.booksInFolders)).single.book;
      expect(book.title, 'A Guerra');
      expect(book.author, 'G. R. R. Martin');
      expect(book.chapters.single.title, 'Prólogo');
    });

    test(
      'arquivo com metadado ilegível usa o nome e fica sem duração',
      () async {
        final ok = storage.addFile(root, 'Livro/01.mp3');
        final bad = storage.addFile(root, 'Livro/02_capitulo_dois.mp3');
        metadata.byUri[ok] = const AudioFileMetadata(
          duration: Duration(seconds: 30),
        );
        metadata.broken.add(bad);
        storage.unreadable.add(bad);

        final book = (await scan(ImportMode.booksInFolders)).single.book;
        expect(book.chapters, hasLength(2));
        expect(book.chapters[1].title, 'capitulo dois');
        expect(book.chapters[1].duration, isNull);
        expect(book.totalDuration, const Duration(seconds: 30));
      },
    );

    test('perda de permissão interrompe o escaneamento', () async {
      storage.permissions.clear();
      expect(
        scan(ImportMode.booksInFolders),
        throwsA(isA<StoragePermissionException>()),
      );
    });
  });

  group('prioridade de capa', () {
    test(
      'imagem com nome de capa vence a embutida e a primeira imagem',
      () async {
        final a = storage.addFile(root, 'Livro/01.mp3');
        storage
          ..addFile(root, 'Livro/aaa.png')
          ..addFile(root, 'Livro/Folder.jpg');
        metadata.byUri[a] = AudioFileMetadata(picture: picture([1]));

        final scanned = (await scan(ImportMode.booksInFolders)).single;
        expect((scanned.cover! as FolderImageCover).image.name, 'Folder.jpg');
        expect(metadata.reads.single.$2, isFalse, reason: 'nem pede a capa');
      },
    );

    test('sem imagem preferida, usa a primeira capa embutida', () async {
      final a = storage.addFile(root, 'Livro/01.mp3');
      final b = storage.addFile(root, 'Livro/02.mp3');
      final c = storage.addFile(root, 'Livro/03.mp3');
      storage.addFile(root, 'Livro/foto.png');
      metadata.byUri[b] = AudioFileMetadata(picture: picture([2]));
      metadata.byUri[c] = AudioFileMetadata(picture: picture([3]));

      final scanned = (await scan(ImportMode.booksInFolders)).single;
      expect((scanned.cover! as EmbeddedCover).picture.bytes, [2]);
      expect(metadata.reads, [(a, true), (b, true), (c, false)]);
    });

    test('sem embutida, a primeira imagem da pasta em ordem natural', () async {
      storage
        ..addFile(root, 'Livro/01.mp3')
        ..addFile(root, 'Livro/img10.jpg')
        ..addFile(root, 'Livro/img2.webp');
      final scanned = (await scan(ImportMode.booksInFolders)).single;
      expect((scanned.cover! as FolderImageCover).image.name, 'img2.webp');
    });

    test('sem nenhuma imagem, sem capa', () async {
      storage.addFile(root, 'Livro/01.mp3');
      expect((await scan(ImportMode.booksInFolders)).single.cover, isNull);
    });
  });

  group('arquivos já existentes em outra origem', () {
    test('são ignorados; pasta só com eles não vira livro', () async {
      final dup = storage.addFile(root, 'Velho/01.mp3');
      final a1 = storage.addFile(root, 'Novo/01.mp3');
      final a2 = storage.addFile(root, 'Novo/02.mp3');
      final books = await scan(ImportMode.booksInFolders, skip: {dup, a1});
      expect(books.single.book.id, '$root/Novo');
      expect([for (final c in books.single.book.chapters) c.uri], [a2]);
      expect(metadata.reads.map((r) => r.$1), [a2]);
    });

    test('no modo pasta inteira também', () async {
      final dup = storage.addFile(root, 'a.mp3');
      expect(await scan(ImportMode.oneBook, skip: {dup}), isEmpty);
    });
  });

  group('arquivos soltos', () {
    test('viram um livro com o título do primeiro arquivo', () async {
      final files = [
        storage.looseFile('doc:b/02_segundo.mp3'),
        storage.looseFile('doc:a/01_primeiro.mp3'),
        storage.looseFile('doc:c/leia.txt'),
      ];
      final scanned = (await scanner.scanFiles(
        files,
        sourceId: 'files:1',
      ))!.book;
      expect(scanned.id, 'files:1');
      expect(scanned.title, 'primeiro');
      expect(
        [for (final c in scanned.chapters) c.title],
        ['primeiro', 'segundo'],
      );
    });

    test('nulo se nenhum é áudio novo', () async {
      final f = storage.looseFile('doc:a/01.mp3');
      expect(
        await scanner.scanFiles([f], sourceId: 'files:1', skipUris: {f.uri}),
        isNull,
      );
    });
  });
}
