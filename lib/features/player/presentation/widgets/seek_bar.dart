import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../../core/utils/duration_format.dart';

/// Barra de progresso do capítulo. Arrastar só move o áudio ao soltar;
/// enquanto isso os tempos acompanham o dedo.
class SeekBar extends StatefulWidget {
  const SeekBar({
    required this.position,
    required this.duration,
    required this.onSeek,
    super.key,
  });

  final Duration position;

  /// Nulo enquanto a duração do capítulo é desconhecida (barra desativada).
  final Duration? duration;
  final ValueChanged<Duration> onSeek;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  /// Valor sob o dedo, em ms.
  double? _dragging;

  /// Posição pedida ao soltar, mantida até o player chegar perto dela, para
  /// o thumb não voltar ao ponto antigo por um instante.
  Duration? _pending;

  static const _settleTolerance = Duration(seconds: 1);

  @override
  void didUpdateWidget(SeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pending = _pending;
    if (pending != null &&
        (widget.position - pending).abs() <= _settleTolerance) {
      _pending = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.duration;
    final max = (total?.inMilliseconds ?? 0).toDouble();
    final shown = _dragging != null
        ? Duration(milliseconds: _dragging!.round())
        : _pending ?? widget.position;
    final value = max > 0
        ? shown.inMilliseconds.toDouble().clamp(0.0, max)
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          ),
          child: Slider(
            value: value,
            max: max > 0 ? max : 1,
            onChangeStart: max > 0
                ? (v) => setState(() => _dragging = v)
                : null,
            onChanged: max > 0 ? (v) => setState(() => _dragging = v) : null,
            onChangeEnd: max > 0
                ? (v) {
                    final target = Duration(milliseconds: v.round());
                    setState(() {
                      _dragging = null;
                      _pending = target;
                    });
                    widget.onSeek(target);
                  }
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatClock(shown), style: AppTypography.caption),
              Text(
                total == null ? '' : formatRemaining(shown, total),
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
