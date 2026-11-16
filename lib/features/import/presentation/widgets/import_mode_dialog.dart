import 'package:material_ui/material_ui.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../domain/import_mode.dart';

/// "Como organizar esta pasta?". Devolve o modo escolhido ou nulo.
Future<ImportMode?> showImportModeDialog(BuildContext context) =>
    showDialog<ImportMode>(
      context: context,
      builder: (context) => const ImportModeDialog(),
    );

class ImportModeDialog extends StatelessWidget {
  const ImportModeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.dialogPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              AppStrings.importModeTitle,
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              AppStrings.importModeMessage,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            _Option(
              label: AppStrings.importModeOneBook,
              onPressed: () => Navigator.pop(context, ImportMode.oneBook),
            ),
            const SizedBox(height: AppSpacing.md),
            _Option(
              label: AppStrings.importModeBooksInFolders,
              onPressed: () =>
                  Navigator.pop(context, ImportMode.booksInFolders),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.borderAccent),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
      ),
      child: Text(label, style: AppTypography.body),
    );
  }
}
