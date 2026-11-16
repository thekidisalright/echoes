import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';

/// Biblioteca vazia ("Nenhum audiobook") ou busca sem resultado.
class EmptyState extends StatelessWidget {
  const EmptyState({required this.searching, this.onManage, super.key});

  /// Há texto na busca: mostra "Nenhum resultado".
  final bool searching;

  /// Leva a Gerenciar biblioteca (só na biblioteca vazia).
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final onManage = this.onManage;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl * 2,
        horizontal: AppSpacing.xl,
      ),
      child: Column(
        children: [
          const Icon(
            Ionicons.headsetOutline,
            size: AppSpacing.emptyStateIcon,
            color: AppColors.textPlaceholder,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            searching ? AppStrings.noResults : AppStrings.emptyLibraryTitle,
            style: AppTypography.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            searching
                ? AppStrings.noResultsMessage
                : AppStrings.emptyLibraryMessage,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (!searching && onManage != null) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onManage,
              icon: const Icon(
                Ionicons.libraryOutline,
                size: AppSpacing.actionIcon,
              ),
              label: const Text(AppStrings.manageLibrary),
            ),
          ],
        ],
      ),
    );
  }
}
