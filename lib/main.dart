import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/strings.dart';
import 'features/import/presentation/import_providers.dart';
import 'features/player/data/echoes_audio_handler.dart';
import 'features/player/domain/skip_rules.dart';
import 'features/player/presentation/player_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fala: pausa em ligações e ao desconectar o fone.
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.speech());

  final handler = await AudioService.init(
    builder: () => EchoesAudioHandler(
      AudioPlayer(),
      const NotificationLabels(
        previous: AppStrings.previousChapter,
        rewind: AppStrings.rewind15,
        play: AppStrings.play,
        pause: AppStrings.pause,
        forward: AppStrings.forward15,
        next: AppStrings.nextChapter,
      ),
    ),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'dev.alexandre.echoes.playback',
      androidNotificationChannelName: AppStrings.notificationChannelName,
      androidNotificationIcon: 'drawable/ic_launcher_monochrome',
      fastForwardInterval: SkipRules.jump,
      rewindInterval: SkipRules.jump,
    ),
  );

  final container = ProviderContainer(
    overrides: [audioHandlerProvider.overrideWithValue(handler)],
  );
  unawaited(_startup(container));
  runApp(
    UncontrolledProviderScope(container: container, child: const EchoesApp()),
  );
}

/// Confere as permissões das origens e reabre o último livro, sem tocar.
Future<void> _startup(ProviderContainer container) async {
  try {
    await container
        .read(importControllerProvider.notifier)
        .refreshAvailability();
  } on Exception catch (e) {
    debugPrint('Falha ao conferir origens: $e');
  }
  try {
    await container.read(playbackControllerProvider).restoreLastBook();
  } on Exception catch (e) {
    debugPrint('Falha ao reabrir o último livro: $e');
  }
}
