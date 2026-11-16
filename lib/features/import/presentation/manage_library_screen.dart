import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../app/widgets/dialogs.dart';
import '../../../app/widgets/screen_header.dart';
import '../../library/domain/library_source.dart';
import '../../library/presentation/library_providers.dart';
import '../domain/import_result.dart';
import 'import_providers.dart';
import 'widgets/import_mode_dialog.dart';
import 'widgets/import_status_banner.dart';
import 'widgets/source_tile.dart';

/// Gerenciar biblioteca: adicionar pastas e arquivos, atualizar e remover
/// origens. As falhas viram alerta no `EchoesApp`.
class ManageLibraryScreen extends ConsumerWidget {
  const ManageLibraryScreen({this.notice, super.key});

  /// Aviso no topo (ex.: o livro tocado está numa pasta indisponível).
  final String? notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(importControllerProvider) is ImportRunning;
    final sources = ref.watch(sourcesProvider).value ?? const [];
    final notice = this.notice;
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
            const ScreenHeader(title: AppStrings.manageLibrary),
            const SizedBox(height: AppSpacing.xl),
            if (notice != null) ...[
              InfoBanner(
                leading: const Icon(
                  Ionicons.informationCircleOutline,
                  size: AppSpacing.actionIcon,
                  color: AppColors.accent,
                ),
                text: notice,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Row(
              spacing: AppSpacing.md,
              children: [
                Expanded(
                  child: _ImportButton(
                    icon: Ionicons.folderOpenOutline,
                    label: AppStrings.addFolder,
                    onPressed: busy ? null : () => _addFolder(context, ref),
                  ),
                ),
                Expanded(
                  child: _ImportButton(
                    icon: Ionicons.musicalNotesOutline,
                    label: AppStrings.addFiles,
                    onPressed: busy ? null : () => _addFiles(context, ref),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const ImportStatusBanner(),
            const Text(
              AppStrings.sourcesSection,
              style: AppTypography.sectionTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (sources.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  AppStrings.sourcesEmpty,
                  style: AppTypography.bodySmall,
                ),
              ),
            for (final source in sources)
              SourceTile(
                key: ValueKey(source.id),
                source: source,
                enabled: !busy,
                onRefresh: () => _rescan(context, ref, source),
                onRemove: () => _remove(context, ref, source),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addFolder(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(importControllerProvider.notifier);
    final dir = await controller.pickDirectory();
    if (dir == null || !context.mounted) return;
    final mode = await showImportModeDialog(context);
    if (mode == null) return;
    final result = await controller.importFolder(dir, mode);
    if (result is ImportNothingNew && context.mounted) {
      await showMessageDialog(
        context,
        title: AppStrings.importNothingNewTitle,
        message: AppStrings.importNothingNewMessage,
      );
    }
  }

  Future<void> _addFiles(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(importControllerProvider.notifier)
        .importFiles();
    if (!context.mounted) return;
    final alert = switch (result) {
      ImportNoAudioSelected() => (
        AppStrings.noAudioSelectedTitle,
        AppStrings.noAudioSelectedMessage,
      ),
      ImportFilesAlreadyAdded() => (
        AppStrings.filesAlreadyAddedTitle,
        AppStrings.filesAlreadyAddedMessage,
      ),
      _ => null,
    };
    if (alert != null) {
      await showMessageDialog(context, title: alert.$1, message: alert.$2);
    }
  }

  Future<void> _rescan(
    BuildContext context,
    WidgetRef ref,
    LibrarySource source,
  ) => ref.read(importControllerProvider.notifier).rescan(source);

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    LibrarySource source,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.removeSourceTitle,
      message: AppStrings.removeSourceMessage(source.name),
      confirmLabel: AppStrings.remove,
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(importControllerProvider.notifier).remove(source);
  }
}

/// "Adicionar pasta" / "Adicionar arquivos".
class _ImportButton extends StatelessWidget {
  const _ImportButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: AppSpacing.actionIcon),
      label: Text(
        label,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.borderAccent),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
      ),
    );
  }
}
