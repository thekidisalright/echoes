import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../library/domain/library_source.dart';
import '../../library/presentation/library_providers.dart';
import '../domain/import_mode.dart';
import '../domain/import_progress.dart';
import '../domain/import_result.dart';
import 'import_providers.dart';

/// Gerenciar biblioteca.
///
/// PROVISÓRIO (Fase 3): versão mínima para validar a importação no aparelho.
/// O layout definitivo (banner, cartões de origem, confirmação de remoção)
/// vem na Fase 5.1.
class ManageLibraryScreen extends ConsumerWidget {
  const ManageLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importControllerProvider);
    final sources = ref.watch(sourcesProvider).value ?? const [];
    final busy = state is ImportRunning;

    ref.listen(importControllerProvider, (_, next) {
      if (next is ImportFailed) {
        ref.read(importControllerProvider.notifier).clearError();
        final (title, message) = switch (next.kind) {
          ImportErrorKind.folder => (
            AppStrings.importFolderErrorTitle,
            AppStrings.importFolderErrorMessage,
          ),
          ImportErrorKind.files => (
            AppStrings.importFilesErrorTitle,
            AppStrings.importFilesErrorMessage,
          ),
          ImportErrorKind.accessExpired => (
            AppStrings.accessExpiredTitle,
            AppStrings.accessExpiredMessage,
          ),
        };
        _alert(context, title, message);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          icon: const Icon(Ionicons.arrowBack),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          AppStrings.manageLibrary,
          style: AppTypography.sectionTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          FilledButton.icon(
            onPressed: busy ? null : () => _addFolder(context, ref),
            icon: const Icon(Ionicons.folderOpenOutline),
            label: const Text(AppStrings.addFolder),
          ),
          OutlinedButton.icon(
            onPressed: busy ? null : () => _addFiles(context, ref),
            icon: const Icon(Ionicons.documentsOutline),
            label: const Text(AppStrings.addFiles),
          ),
          if (state is ImportRunning)
            ListTile(
              leading: const CircularProgressIndicator(),
              title: Text(_progressText(state.progress)),
            ),
          const SizedBox(height: AppSpacing.screenPadding),
          const Text(
            AppStrings.sourcesSection,
            style: AppTypography.subsectionTitle,
          ),
          if (sources.isEmpty)
            const Text(AppStrings.sourcesEmpty, style: AppTypography.bodySmall),
          for (final source in sources)
            ListTile(
              title: Text(source.name),
              subtitle: Text(
                AppStrings.sourceSummary(
                  source.bookCount,
                  available: source.available,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (source.kind == SourceKind.folder)
                    IconButton(
                      tooltip: AppStrings.refreshSource,
                      icon: const Icon(Ionicons.refresh),
                      onPressed: busy
                          ? null
                          : () => _rescan(context, ref, source),
                    ),
                  IconButton(
                    tooltip: AppStrings.removeSource,
                    icon: const Icon(Ionicons.trashOutline),
                    onPressed: busy
                        ? null
                        : () => ref
                              .read(importControllerProvider.notifier)
                              .remove(source),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addFolder(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(importControllerProvider.notifier);
    final dir = await controller.pickDirectory();
    if (dir == null || !context.mounted) return;
    final mode = await showDialog<ImportMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text(AppStrings.importModeTitle),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.dialogPadding),
            child: Text(AppStrings.importModeMessage),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ImportMode.oneBook),
            child: const Text(AppStrings.importModeOneBook),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ImportMode.booksInFolders),
            child: const Text(AppStrings.importModeBooksInFolders),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );
    if (mode == null) return;
    final result = await controller.importFolder(dir, mode);
    if (result is ImportNothingNew && context.mounted) {
      await _alert(
        context,
        AppStrings.importNothingNewTitle,
        AppStrings.importNothingNewMessage,
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
    if (alert != null) await _alert(context, alert.$1, alert.$2);
  }

  Future<void> _rescan(
    BuildContext context,
    WidgetRef ref,
    LibrarySource source,
  ) => ref.read(importControllerProvider.notifier).rescan(source);

  static String _progressText(ImportProgress progress) => switch (progress) {
    ImportPreparing() => AppStrings.importPreparing,
    ImportReadingFolder(:final current, :final total) =>
      AppStrings.importReadingFolder(current, total),
    ImportReadingFiles(:final count) => AppStrings.importReadingFiles(count),
    ImportSaving() => AppStrings.importSaving,
  };

  static Future<void> _alert(
    BuildContext context,
    String title,
    String message,
  ) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.ok),
        ),
      ],
    ),
  );
}
