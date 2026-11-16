import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/strings.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/utils/duration_format.dart';
import '../data/playback_controller.dart';
import 'player_providers.dart';

/// Player em tela cheia.
///
/// PROVISÓRIO (Fase 4): textos e controles mínimos para validar o motor de
/// áudio no aparelho. O layout definitivo vem na Fase 5.4.
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerStateProvider).value;
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    // Lido só ao tocar num botão: o build não depende do motor de áudio.
    PlaybackController controller() => ref.read(playbackControllerProvider);
    final hasBook = state?.hasBook ?? false;
    final duration = state?.duration;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.closePlayer,
          icon: const Icon(Ionicons.chevronDown),
          onPressed: () => context.pop(),
        ),
        title: Text(
          (state?.book?.author.isNotEmpty ?? false)
              ? state!.book!.author
              : AppStrings.audiobookFallback,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state?.book?.title ?? AppStrings.untitled,
              style: AppTypography.screenTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            if (hasBook) ...[
              Text(state!.chapter!.title, textAlign: TextAlign.center),
              Text(
                AppStrings.chapterOf(
                  state.chapterIndex + 1,
                  state.chapters.length,
                ),
                style: AppTypography.caption,
              ),
              Text(
                duration == null
                    ? formatClock(position)
                    : '${formatClock(position)}  ${formatRemaining(position, duration)}',
                style: AppTypography.caption,
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: AppStrings.previousChapter,
                  icon: const Icon(Ionicons.playSkipBack),
                  onPressed: hasBook
                      ? () => controller().previousChapter()
                      : null,
                ),
                IconButton(
                  tooltip: AppStrings.rewind15,
                  icon: const Icon(Ionicons.playBack),
                  onPressed: hasBook ? () => controller().rewind() : null,
                ),
                IconButton(
                  tooltip: (state?.playing ?? false)
                      ? AppStrings.pause
                      : AppStrings.play,
                  iconSize: 56,
                  icon: Icon(
                    (state?.playing ?? false)
                        ? Ionicons.pauseCircle
                        : Ionicons.playCircle,
                  ),
                  onPressed: hasBook ? () => controller().togglePlay() : null,
                ),
                IconButton(
                  tooltip: AppStrings.forward15,
                  icon: const Icon(Ionicons.playForward),
                  onPressed: hasBook ? () => controller().fastForward() : null,
                ),
                IconButton(
                  tooltip: AppStrings.nextChapter,
                  icon: const Icon(Ionicons.playSkipForward),
                  onPressed: hasBook && !state!.isLastChapter
                      ? () => controller().nextChapter()
                      : null,
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.chapters),
              icon: const Icon(Ionicons.listOutline),
              label: const Text(AppStrings.chapters),
            ),
          ],
        ),
      ),
    );
  }
}
