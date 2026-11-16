import 'package:echoes/app/strings.dart';
import 'package:echoes/app/theme/colors.dart';
import 'package:echoes/app/theme/theme.dart';
import 'package:echoes/features/bookmarks/domain/bookmark.dart';
import 'package:echoes/features/bookmarks/presentation/bookmark_providers.dart';
import 'package:echoes/features/chapters/presentation/chapters_screen.dart';
import 'package:echoes/features/library/domain/book.dart';
import 'package:echoes/features/library/domain/chapter.dart';
import 'package:echoes/features/player/domain/player_state.dart';
import 'package:echoes/features/player/presentation/player_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/accessibility.dart';

void main() {
  final book = Book(
    id: 'b',
    sourceId: 's',
    scannedTitle: 'Misery',
    scannedAuthor: 'Stephen King',
    chapterCount: 40,
    createdAt: DateTime(2026),
  );
  final chapters = [
    for (var i = 0; i < 40; i++)
      Chapter(
        id: 'c$i',
        bookId: 'b',
        title: 'Parte ${i + 1}',
        uri: 'u$i',
        sortOrder: i,
        duration: const Duration(minutes: 3, seconds: 5),
      ),
  ];

  Future<void> pump(
    WidgetTester tester, {
    int index = 0,
    List<Bookmark> bookmarks = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerStateProvider.overrideWith(
            (ref) => Stream.value(
              PlayerState(book: book, chapters: chapters, chapterIndex: index),
            ),
          ),
          currentBookmarksProvider.overrideWith(
            (ref) => Stream.value(bookmarks),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ChaptersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista capítulos com número, nome e duração', (tester) async {
    await pump(tester);
    expect(find.text('Misery'), findsOneWidget);
    expect(find.text(AppStrings.chaptersTab), findsOneWidget);
    expect(find.text(AppStrings.bookmarksTab(0)), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('Parte 1'), findsOneWidget);
    expect(find.text('03:05'), findsWidgets);
    await expectAccessible(tester);
  });

  testWidgets('abre rolada até o capítulo atual, em dourado', (tester) async {
    await pump(tester, index: 30);
    final current = tester.widget<Text>(find.text('Parte 31'));
    expect(current.style?.color, AppColors.accent);
    expect(find.text('Parte 1'), findsNothing);
  });

  testWidgets('sem marcadores mostra o texto de vazio', (tester) async {
    await pump(tester);
    expect(find.text(AppStrings.bookmarksEmpty), findsNothing);
    await tester.tap(find.text(AppStrings.bookmarksTab(0)));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.bookmarksEmpty), findsOneWidget);
  });

  testWidgets('aba de marcadores com contagem e capítulo removido', (
    tester,
  ) async {
    await pump(
      tester,
      bookmarks: [
        Bookmark(
          id: 1,
          bookId: 'b',
          chapterId: 'sumiu',
          position: const Duration(minutes: 12, seconds: 34),
          createdAt: DateTime(2026, 11, 16),
        ),
      ],
    );
    // A aba mostra o total, sem rolar a lista de capítulos.
    await tester.tap(find.text(AppStrings.bookmarksTab(1)));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.chapterRemoved), findsOneWidget);
    expect(find.text('12:34 · 16/11/2026'), findsOneWidget);
    expect(find.byTooltip(AppStrings.removeBookmark), findsOneWidget);
    await expectAccessible(tester);
  });
}
