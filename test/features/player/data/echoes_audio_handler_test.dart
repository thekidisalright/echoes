import 'dart:async';

import 'package:echoes/features/player/data/echoes_audio_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

/// Imita o just_audio: o `Future` de `play()` só termina quando a
/// reprodução para.
class _PlayingForeverPlayer extends Fake implements AudioPlayer {
  int playCalls = 0;

  @override
  Future<void> play() {
    playCalls++;
    return Completer<void>().future;
  }

  @override
  Stream<PlaybackEvent> get playbackEventStream => const Stream.empty();
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<ProcessingState> get processingStateStream => const Stream.empty();
}

const _labels = NotificationLabels(
  previous: 'p',
  rewind: 'r',
  play: 'pl',
  pause: 'pa',
  forward: 'f',
  next: 'n',
);

void main() {
  test('play() retorna sem esperar a reprodução terminar', () async {
    final player = _PlayingForeverPlayer();
    final handler = EchoesAudioHandler(player, _labels);

    await handler.play().timeout(const Duration(seconds: 1));

    expect(player.playCalls, 1);
  });
}
