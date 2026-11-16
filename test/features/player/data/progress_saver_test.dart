import 'package:echoes/core/database/app_database.dart';
import 'package:echoes/features/library/data/library_repository.dart';
import 'package:echoes/features/player/data/progress_repository.dart';
import 'package:echoes/features/player/data/progress_saver.dart';
import 'package:echoes/features/player/domain/player_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/test_database.dart';

/// Repositório que registra as gravações em vez de só gravar.
class RecordingProgressRepository extends ProgressRepository {
  RecordingProgressRepository(super.db, {super.clock});

  final List<String> saves = [];
  final List<String> touches = [];

  @override
  Future<void> saveProgress(String bookId, String chapterId, Duration p) {
    saves.add('$bookId/$chapterId@${p.inSeconds}');
    return super.saveProgress(bookId, chapterId, p);
  }

  @override
  Future<void> touchLastPlayed(String bookId) {
    touches.add(bookId);
    return super.touchLastPlayed(bookId);
  }
}

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late RecordingProgressRepository repo;
  late ProgressSaver saver;

  setUp(() async {
    db = memoryDatabase();
    clock = FakeClock();
    await LibraryRepository(db, clock: clock.call).saveScannedSource(
      folder('tree:a', [
        book('A', [chapter('a1'), chapter('a2')]),
        book('B', [chapter('b1')]),
      ]),
    );
    repo = RecordingProgressRepository(db, clock: clock.call);
    saver = ProgressSaver(repo);
  });

  tearDown(() => db.close());

  /// Atualização do player: livro, capítulo, segundos, tocando.
  void emit(
    String bookId,
    String chapterId,
    int seconds, {
    bool playing = true,
  }) => saver.onSnapshot(
    PlaybackSnapshot(
      bookId: bookId,
      chapterId: chapterId,
      position: Duration(seconds: seconds),
      playing: playing,
    ),
  );

  test('o primeiro estado do livro não grava', () async {
    emit('A', 'a2', 120, playing: false);
    await saver.flush();
    expect(repo.saves, isEmpty);
  });

  test('grava a cada 10 s de posição enquanto toca', () async {
    emit('A', 'a1', 0, playing: false);
    for (var s = 1; s <= 25; s++) {
      emit('A', 'a1', s);
    }
    await saver.flush();
    expect(repo.saves, ['A/a1@10', 'A/a1@20', 'A/a1@25']);
    expect(repo.touches, ['A', 'A', 'A']);
  });

  test('grava ao pausar', () async {
    emit('A', 'a1', 5, playing: false);
    emit('A', 'a1', 6);
    emit('A', 'a1', 7, playing: false);
    await saver.flush();
    expect(repo.saves, ['A/a1@7'], reason: 'flush sem mudança não grava');
  });

  test('mudar de capítulo grava o novo na posição 0', () async {
    emit('A', 'a1', 0);
    emit('A', 'a1', 4);
    emit('A', 'a2', 3);
    await saver.flush();
    expect(repo.saves.first, 'A/a2@0');
    final saved = (await repo.getProgress('A'))!;
    expect(saved.chapterId, 'a2');
  });

  test('flush grava o estado pausado depois de um seek', () async {
    emit('A', 'a1', 30, playing: false);
    emit('A', 'a1', 45, playing: false);
    await saver.flush();
    expect(repo.saves, ['A/a1@45']);
  });

  test(
    'troca de livro: flush grava o anterior e o novo vira referência',
    () async {
      emit('A', 'a1', 0);
      emit('A', 'a1', 7);
      await saver.flush();
      saver.reset();
      emit('B', 'b1', 50, playing: false);
      await saver.flush();
      expect(repo.saves, ['A/a1@7']);
    },
  );

  test('livro removido no meio da reprodução não quebra', () async {
    emit('A', 'a1', 0);
    await LibraryRepository(db).removeSource('tree:a');
    emit('A', 'a1', 12);
    await saver.flush();
    expect(await repo.getProgress('A'), isNull);
  });
}
