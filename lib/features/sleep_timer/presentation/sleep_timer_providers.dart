import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/presentation/player_providers.dart';
import '../data/sleep_timer_service.dart';
import '../domain/sleep_timer_state.dart';

/// Vive enquanto o app vive: o timer continua com o Player fechado.
final sleepTimerServiceProvider = Provider<SleepTimerService>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  final service = SleepTimerService(
    player: controller.state,
    pause: controller.pause,
  );
  ref.onDispose(service.dispose);
  return service;
});

final sleepTimerStateProvider = StreamProvider<SleepTimerState>(
  (ref) => ref.watch(sleepTimerServiceProvider).state,
);
