import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router.dart';
import '../../../../app/strings.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../library/presentation/widgets/book_cover.dart';
import '../player_providers.dart';

/// Player compacto no rodapé da biblioteca. Some quando não há livro.
///
/// Toque no corpo abre o Player; o botão só alterna tocar/pausar.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  static const coverSize = 56.0;
  static const playIconSize = 48.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerStateProvider).value;
    if (state == null || !state.hasBook) return const SizedBox.shrink();
    final book = state.book!;
    final playing = state.playing;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.miniPlayerBg,
        borderRadius: BorderRadius.circular(AppRadii.miniPlayer),
        border: Border.all(color: AppColors.miniPlayerBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppSpacing.xl,
            offset: Offset(0, AppSpacing.sm),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.miniPlayer),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                button: true,
                label: AppStrings.openPlayer,
                child: InkWell(
                  onTap: () => context.push(AppRoutes.player),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      children: [
                        SizedBox.square(
                          dimension: coverSize,
                          child: BookCover(
                            path: book.coverPath,
                            placeholderIcon: Ionicons.imageOutline,
                            iconSize: AppSpacing.xl,
                            radius: AppRadii.coverSmall,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title.isEmpty
                                    ? AppStrings.untitled
                                    : book.title,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                state.chapter?.title ?? '',
                                style: AppTypography.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: playing ? AppStrings.pause : AppStrings.play,
                          iconSize: playIconSize,
                          padding: EdgeInsets.zero,
                          color: AppColors.iconOnDark,
                          icon: Icon(
                            playing
                                ? Ionicons.pauseCircle
                                : Ionicons.playCircle,
                          ),
                          onPressed: () =>
                              ref.read(playbackControllerProvider).togglePlay(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _ChapterProgress(duration: state.duration),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra fina com o progresso do capítulo. Isolada para que só ela
/// reconstrua a cada atualização de posição.
class _ChapterProgress extends ConsumerWidget {
  const _ChapterProgress({required this.duration});

  final Duration? duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = duration?.inMilliseconds ?? 0;
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    final value = total > 0
        ? (position.inMilliseconds / total).clamp(0.0, 1.0)
        : 0.0;
    return LinearProgressIndicator(
      value: value,
      minHeight: AppSpacing.miniProgressBar,
      backgroundColor: AppColors.track,
    );
  }
}
