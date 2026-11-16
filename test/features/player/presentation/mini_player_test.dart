import 'package:echoes/app/strings.dart';
import 'package:echoes/app/theme/theme.dart';
import 'package:echoes/features/library/domain/book.dart';
import 'package:echoes/features/library/domain/chapter.dart';
import 'package:echoes/features/player/domain/player_state.dart';
import 'package:echoes/features/player/presentation/player_providers.dart';
import 'package:echoes/features/player/presentation/widgets/mini_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final book = Book(
    id: 'b',
    sourceId: 's',
    scannedTitle: 'Misery',
    scannedAuthor: 'Stephen King',
    chapterCount: 2,
    createdAt: DateTime(2026),
  );
  const chapters = [
    Chapter(id: 'c1', bookId: 'b', title: 'Parte 1', uri: 'u1', sortOrder: 0),
    Chapter(id: 'c2', bookId: 'b', title: 'Parte 2', uri: 'u2', sortOrder: 1),
  ];

  Future<void> pump(WidgetTester tester, PlayerState state) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerStateProvider.overrideWith((ref) => Stream.value(state)),
          playerPositionProvider.overrideWith(
            (ref) => Stream.value(const Duration(minutes: 1)),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: MiniPlayer()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sem livro não aparece', (tester) async {
    await pump(tester, PlayerState.empty);
    expect(find.byTooltip(AppStrings.play), findsNothing);
  });

  testWidgets('mostra livro, capítulo e progresso do capítulo', (tester) async {
    await pump(
      tester,
      PlayerState(
        book: book,
        chapters: chapters,
        chapterIndex: 1,
        duration: const Duration(minutes: 4),
        playing: true,
      ),
    );
    expect(find.text('Misery'), findsOneWidget);
    expect(find.text('Parte 2'), findsOneWidget);
    expect(find.byTooltip(AppStrings.pause), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.25);
  });
}
