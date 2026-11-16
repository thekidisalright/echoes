import 'dart:io';

import 'package:echoes/core/database/app_database.dart';
import 'package:echoes/core/files/cover_store.dart';
import 'package:echoes/core/metadata/metadata_reader.dart';
import 'package:echoes/core/storage/storage_gateway.dart';
import 'package:echoes/features/import/data/import_service.dart';
import 'package:echoes/features/import/data/library_scanner.dart';
import 'package:echoes/features/import/domain/import_mode.dart';
import 'package:echoes/features/import/domain/import_progress.dart';
import 'package:echoes/features/import/domain/import_result.dart';
import 'package:echoes/features/library/data/library_repository.dart';
import 'package:echoes/features/library/domain/library_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_metadata_reader.dart';
import '../../../fakes/fake_storage_gateway.dart';
import '../../../fakes/test_database.dart';

const root = 'tree:raiz';

void main() {
  late AppDatabase db;
  late Directory temp;
  late FakeStorageGateway storage;
  late FakeMetadataReader metadata;
  late LibraryRepository library;
  late ImportService service;

  setUp(() {
    db = memoryDatabase();
    temp = Directory.systemTemp.createTempSync('echoes_import_');
    storage = FakeStorageGateway();
    metadata = FakeMetadataReader();
    library = LibraryRepository(db);
    service = ImportService(
      storage: storage,
      scanner: LibraryScanner(storage, metadata),
      library: library,
      covers: CoverStore(() async => temp),
      filesSourceName: 'Arquivos selecionados',
      fallbackFolderName: 'Pasta de áudio',
      clock: () => DateTime.fromMillisecondsSinceEpoch(1000),
    );
  });

  tearDown(() async {
    await db.close();
    temp.deleteSync(recursive: true);
  });

  List<String> coverFiles() => [
    for (final f in temp.listSync().whereType<File>()) f.path,
  ];

  group('importFolder', () {
    test('salva livros, capas e relata o progresso', () async {
      final a = storage.addFile(root, 'Livro A/01.mp3');
      storage
        ..addFile(root, 'Livro A/cover.jpg', bytes: [7, 7])
        ..addFile(root, 'Livro B/01.mp3');
      metadata.byUri[a] = const AudioFileMetadata(
        duration: Duration(minutes: 1),
      );
      storage.permissions.add(root);

      final progress = <ImportProgress>[];
      final result = await service.importFolder(
        const PickedDirectory(uri: root, name: 'Audiobooks'),
        ImportMode.booksInFolders,
        onProgress: progress.add,
      );

      expect((result as ImportCompleted).bookCount, 2);
      expect(progress.first, isA<ImportPreparing>());
      expect(progress.last, isA<ImportSaving>());

      final bookA = (await library.getBook('$root/Livro A'))!;
      expect(File(bookA.coverPath!).readAsBytesSync(), [7, 7]);
      expect((await library.getBook('$root/Livro B'))!.coverPath, isNull);
      expect(coverFiles(), hasLength(1));

      final source = (await library.getSource(root))!;
      expect(source.name, 'Audiobooks');
      expect(source.importMode, ImportMode.booksInFolders);
    });

    test('capa embutida vira arquivo com extensão do tipo', () async {
      final a = storage.addFile(root, 'Livro/01.m4b');
      metadata.byUri[a] = AudioFileMetadata(
        picture: picture([1, 2, 3], 'image/png'),
      );
      storage.permissions.add(root);
      await service.importFolder(
        const PickedDirectory(uri: root, name: 'x'),
        ImportMode.oneBook,
      );
      final cover = (await library.getBook(root))!.coverPath!;
      expect(cover, endsWith('.png'));
      expect(File(cover).readAsBytesSync(), [1, 2, 3]);
    });

    test('pasta nova sem áudio: nada salvo e permissão liberada', () async {
      storage
        ..addFile(root, 'leia.txt')
        ..permissions.add(root);
      final result = await service.importFolder(
        const PickedDirectory(uri: root, name: 'x'),
        ImportMode.booksInFolders,
      );
      expect(result, isA<ImportNothingNew>());
      expect(await library.getSource(root), isNull);
      expect(storage.released, [root]);
    });

    test('nome vazio usa o nome padrão', () async {
      storage
        ..addFile(root, '01.mp3')
        ..permissions.add(root);
      await service.importFolder(
        const PickedDirectory(uri: root, name: ' '),
        ImportMode.oneBook,
      );
      expect((await library.getSource(root))!.name, 'Pasta de áudio');
    });
  });

  group('importFiles', () {
    test('cancelado', () async {
      expect(await service.importFiles(), isA<ImportCancelled>());
    });

    test('nenhum áudio: libera as permissões dos arquivos', () async {
      storage.nextFiles = [storage.looseFile('doc:leia.txt')];
      expect(await service.importFiles(), isA<ImportNoAudioSelected>());
      expect(storage.released, ['doc:leia.txt']);
    });

    test('cria a origem de arquivos e depois recusa repetidos', () async {
      storage.nextFiles = [
        storage.looseFile('doc:02.mp3'),
        storage.looseFile('doc:01.mp3'),
      ];
      expect(await service.importFiles(), isA<ImportCompleted>());

      final source = (await library.watchSources().first).single;
      expect(source.id, 'files:1000');
      expect(source.kind, SourceKind.files);
      expect(source.name, 'Arquivos selecionados');
      final chapters = await library.chaptersOf('files:1000');
      expect([for (final c in chapters) c.uri], ['doc:01.mp3', 'doc:02.mp3']);

      expect(await service.importFiles(), isA<ImportFilesAlreadyAdded>());
      expect(storage.released, isEmpty);
    });
  });

  group('rescan', () {
    test('aplica mudanças da pasta preservando a origem', () async {
      final keep = storage.addFile(root, 'Livro/01.mp3');
      final gone = storage.addFile(root, 'Livro/02.mp3');
      storage.permissions.add(root);
      await service.importFolder(
        const PickedDirectory(uri: root, name: 'raiz'),
        ImportMode.oneBook,
      );
      storage
        ..removeFile(root, gone)
        ..addFile(root, 'Livro/03.mp3');

      final source = (await library.getSource(root))!;
      expect(await service.rescan(source), isA<ImportCompleted>());
      expect(
        [for (final c in await library.chaptersOf(root)) c.uri],
        [keep, '$root/Livro/03.mp3'],
      );
    });

    test('sem permissão marca indisponível e lança', () async {
      storage
        ..addFile(root, '01.mp3')
        ..permissions.add(root);
      await service.importFolder(
        const PickedDirectory(uri: root, name: 'raiz'),
        ImportMode.oneBook,
      );
      storage.permissions.clear();
      final source = (await library.getSource(root))!;

      await expectLater(
        service.rescan(source),
        throwsA(isA<StoragePermissionException>()),
      );
      expect((await library.getSource(root))!.available, isFalse);
      expect(storage.listTreeCalls, 1, reason: 'nem tenta listar');
    });
  });

  test('remove libera permissões e apaga capas', () async {
    storage
      ..addFile(root, 'Livro/01.mp3')
      ..addFile(root, 'Livro/cover.png')
      ..permissions.add(root);
    await service.importFolder(
      const PickedDirectory(uri: root, name: 'raiz'),
      ImportMode.booksInFolders,
    );
    storage.nextFiles = [storage.looseFile('doc:a.mp3')];
    await service.importFiles();
    expect(coverFiles(), hasLength(1));

    for (final source in await library.watchSources().first) {
      await service.remove(source);
    }
    expect(await library.watchSources().first, isEmpty);
    expect(storage.released, unorderedEquals([root, 'doc:a.mp3']));
    expect(coverFiles(), isEmpty);
  });

  test('refreshAvailability compara com as permissões persistidas', () async {
    storage
      ..addFile(root, '01.mp3')
      ..permissions.add(root);
    await service.importFolder(
      const PickedDirectory(uri: root, name: 'raiz'),
      ImportMode.oneBook,
    );
    storage.nextFiles = [storage.looseFile('doc:a.mp3')];
    await service.importFiles();

    storage.permissions.remove(root);
    await service.refreshAvailability();
    var sources = {
      for (final s in await library.watchSources().first) s.id: s.available,
    };
    expect(sources, {root: false, 'files:1000': true});

    storage.permissions
      ..add(root)
      ..remove('doc:a.mp3');
    await service.refreshAvailability();
    sources = {
      for (final s in await library.watchSources().first) s.id: s.available,
    };
    expect(sources, {root: true, 'files:1000': false});
  });
}
