import 'package:echoes/core/database/app_database.dart';
import 'package:echoes/features/library/data/library_repository.dart';
import 'package:echoes/features/player/data/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late LibraryRepository library;
  late ProgressRepository progress;

  setUp(() async {
    db = memoryDatabase();
    clock = FakeClock();
    library = LibraryRepository(db, clock: clock.call);
    progress = ProgressRepository(db, clock: clock.call);
    await library.saveScannedSource(
      folder('tree:a', [
        book('dir:1', [chapter('f:1'), chapter('f:2')]),
      ]),
    );
  });

  tearDown(() => db.close());

  test('sem progresso salvo devolve nulo', () async {
    expect(await progress.getProgress('dir:1'), isNull);
  });

  test('salvar de novo sobrescreve a linha do livro', () async {
    await progress.saveProgress('dir:1', 'f:1', const Duration(seconds: 10));
    clock.tick();
    await progress.saveProgress('dir:1', 'f:2', const Duration(seconds: 20));
    final p = (await progress.getProgress('dir:1'))!;
    expect(p.chapterId, 'f:2');
    expect(p.position, const Duration(seconds: 20));
    expect(p.updatedAt, clock.now);
    expect(await db.select(db.progressEntries).get(), hasLength(1));
  });

  test('livro inexistente é ignorado em vez de falhar', () async {
    await progress.saveProgress('sumiu', 'x', Duration.zero);
    expect(await progress.getProgress('sumiu'), isNull);
  });

  test('touchLastPlayed grava o horário atual', () async {
    clock.tick(const Duration(hours: 1));
    await progress.touchLastPlayed('dir:1');
    expect((await library.getBook('dir:1'))!.lastPlayedAt, clock.now);
  });
}
