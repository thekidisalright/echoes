import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/strings.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../import/presentation/widgets/import_status_banner.dart';
import '../../player/presentation/player_providers.dart';
import '../../player/presentation/widgets/mini_player.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/sort_order.dart';
import 'library_providers.dart';
import 'open_book.dart';
import 'widgets/book_grid_item.dart';
import 'widgets/continue_listening_item.dart';
import 'widgets/empty_state.dart';
import 'widgets/search_field.dart';
import 'widgets/sort_chips.dart';

/// Tela inicial: cabeçalho, Continue ouvindo, busca e grade.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  /// Colunas da grade conforme a largura (docs/FEATURES.md §2).
  static int columnsFor(double width) => width > 900
      ? 5
      : width > 620
      ? 4
      : 2;

  static const _gridSpacing = 14.0;
  static const _gridRunSpacing = 20.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = AppSpacing.screenPaddingFor(width);
    final books = ref.watch(libraryBooksProvider).value;
    final recent = ref.watch(continueListeningProvider).value ?? const [];
    final query = ref.watch(librarySearchProvider);
    final sort = ref.watch(librarySortProvider).value ?? SortOrder.recent;
    final hasBook = ref.watch(
      playerStateProvider.select((s) => s.value?.hasBook ?? false),
    );

    final columns = columnsFor(width);
    final itemWidth =
        (width - padding * 2 - _gridSpacing * (columns - 1)) / columns;

    final scroll = SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              padding,
              AppSpacing.screenTop,
              padding,
              0,
            ),
            sliver: SliverList.list(
              children: [
                const _Header(),
                const SizedBox(height: AppSpacing.xl),
                const ImportStatusBanner(),
                if (recent.isNotEmpty) ...[
                  const Text(
                    AppStrings.continueListening,
                    style: AppTypography.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _ContinueListening(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
                SearchField(
                  initialValue: query,
                  onChanged: ref.read(librarySearchProvider.notifier).set,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        AppStrings.library,
                        style: AppTypography.sectionTitle,
                      ),
                    ),
                    SortChips(
                      value: sort,
                      onChanged: (order) => ref
                          .read(settingsRepositoryProvider)
                          .setLibrarySort(order),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          if (books == null)
            const SliverToBoxAdapter(child: SizedBox.shrink())
          else if (books.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                searching: query.trim().isNotEmpty,
                onManage: () => context.push(AppRoutes.manage),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: _gridSpacing,
                  mainAxisSpacing: _gridRunSpacing,
                  childAspectRatio: BookGridItem.aspectRatioFor(itemWidth),
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final summary = books[index];
                  return BookGridItem(
                    key: ValueKey(summary.book.id),
                    summary: summary,
                    onTap: () => openBookAndShowPlayer(context, ref, summary),
                    // Diálogo de edição: Fase 5.6.
                    onLongPress: () {},
                  );
                },
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  MediaQuery.paddingOf(context).bottom +
                  (hasBook ? AppSpacing.miniPlayerClearance : 0) +
                  AppSpacing.listBottom,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          scroll,
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
            child: const MiniPlayer(),
          ),
        ],
      ),
    );
  }
}

class _ContinueListening extends ConsumerWidget {
  const _ContinueListening();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(continueListeningProvider).value ?? const [];
    final player = ref.watch(playerStateProvider).value;
    final playingId = (player?.playing ?? false) ? player!.book?.id : null;
    return Column(
      children: [
        for (final summary in recent)
          ContinueListeningItem(
            key: ValueKey(summary.book.id),
            summary: summary,
            playing: summary.book.id == playingId,
            onTap: () => openBookAndShowPlayer(context, ref, summary),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(AppStrings.appName, style: AppTypography.display),
        ),
        _HeaderButton(
          icon: Ionicons.libraryOutline,
          label: AppStrings.manageLibrary,
          onPressed: () => context.push(AppRoutes.manage),
        ),
        const SizedBox(width: AppSpacing.sm),
        _HeaderButton(
          icon: Ionicons.settingsOutline,
          label: AppStrings.settings,
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: AppSpacing.headerIconButton,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: const BorderSide(color: AppColors.borderStrong),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.field),
            ),
          ),
          child: Icon(
            icon,
            size: AppSpacing.headerIcon,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}
