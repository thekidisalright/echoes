import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/strings.dart';
import '../../player/presentation/player_providers.dart';
import '../domain/book_summary.dart';

/// Toque num livro: abre no player e mostra o Player. Com a origem
/// indisponível, leva a Gerenciar biblioteca com o aviso para atualizá-la.
Future<void> openBookAndShowPlayer(
  BuildContext context,
  WidgetRef ref,
  BookSummary summary,
) async {
  if (!summary.sourceAvailable) {
    await context.push(
      AppRoutes.manage,
      extra: const ManageLibraryArgs(notice: AppStrings.sourceUnavailableHint),
    );
    return;
  }
  final bool opened;
  try {
    opened = await ref
        .read(playbackControllerProvider)
        .openBook(summary.book.id);
  } on Exception catch (e) {
    debugPrint('Falha ao abrir o livro ${summary.book.id}: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.openBookError)));
    }
    return;
  }
  // Falso: o livro sumiu entre a lista e o toque (origem removida).
  if (opened && context.mounted) await context.push(AppRoutes.player);
}
