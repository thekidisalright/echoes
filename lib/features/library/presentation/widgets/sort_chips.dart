import 'package:material_ui/material_ui.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../domain/sort_order.dart';

/// Chips "Recentes" / "Título".
class SortChips extends StatelessWidget {
  const SortChips({required this.value, required this.onChanged, super.key});

  final SortOrder value;
  final ValueChanged<SortOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        for (final order in SortOrder.values)
          _Chip(
            label: switch (order) {
              SortOrder.recent => AppStrings.sortRecent,
              SortOrder.title => AppStrings.sortTitle,
            },
            selected: order == value,
            onTap: () => onChanged(order),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.accentFill : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: selected ? AppColors.onAccent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
