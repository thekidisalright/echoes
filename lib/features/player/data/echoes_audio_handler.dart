import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/skip_rules.dart';

/// Rótulos das ações da notificação (acessibilidade). Vêm de fora para o
/// handler não depender dos textos de UI.
class NotificationLabels {
  const NotificationLabels({
    required this.previous,
    required this.rewind,
    required this.play,
    required this.pause,
    required this.forward,
    required this.next,
  });

  final String previous;
  final String rewind;
  final String play;
  final String pause;
  final String forward;
  final String next;
}

/// Ponte entre o just_audio e o audio_service: fila de capítulos,
/// notificação, tela de bloqueio e botões de mídia.
class EchoesAudioHandler extends BaseAudioHandler with SeekHandler {
  EchoesAudioHandler(this._player, this._labels) {
    _subscriptions
      ..add(_player.playbackEventStream.listen(_publishState))
      ..add(_player.playingStream.listen((_) => _publishState()))
      ..add(_player.currentIndexStream.listen(_publishMediaItem))
      ..add(_player.durationStream.listen(_publishDuration))
      ..add(_player.processingStateStream.listen(_onProcessingState));
  }

  final AudioPlayer _player;
  final NotificationLabels _labels;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// Chamado antes de parar o serviço (para salvar o progresso).
  Future<void> Function()? onBeforeStop;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;

  Duration get position => _player.position;
  int get currentIndex => _player.currentIndex ?? 0;
  bool get playing => _player.playing;

  /// Carrega os capítulos já no [index] e na [position] iniciais, sem tocar.
  Future<void> load(
    List<MediaItem> items, {
    required int index,
    required Duration position,
  }) async {
    await _player.pause();
    queue.add(items);
    if (items.isEmpty) {
      mediaItem.add(null);
      await _player.stop();
      return;
    }
    await _player.setAudioSources(
      [for (final item in items) AudioSource.uri(Uri.parse(item.id))],
      initialIndex: index,
      initialPosition: position,
    );
    _publishMediaItem(index);
  }

  /// Troca os textos e a capa da fila sem recarregar o áudio (o livro foi
  /// editado). Ignorado se a fila mudou de tamanho.
  void updateItems(List<MediaItem> items) {
    if (items.length != queue.value.length) return;
    queue.add(items);
    _publishMediaItem(_player.currentIndex);
  }

  /// Descarrega o livro e esconde a notificação.
  Future<void> unload() async {
    await _player.stop();
    queue.add(const []);
    mediaItem.add(null);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) =>
      seekInChapter(index, Duration.zero);

  /// Vai para [position] dentro do capítulo [index] (marcadores).
  Future<void> seekInChapter(int index, Duration position) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(position, index: index);
  }

  @override
  Future<void> skipToNext() async {
    final next = SkipRules.nextChapter(currentIndex, queue.value.length);
    if (next != null) await skipToQueueItem(next);
  }

  @override
  Future<void> skipToPrevious() => skipToQueueItem(
    SkipRules.previousChapter(currentIndex, _player.position),
  );

  @override
  Future<void> rewind() => _player.seek(SkipRules.rewind(_player.position));

  @override
  Future<void> fastForward() =>
      _player.seek(SkipRules.fastForward(_player.position, _player.duration));

  @override
  Future<void> stop() async {
    await onBeforeStop?.call();
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    // Fechado pelo multitarefa: salva e encerra se não estiver tocando.
    await onBeforeStop?.call();
    if (!_player.playing) await stop();
  }

  /// Fim do último capítulo: pausa e mantém o livro carregado no fim.
  void _onProcessingState(ProcessingState state) {
    if (state == ProcessingState.completed && _player.playing) {
      unawaited(_player.pause());
    }
  }

  void _publishMediaItem(int? index) {
    final items = queue.value;
    if (index == null || index < 0 || index >= items.length) return;
    final duration = _player.duration;
    final item = items[index];
    mediaItem.add(
      duration != null && item.duration == null
          ? item.copyWith(duration: duration)
          : item,
    );
  }

  void _publishDuration(Duration? duration) {
    final item = mediaItem.value;
    if (duration == null || item == null || item.duration == duration) return;
    mediaItem.add(item.copyWith(duration: duration));
  }

  void _publishState([PlaybackEvent? _]) {
    final playing = _player.playing;
    final index = _player.currentIndex;
    final count = queue.value.length;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious.copyWith(label: _labels.previous),
          MediaControl.rewind.copyWith(label: _labels.rewind),
          if (playing)
            MediaControl.pause.copyWith(label: _labels.pause)
          else
            MediaControl.play.copyWith(label: _labels.play),
          MediaControl.fastForward.copyWith(label: _labels.forward),
          MediaControl.skipToNext.copyWith(label: _labels.next),
        ],
        androidCompactActionIndices: const [1, 2, 3],
        systemActions: {
          MediaAction.seek,
          MediaAction.rewind,
          MediaAction.fastForward,
          if (index != null && index > 0) MediaAction.skipToPrevious,
          if (index != null && index + 1 < count) MediaAction.skipToNext,
        },
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: index,
      ),
    );
  }

  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _player.dispose();
  }
}
