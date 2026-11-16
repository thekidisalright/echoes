import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../app/widgets/screen_header.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/duration_format.dart';
import '../../bookmarks/domain/bookmark.dart';
import '../../bookmarks/presentation/bookmark_providers.dart';
import '../../library/domain/chapter.dart';
import '../../player/domain/player_state.dart';
import '../../player/presentation/player_providers.dart';

/// Capítulos e marcadores do livro carregado no player, em duas abas.
///
/// Abre na aba Capítulos, com o capítulo atual visível. Tocar num capítulo ou marcador leva o
/// player até ele e volta ao Player.
class ChaptersScreen extends ConsumerStatefulWidget {
  const ChaptersScreen({super.key});

  /// Altura fixa de cada capítulo, para rolar até o atual sem medir.
  static const chapterExtent = 56.0;

  @override
  ConsumerState<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends ConsumerState<ChaptersScreen> {
  /// Capítulos acima do atual que continuam visíveis ao abrir.
  static const _contextChapters = 2;

  final _scroll = ScrollController();

  /// Já rolou até o capítulo atual (só na primeira vez que há capítulos).
  bool _scrolledToCurrent = false;

  void _scrollToCurrent(int index) {
    _scrolledToCurrent = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      final offset =
          math.max(0, index - _contextChapters) * ChaptersScreen.chapterExtent;
      _scroll.jumpTo(math.min(offset, position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _playChapter(int index) async {
    await ref.read(playbackControllerProvider).playChapter(index);
    if (mounted) context.pop();
  }

  Future<void> _openBookmark(Bookmark bookmark) async {
    final ok = await ref
        .read(playbackControllerProvider)
        .playAt(bookmark.chapterId, bookmark.position);
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerStateProvider).value ?? PlayerState.empty;
    final bookmarks = ref.watch(currentBookmarksProvider).value ?? const [];
    final padding = AppSpacing.screenPaddingFor(
      MediaQuery.sizeOf(context).width,
    );
    final chapterById = {for (final c in state.chapters) c.id: c};
    if (!_scrolledToCurrent && state.hasBook) {
      _scrollToCurrent(state.chapterIndex);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  AppSpacing.screenTop,
                  padding,
                  AppSpacing.sm,
                ),
                child: ScreenHeader(
                  title: state.book?.title ?? AppStrings.chapters,
                  subtitle: AppStrings.chaptersAndBookmarks,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: TabBar(
                  tabs: [
                    const Tab(text: AppStrings.chaptersTab),
                    Tab(text: AppStrings.bookmarksTab(bookmarks.length)),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.fromLTRB(
                        padding,
                        AppSpacing.sm,
                        padding,
                        AppSpacing.listBottom,
                      ),
                      itemExtent: ChaptersScreen.chapterExtent,
                      itemCount: state.chapters.length,
                      itemBuilder: (context, index) => _ChapterTile(
                        index: index,
                        chapter: state.chapters[index],
                        current: index == state.chapterIndex,
                        onTap: () => _playChapter(index),
                      ),
                    ),
                    if (bookmarks.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: AppSpacing.xl,
                        ),
                        child: const Text(
                          AppStrings.bookmarksEmpty,
                          style: AppTypography.bodySmall,
                        ),
                      )
                    else
                      ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          padding,
                          AppSpacing.sm,
                          padding,
                          AppSpacing.listBottom,
                        ),
                        itemCount: bookmarks.length,
                        itemBuilder: (context, index) {
                          final bookmark = bookmarks[index];
                          return _BookmarkTile(
                            key: ValueKey(bookmark.id),
                            bookmark: bookmark,
                            chapter: chapterById[bookmark.chapterId],
                            onTap: () => _openBookmark(bookmark),
                            onRemove: () => ref
                                .read(bookmarkRepositoryProvider)
                                .remove(bookmark.id),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.index,
    required this.chapter,
    required this.current,
    required this.onTap,
  });

  final int index;
  final Chapter chapter;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = chapter.duration;
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppSpacing.xxl,
              child: Text(
                (index + 1).toString().padLeft(2, '0'),
                style: AppTypography.caption,
              ),
            ),
            Expanded(
              child: Text(
                chapter.title,
                style: AppTypography.body.copyWith(
                  color: current ? AppColors.accent : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (duration != null) ...[
              const SizedBox(width: AppSpacing.md),
              Text(formatClock(duration), style: AppTypography.caption),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({
    required this.bookmark,
    required this.chapter,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  final Bookmark bookmark;

  /// Nulo se o capítulo não existe mais.
  final Chapter? chapter;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final chapter = this.chapter;
    return InkWell(
      onTap: chapter == null ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            const Icon(
              Ionicons.bookmark,
              size: AppSpacing.statusIcon,
              color: AppColors.accent,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter?.title ?? AppStrings.chapterRemoved,
                    style: AppTypography.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${formatClock(bookmark.position)} · '
                    '${formatShortDate(bookmark.createdAt)}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: AppStrings.removeBookmark,
              iconSize: AppSpacing.actionIcon,
              icon: const Icon(Ionicons.trashOutline),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
