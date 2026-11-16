import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../player/domain/player_state.dart';
import '../domain/sleep_timer_state.dart';

/// Cria um timer de uma vez (injetável nos testes).
typedef TimerFactory = Timer Function(Duration delay, void Function() onFire);

/// Timer de sono: pausa depois de alguns minutos ou ao fim do capítulo.
///
/// Pausar manualmente não cancela o timer; ele só zera ao disparar, ao ser
/// cancelado ou quando o livro é fechado.
class SleepTimerService {
  SleepTimerService({
    required Stream<PlayerState> player,
    required this._pause,
    DateTime Function()? clock,
    TimerFactory? createTimer,
  }) : _clock = clock ?? DateTime.now,
       _createTimer = createTimer ?? Timer.new {
    _player = player.listen(_onPlayer);
  }

  final Future<void> Function() _pause;
  final DateTime Function() _clock;
  final TimerFactory _createTimer;
  late final StreamSubscription<PlayerState> _player;

  final _state = BehaviorSubject<SleepTimerState>.seeded(const SleepTimerOff());
  PlayerState _last = PlayerState.empty;

  /// Horário em que o timer por minutos dispara.
  DateTime? _deadline;

  /// Próximo despertar: troca do minuto exibido ou o próprio disparo.
  Timer? _wake;

  Stream<SleepTimerState> get state => _state;
  SleepTimerState get current => _state.value;

  /// Pausa daqui a [duration].
  void startCountdown(Duration duration) {
    _clear();
    _deadline = _clock().add(duration);
    _tick();
  }

  /// Pausa quando o capítulo atual terminar. Ignorado sem livro carregado.
  void startEndOfChapter() {
    final book = _last.book;
    if (book == null) return;
    _clear();
    _state.add(
      SleepTimerEndOfChapter(bookId: book.id, chapterIndex: _last.chapterIndex),
    );
  }

  void cancel() {
    _clear();
    _state.add(const SleepTimerOff());
  }

  Future<void> dispose() async {
    _wake?.cancel();
    await _player.cancel();
    await _state.close();
  }

  void _tick() {
    final deadline = _deadline;
    if (deadline == null) return;
    final remaining = deadline.difference(_clock());
    if (remaining <= Duration.zero) {
      _fire();
      return;
    }
    final countdown = SleepTimerCountdown(remaining);
    _state.add(countdown);
    // Acorda quando o minuto exibido mudar (ou no disparo, no último minuto).
    final shownAfter = Duration(minutes: countdown.minutesLeft - 1);
    _wake = _createTimer(remaining - shownAfter, _tick);
  }

  void _onPlayer(PlayerState player) {
    _last = player;
    final timer = current;
    if (timer is SleepTimerOff) return;
    final book = player.book;
    if (book == null) {
      cancel();
      return;
    }
    if (timer is! SleepTimerEndOfChapter) return;
    if (book.id != timer.bookId) {
      cancel();
    } else if (player.chapterIndex != timer.chapterIndex) {
      // O capítulo terminou e o seguinte começou (ou o usuário trocou).
      _fire();
    } else if (player.completed) {
      // Último capítulo: o player já parou sozinho.
      cancel();
    }
  }

  void _fire() {
    cancel();
    unawaited(_pause());
  }

  void _clear() {
    _wake?.cancel();
    _wake = null;
    _deadline = null;
  }
}
