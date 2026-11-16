import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../library/presentation/library_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../data/echoes_audio_handler.dart';
import '../data/playback_controller.dart';
import '../data/progress_repository.dart';
import '../data/progress_saver.dart';
import '../domain/player_state.dart';

/// Criado por `AudioService.init` no `main` e injetado com `overrideWithValue`.
final audioHandlerProvider = Provider<EchoesAudioHandler>(
  (ref) => throw UnimplementedError('audioHandlerProvider vem do main'),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(appDatabaseProvider)),
);

final playbackControllerProvider = Provider<PlaybackController>((ref) {
  final progress = ref.watch(progressRepositoryProvider);
  final controller = PlaybackController(
    handler: ref.watch(audioHandlerProvider),
    library: ref.watch(libraryRepositoryProvider),
    progress: progress,
    settings: ref.watch(settingsRepositoryProvider),
    saver: ProgressSaver(progress),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// Livro, capítulo e estado de reprodução.
final playerStateProvider = StreamProvider<PlayerState>(
  (ref) => ref.watch(playbackControllerProvider).state,
);

/// Posição dentro do capítulo atual.
final playerPositionProvider = StreamProvider<Duration>(
  (ref) => ref.watch(playbackControllerProvider).position,
);
