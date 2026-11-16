import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/strings.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../bookmarks/presentation/bookmark_providers.dart';
import '../../library/presentation/widgets/book_cover.dart';
import '../data/playback_controller.dart';
import '../domain/player_state.dart';
import 'player_providers.dart';
import 'widgets/player_controls.dart';
import 'widgets/seek_bar.dart';

/// Player em tela cheia. Fecha pelo chevron ou arrastando para baixo.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  /// Arrasto mínimo para fechar.
  static const dismissDistance = 120.0;

  /// Velocidade (px/s) que fecha mesmo com arrasto curto.
  static const dismissVelocity = 900.0;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  // Capa: min(largura − 64, 45% da altura), no máximo 480.
  static const _coverMargin = 64.0;
  static const _coverHeightFraction = 0.45;
  static const _coverMax = 480.0;

  /// Deslocamento vertical do arrasto, em pixels.
  late final _drag = AnimationController.unbounded(vsync: this);

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _drag.value = math.max(0, _drag.value + details.delta.dy);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_drag.value > PlayerScreen.dismissDistance ||
        velocity > PlayerScreen.dismissVelocity) {
      // A transição de saída desliza a partir de onde o dedo soltou.
      context.pop();
    } else {
      unawaited(
        _drag.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerStateProvider).value ?? PlayerState.empty;
    final book = state.book;
    final size = MediaQuery.sizeOf(context);
    final coverSize = [
      size.width - _coverMargin,
      size.height * _coverHeightFraction,
      _coverMax,
    ].reduce(math.min);
    // Lido só nos callbacks: o build não depende do motor de áudio.
    PlaybackController controller() => ref.read(playbackControllerProvider);

    return AnimatedBuilder(
      animation: _drag,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, _drag.value), child: child),
      child: GestureDetector(
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: AppStrings.closePlayer,
                        icon: const Icon(
                          Ionicons.chevronDown,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          (book?.author.isNotEmpty ?? false)
                              ? book!.author
                              : AppStrings.audiobookFallback,
                          style: AppTypography.bodySmall,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(
                        width: AppSpacing.minTouch + AppSpacing.xs,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox.square(
                    dimension: coverSize,
                    child: BookCover(
                      path: book?.coverPath,
                      placeholderIcon: Ionicons.bookOutline,
                      iconSize: coverSize / 4,
                      radius: AppRadii.cover,
                      background: AppColors.coverPlaceholder,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    (book?.title.isNotEmpty ?? false)
                        ? book!.title
                        : AppStrings.untitled,
                    style: AppTypography.screenTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (state.hasBook) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      state.chapter!.title,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppStrings.chapterOf(
                        state.chapterIndex + 1,
                        state.chapters.length,
                      ),
                      style: AppTypography.caption,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _ChapterSeekBar(
                    duration: state.duration,
                    onSeek: (p) => controller().seek(p),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PlayerControls(
                    playing: state.playing,
                    enabled: state.hasBook,
                    hasNext: !state.isLastChapter,
                    onPrevious: () => controller().previousChapter(),
                    onRewind: () => controller().rewind(),
                    onTogglePlay: () => controller().togglePlay(),
                    onForward: () => controller().fastForward(),
                    onNext: () => controller().nextChapter(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _BookmarkButton(enabled: state.hasBook),
                      _ActionButton(
                        icon: Ionicons.listOutline,
                        label: AppStrings.chapters,
                        onPressed: state.hasBook
                            ? () => context.push(AppRoutes.chapters)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// SeekBar que reconstrói sozinha a cada posição.
class _ChapterSeekBar extends ConsumerWidget {
  const _ChapterSeekBar({required this.duration, required this.onSeek});

  final Duration? duration;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playerPositionProvider).value ?? Duration.zero;
    return SeekBar(position: position, duration: duration, onSeek: onSeek);
  }
}

/// Cria um marcador na posição atual e mostra "Salvo" por 1,5 s.
class _BookmarkButton extends ConsumerStatefulWidget {
  const _BookmarkButton({required this.enabled});

  final bool enabled;

  @override
  ConsumerState<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends ConsumerState<_BookmarkButton> {
  static const _feedback = Duration(milliseconds: 1500);

  Timer? _savedTimer;

  @override
  void dispose() {
    _savedTimer?.cancel();
    super.dispose();
  }

  Future<void> _add() async {
    final controller = ref.read(playbackControllerProvider);
    final state = controller.currentState;
    final book = state.book;
    final chapter = state.chapter;
    if (book == null || chapter == null) return;
    await ref
        .read(bookmarkRepositoryProvider)
        .add(book.id, chapter.id, controller.currentPosition);
    if (!mounted) return;
    _savedTimer?.cancel();
    setState(() => _savedTimer = Timer(_feedback, _clear));
  }

  void _clear() {
    if (mounted) setState(() => _savedTimer = null);
  }

  @override
  Widget build(BuildContext context) {
    final saved = _savedTimer != null;
    return _ActionButton(
      icon: saved ? Ionicons.bookmark : Ionicons.bookmarkOutline,
      label: saved ? AppStrings.bookmarkSaved : AppStrings.bookmark,
      highlighted: saved,
      onPressed: widget.enabled ? _add : null,
    );
  }
}

/// Botão da linha de ações: ícone com rótulo abaixo.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null
        ? AppColors.textMuted
        : highlighted
        ? AppColors.accent
        : AppColors.textSecondary;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.field),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSpacing.minTouch * 2,
            minHeight: AppSpacing.minTouch,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppSpacing.listIcon, color: color),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
