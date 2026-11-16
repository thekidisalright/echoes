import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../domain/import_progress.dart';
import '../import_providers.dart';

/// Banner com spinner e a mensagem da importação em andamento. Some quando
/// não há importação.
class ImportStatusBanner extends ConsumerWidget {
  const ImportStatusBanner({
    this.padding = const EdgeInsets.only(bottom: AppSpacing.xl),
    super.key,
  });

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importControllerProvider);
    if (state is! ImportRunning) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: InfoBanner(
        leading: const SizedBox.square(
          dimension: AppSpacing.lg,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        text: progressText(state.progress),
      ),
    );
  }

  static String progressText(ImportProgress progress) => switch (progress) {
    ImportPreparing() => AppStrings.importPreparing,
    ImportReadingFolder(:final current, :final total) =>
      AppStrings.importReadingFolder(current, total),
    ImportReadingFiles(:final count) => AppStrings.importReadingFiles(count),
    ImportSaving() => AppStrings.importSaving,
  };
}

/// Caixa `surface` com ícone e texto (banner de importação e avisos).
class InfoBanner extends StatelessWidget {
  const InfoBanner({required this.leading, required this.text, super.key});

  final Widget leading;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.banner),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }
}
