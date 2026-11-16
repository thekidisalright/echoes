import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';

/// Capítulo anterior · voltar 15 s · tocar/pausar · avançar 15 s · próximo.
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    required this.playing,
    required this.enabled,
    required this.hasNext,
    required this.onPrevious,
    required this.onRewind,
    required this.onTogglePlay,
    required this.onForward,
    required this.onNext,
    super.key,
  });

  static const playIconSize = 72.0;
  static const skipIconSize = 30.0;

  final bool playing;

  /// Há livro carregado.
  final bool enabled;

  /// Falso no último capítulo (próximo desabilitado).
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onRewind;
  final VoidCallback onTogglePlay;
  final VoidCallback onForward;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    Widget button(
      String tooltip,
      IconData icon,
      VoidCallback? onPressed, {
      double size = skipIconSize,
    }) => IconButton(
      tooltip: tooltip,
      iconSize: size,
      color: AppColors.iconOnDark,
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minTouch,
        minHeight: AppSpacing.minTouch,
      ),
      icon: Icon(icon),
      onPressed: onPressed,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        button(
          AppStrings.previousChapter,
          Ionicons.playSkipBack,
          enabled ? onPrevious : null,
        ),
        button(
          AppStrings.rewind15,
          Ionicons.playBack,
          enabled ? onRewind : null,
        ),
        button(
          playing ? AppStrings.pause : AppStrings.play,
          playing ? Ionicons.pauseCircle : Ionicons.playCircle,
          enabled ? onTogglePlay : null,
          size: playIconSize,
        ),
        button(
          AppStrings.forward15,
          Ionicons.playForward,
          enabled ? onForward : null,
        ),
        button(
          AppStrings.nextChapter,
          Ionicons.playSkipForward,
          enabled && hasNext ? onNext : null,
        ),
      ],
    );
  }
}
