import 'dart:io';
import 'dart:typed_data';

import 'package:echoes/core/files/cover_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/test_database.dart';

void main() {
  late Directory temp;
  late Directory covers;
  late FakeClock clock;
  late CoverStore store;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('echoes_covers_');
    covers = Directory('${temp.path}${Platform.pathSeparator}covers');
    clock = FakeClock();
    store = CoverStore(() async => covers, clock: clock.call);
  });

  tearDown(() => temp.deleteSync(recursive: true));

  List<String> names() => [
    for (final f in covers.listSync().whereType<File>())
      f.uri.pathSegments.last,
  ]..sort();

  test('capa escaneada usa sha1 do id e troca a extensão antiga', () async {
    final jpg = await store.saveScanned(
      'content://livro',
      Uint8List.fromList([1, 2]),
      '.JPEG',
    );
    expect(jpg, endsWith('.jpg'));
    expect(File(jpg).readAsBytesSync(), [1, 2]);

    final png = await store.saveScanned(
      'content://livro',
      Uint8List.fromList([3]),
      'png',
    );
    expect(names(), [png.split(Platform.pathSeparator).last]);

    final again = await store.saveScanned(
      'content://livro',
      Uint8List.fromList([4]),
      'png',
    );
    expect(again, png);
    expect(File(png).readAsBytesSync(), [4]);
  });

  test('capa do usuário ganha timestamp e apaga a anterior', () async {
    final source = File('${temp.path}${Platform.pathSeparator}foto.webp')
      ..writeAsBytesSync([9]);
    final first = await store.saveCustom('livro', source.path);
    clock.tick();
    final second = await store.saveCustom('livro', source.path);

    expect(first, isNot(second));
    expect(second, contains('custom_'));
    expect(second, endsWith('.webp'));
    expect(File(first).existsSync(), isFalse);
    expect(File(second).readAsBytesSync(), [9]);

    await store.removeCustom('livro');
    expect(names(), isEmpty);
  });

  test('deleteOrphans apaga só o que não está em uso', () async {
    final keep = await store.saveScanned('a', Uint8List(1), 'jpg');
    await store.saveScanned('b', Uint8List(1), 'jpg');
    await store.saveScanned('c', Uint8List(1), 'png');

    expect(await store.deleteOrphans({keep}), 2);
    expect(names(), [keep.split(Platform.pathSeparator).last]);
  });
}
