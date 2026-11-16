import 'package:echoes/app/strings.dart';
import 'package:echoes/app/theme/theme.dart';
import 'package:echoes/features/library/domain/book.dart';
import 'package:echoes/features/library/domain/book_summary.dart';
import 'package:echoes/features/library/domain/sort_order.dart';
import 'package:echoes/features/library/presentation/library_providers.dart';
import 'package:echoes/features/library/presentation/library_screen.dart';
import 'package:echoes/features/player/domain/player_state.dart';
import 'package:echoes/features/player/presentation/player_providers.dart';
import 'package:echoes/features/settings/presentation/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

BookSummary summary(
  String id, {
  String title = 'Livro',
  String author = 'Autora',
  int chapters = 10,
  Duration? total = const Duration(hours: 5, minutes: 3),
  bool available = true,
  DateTime? lastPlayedAt,
}) => BookSummary(
  book: Book(
    id: id,
    sourceId: 'folder:1',
    scannedTitle: title,
    scannedAuthor: author,
    chapterCount: chapters,
    createdAt: DateTime(2026),
    totalDuration: total,
    lastPlayedAt: lastPlayedAt,
  ),
  sourceAvailable: available,
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    List<BookSummary> books = const [],
    List<BookSummary> recent = const [],
    String query = '',
    PlayerState player = PlayerState.empty,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryBooksProvider.overrideWith((ref) => Stream.value(books)),
          continueListeningProvider.overrideWith((ref) => Stream.value(recent)),
          librarySortProvider.overrideWith(
            (ref) => Stream.value(SortOrder.recent),
          ),
          playerStateProvider.overrideWith((ref) => Stream.value(player)),
          librarySearchProvider.overrideWith(() => _FixedSearch(query)),
        ],
        child: MaterialApp(theme: buildAppTheme(), home: const LibraryScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('colunas da grade conforme a largura', () {
    expect(LibraryScreen.columnsFor(400), 2);
    expect(LibraryScreen.columnsFor(620), 2);
    expect(LibraryScreen.columnsFor(621), 4);
    expect(LibraryScreen.columnsFor(900), 4);
    expect(LibraryScreen.columnsFor(901), 5);
  });

  testWidgets('biblioteca vazia mostra "Nenhum audiobook"', (tester) async {
    await pump(tester);
    expect(find.text(AppStrings.emptyLibraryTitle), findsOneWidget);
    expect(find.text(AppStrings.continueListening), findsNothing);
  });

  testWidgets('busca sem resultado mostra "Nenhum resultado"', (tester) async {
    await pump(tester, query: 'xyz');
    expect(find.text(AppStrings.noResults), findsOneWidget);
    expect(find.text(AppStrings.emptyLibraryTitle), findsNothing);
  });

  testWidgets('grade mostra título, autor e detalhe', (tester) async {
    await pump(
      tester,
      books: [
        summary('a', title: 'Misery', author: ''),
        summary('b', title: 'Duna', available: false),
      ],
    );
    expect(find.text('Misery'), findsOneWidget);
    expect(find.text(AppStrings.unknownAuthor), findsOneWidget);
    expect(
      find.text('${AppStrings.chapterCount(10)} · 5h 03m'),
      findsOneWidget,
    );
    expect(find.text(AppStrings.sourceUnavailable), findsOneWidget);
  });

  testWidgets('Continue ouvindo marca o livro tocando', (tester) async {
    final misery = summary('a', title: 'Misery', lastPlayedAt: DateTime(2026));
    await pump(
      tester,
      books: [misery],
      recent: [misery],
      player: PlayerState(book: misery.book, chapters: const [], playing: true),
    );
    expect(find.text(AppStrings.continueListening), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        '${AppStrings.listenTo('Misery')}, ${AppStrings.nowPlaying}',
      ),
      findsOneWidget,
    );
  });
}

class _FixedSearch extends LibrarySearch {
  _FixedSearch(this._query);

  final String _query;

  @override
  String build() => _query;
}
