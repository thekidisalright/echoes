import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../app/widgets/screen_header.dart';
import '../../library/domain/sort_order.dart';
import 'settings_providers.dart';

/// Configurações: ordem da biblioteca e versão do app.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(librarySortProvider).value ?? SortOrder.recent;
    final version = ref.watch(appVersionProvider).value;
    final padding = AppSpacing.screenPaddingFor(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            padding,
            AppSpacing.screenTop,
            padding,
            AppSpacing.listBottom,
          ),
          children: [
            const ScreenHeader(title: AppStrings.settings),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              AppStrings.librarySortTitle,
              style: AppTypography.subsectionTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              AppStrings.librarySortMessage,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final order in SortOrder.values)
              _RadioRow(
                label: switch (order) {
                  SortOrder.recent => AppStrings.librarySortRecent,
                  SortOrder.title => AppStrings.librarySortTitleOption,
                },
                selected: order == sort,
                onTap: () =>
                    ref.read(settingsRepositoryProvider).setLibrarySort(order),
              ),
            const SizedBox(height: AppSpacing.xxl),
            const Text(AppStrings.about, style: AppTypography.subsectionTitle),
            const SizedBox(height: AppSpacing.sm),
            const Text(AppStrings.appName, style: AppTypography.body),
            if (version != null)
              Text(
                AppStrings.appVersion(version),
                style: AppTypography.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
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
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
          child: Row(
            children: [
              Icon(
                selected ? Ionicons.radioButtonOn : Ionicons.radioButtonOff,
                size: AppSpacing.listIcon,
                color: selected ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(label, style: AppTypography.body),
            ],
          ),
        ),
      ),
    );
  }
}
