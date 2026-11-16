import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/strings.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../app/theme/typography.dart';
import '../../../library/domain/library_source.dart';

/// Linha de uma origem em Gerenciar biblioteca.
class SourceTile extends StatelessWidget {
  const SourceTile({
    required this.source,
    required this.enabled,
    required this.onRefresh,
    required this.onRemove,
    super.key,
  });

  final LibrarySource source;

  /// Falso durante uma importação.
  final bool enabled;
  final VoidCallback onRefresh;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isFolder = source.kind == SourceKind.folder;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.sourceIconBox,
            height: AppSpacing.sourceIconBox,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.banner),
            ),
            child: Icon(
              isFolder ? Ionicons.folderOutline : Ionicons.musicalNotesOutline,
              size: AppSpacing.listIcon,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.name,
                  style: AppTypography.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppStrings.sourceSummary(
                    source.bookCount,
                    available: source.available,
                  ),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          if (isFolder)
            IconButton(
              tooltip: AppStrings.refreshSource,
              icon: const Icon(Ionicons.refreshOutline),
              iconSize: AppSpacing.actionIcon,
              onPressed: enabled ? onRefresh : null,
            ),
          IconButton(
            tooltip: AppStrings.removeSource,
            icon: const Icon(Ionicons.trashOutline),
            iconSize: AppSpacing.actionIcon,
            onPressed: enabled ? onRemove : null,
          ),
        ],
      ),
    );
  }
}
