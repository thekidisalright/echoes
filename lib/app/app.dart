import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../features/import/presentation/import_providers.dart';
import '../features/player/presentation/player_providers.dart';
import 'router.dart';
import 'strings.dart';
import 'theme/theme.dart';

class EchoesApp extends ConsumerStatefulWidget {
  const EchoesApp({super.key});

  @override
  ConsumerState<EchoesApp> createState() => _EchoesAppState();
}

class _EchoesAppState extends ConsumerState<EchoesApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      // Indo para segundo plano ou sendo encerrado: salva o progresso.
      onPause: _saveProgress,
      onDetach: _saveProgress,
      // De volta: a permissão de alguma pasta pode ter sido revogada.
      onResume: () => unawaited(
        ref.read(importControllerProvider.notifier).refreshAvailability(),
      ),
    );
  }

  void _saveProgress() =>
      unawaited(ref.read(playbackControllerProvider).saveNow());

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
