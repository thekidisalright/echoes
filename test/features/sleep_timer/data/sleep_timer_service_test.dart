import 'dart:async';

import 'package:echoes/features/library/domain/book.dart';
import 'package:echoes/features/library/domain/chapter.dart';
import 'package:echoes/features/player/domain/player_state.dart';
import 'package:echoes/features/sleep_timer/data/sleep_timer_service.dart';
import 'package:echoes/features/sleep_timer/domain/sleep_timer_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Relógio e timers controlados à mão.
class _FakeTime {
  DateTime now = DateTime(2026);
  final List<_FakeTimer> timers = [];

  Timer create(Duration delay, void Function() onFire) {
    final timer = _FakeTimer(now.add(delay), onFire);
    timers.add(timer);
    return timer;
  }

  /// Avança o relógio disparando os timers que vencerem, em ordem.
  void advance(Duration by) {
    final end = now.add(by);
    while (true) {
      final due = timers.where((t) => t.isActive && !t.at.isAfter(end)).toList()
        ..sort((a, b) => a.at.compareTo(b.at));
      if (due.isEmpty) break;
      final next = due.first;
      now = next.at;
      next.fire();
    }
    now = end;
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this.at, this._onFire);

  final DateTime at;
  final void Function() _onFire;
  bool _active = true;

  void fire() {
    _active = false;
    _onFire();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

void main() {
  final book = Book(
    id: 'b',
    sourceId: 's',
    scannedTitle: 'Misery',
    scannedAuthor: '',
    chapterCount: 3,
    createdAt: DateTime(2026),
  );
  const chapters = [
    Chapter(id: 'c1', bookId: 'b', title: '1', uri: 'u1', sortOrder: 0),
    Chapter(id: 'c2', bookId: 'b', title: '2', uri: 'u2', sortOrder: 1),
    Chapter(id: 'c3', bookId: 'b', title: '3', uri: 'u3', sortOrder: 2),
  ];
  PlayerState at(int index, {bool completed = false, Book? other}) =>
      PlayerState(
        book: other ?? book,
        chapters: chapters,
        chapterIndex: index,
        completed: completed,
      );

  late _FakeTime time;
  late StreamController<PlayerState> player;
  late int pauses;
  late SleepTimerService service;

  setUp(() async {
    time = _FakeTime();
    player = StreamController<PlayerState>();
    pauses = 0;
    service = SleepTimerService(
      player: player.stream,
      pause: () async => pauses++,
      clock: () => time.now,
      createTimer: time.create,
    );
    player.add(at(0));
    await pumpEventQueue();
  });

  tearDown(() async {
    await service.dispose();
    await player.close();
  });

  Future<void> emit(PlayerState state) async {
    player.add(state);
    await pumpEventQueue();
  }

  group('por minutos', () {
    test('mostra os minutos restantes arredondados para cima', () {
      service.startCountdown(const Duration(minutes: 15));
      expect((service.current as SleepTimerCountdown).minutesLeft, 15);

      time.advance(const Duration(seconds: 30));
      expect((service.current as SleepTimerCountdown).minutesLeft, 15);

      time.advance(const Duration(seconds: 31));
      expect((service.current as SleepTimerCountdown).minutesLeft, 14);

      time.advance(const Duration(minutes: 13, seconds: 58));
      expect((service.current as SleepTimerCountdown).minutesLeft, 1);
      expect(pauses, 0);
    });

    test('pausa e desliga ao acabar o tempo', () {
      service.startCountdown(const Duration(minutes: 15));
      time.advance(const Duration(minutes: 15));
      expect(pauses, 1);
      expect(service.current, isA<SleepTimerOff>());
      expect(time.timers.where((t) => t.isActive), isEmpty);
    });

    test(
      'pausar manualmente não cancela; trocar de capítulo também não',
      () async {
        service.startCountdown(const Duration(minutes: 15));
        await emit(at(1));
        expect(service.current, isA<SleepTimerCountdown>());
        time.advance(const Duration(minutes: 15));
        expect(pauses, 1);
      },
    );

    test('cancelar não pausa', () {
      service.startCountdown(const Duration(minutes: 15));
      service.cancel();
      time.advance(const Duration(minutes: 30));
      expect(pauses, 0);
      expect(service.current, isA<SleepTimerOff>());
    });

    test('um timer novo substitui o anterior', () {
      service.startCountdown(const Duration(minutes: 15));
      service.startCountdown(const Duration(minutes: 30));
      time.advance(const Duration(minutes: 20));
      expect(pauses, 0);
      expect((service.current as SleepTimerCountdown).minutesLeft, 10);
    });
  });

  group('fim do capítulo', () {
    test('pausa quando o capítulo seguinte começa', () async {
      service.startEndOfChapter();
      expect(
        service.current,
        const SleepTimerEndOfChapter(bookId: 'b', chapterIndex: 0),
      );
      await emit(at(0));
      expect(pauses, 0);

      await emit(at(1));
      expect(pauses, 1);
      expect(service.current, isA<SleepTimerOff>());
    });

    test('no último capítulo, desliga quando o livro termina', () async {
      await emit(at(2));
      service.startEndOfChapter();
      await emit(at(2, completed: true));
      expect(service.current, isA<SleepTimerOff>());
    });

    test('abrir outro livro cancela sem pausar', () async {
      service.startEndOfChapter();
      final other = Book(
        id: 'x',
        sourceId: 's',
        scannedTitle: 'Carrie',
        scannedAuthor: '',
        chapterCount: 3,
        createdAt: DateTime(2026),
      );
      await emit(at(1, other: other));
      expect(pauses, 0);
      expect(service.current, isA<SleepTimerOff>());
    });

    test('sem livro carregado não liga', () async {
      await emit(PlayerState.empty);
      service.startEndOfChapter();
      expect(service.current, isA<SleepTimerOff>());
    });
  });

  test('fechar o livro cancela o timer por minutos', () async {
    service.startCountdown(const Duration(minutes: 15));
    await emit(PlayerState.empty);
    expect(service.current, isA<SleepTimerOff>());
    time.advance(const Duration(minutes: 15));
    expect(pauses, 0);
  });
}
