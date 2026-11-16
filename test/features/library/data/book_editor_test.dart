import 'dart:io';

import 'package:echoes/core/database/app_database.dart';
import 'package:echoes/core/files/cover_store.dart';
import 'package:echoes/features/library/data/book_editor.dart';
import 'package:echoes/features/library/data/library_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/test_database.dart';

void main() {
  late AppDatabase db;
  late LibraryRepository library;
  late Directory temp;
  late CoverStore covers;
  late BookEditor editor;
  late FakeClock clock;

  setUp(() async {
    db = memoryDatabase();
    library = LibraryRepository(db);
    temp = Directory.systemTemp.createTempSync('echoes_editor_');
    clock = FakeClock();
    covers = CoverStore(
      () async => Directory('${temp.path}${Platform.pathSeparator}covers'),
      clock: clock.call,
    );
    editor = BookEditor(library: library, covers: covers);
    await library.saveScannedSource(
      folder('f', [
        book('b', [chapter('c1')], title: 'Original', author: 'Autor'),
      ]),
    );
  });

  tearDown(() async {
    await db.close();
    temp.deleteSync(recursive: true);
  });

  String image(String name) {
    final file = File('${temp.path}${Platform.pathSeparator}$name')
      ..writeAsBytesSync([1, 2, 3]);
    return file.path;
  }

  test('salva título e autor sem mexer na capa', () async {
    await editor.save('b', title: ' Novo ', author: 'Outra');
    final saved = (await library.getBook('b'))!;
    expect(saved.title, 'Novo');
    expect(saved.author, 'Outra');
    expect(saved.customCoverPath, isNull);
  });

  test('capa nova substitui a anterior e apaga o arquivo antigo', () async {
    await editor.save('b', title: 'T', author: '', imagePath: image('a.png'));
    final first = (await library.getBook('b'))!.customCoverPath!;
    expect(File(first).existsSync(), isTrue);

    clock.tick();
    await editor.save('b', title: 'T', author: '', imagePath: image('b.jpg'));
    final second = (await library.getBook('b'))!.customCoverPath!;
    expect(second, isNot(first));
    expect(File(second).existsSync(), isTrue);
    expect(File(first).existsSync(), isFalse);
  });

  test('restaurar volta aos dados originais e apaga a capa', () async {
    await editor.save('b', title: 'T', author: 'X', imagePath: image('a.png'));
    final custom = (await library.getBook('b'))!.customCoverPath!;

    await editor.reset('b');
    final restored = (await library.getBook('b'))!;
    expect(restored.title, 'Original');
    expect(restored.author, 'Autor');
    expect(restored.hasCustomDetails, isFalse);
    expect(File(custom).existsSync(), isFalse);
  });

  test('título vazio é recusado', () {
    expect(
      () => editor.save('b', title: '  ', author: ''),
      throwsArgumentError,
    );
  });
}
