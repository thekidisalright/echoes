import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import 'sleep_timer_providers.dart';

/// Abre a folha "Temporizador" e liga o timer escolhido.
Future<void> showSleepTimerSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => const SleepTimerSheet(),
    );

/// Folha inferior: 15/30/45/60 minutos, fim do capítulo ou cancelar.
class SleepTimerSheet extends ConsumerWidget {
  const SleepTimerSheet({super.key});

  static const minuteOptions = [15, 30, 45, 60];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void choose(void Function() start) {
      start();
      Navigator.pop(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.dialogPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            AppStrings.sleepTimerTitle,
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            AppStrings.sleepTimerMessage,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final minutes in minuteOptions)
            _Option(
              label: AppStrings.sleepTimerMinutes(minutes),
              onTap: () => choose(
                () => ref
                    .read(sleepTimerServiceProvider)
                    .startCountdown(Duration(minutes: minutes)),
              ),
            ),
          _Option(
            label: AppStrings.sleepTimerEndOfChapter,
            onTap: () => choose(
              () => ref.read(sleepTimerServiceProvider).startEndOfChapter(),
            ),
          ),
          _Option(
            label: AppStrings.cancel,
            color: AppColors.textSecondary,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.field),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: color),
            ),
          ),
        ),
      ),
    );
  }
}
