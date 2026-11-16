import 'dart:async';

import 'package:echoes/app/theme/theme.dart';
import 'package:echoes/features/library/domain/book.dart';
import 'package:echoes/features/library/domain/chapter.dart';
import 'package:echoes/features/player/domain/player_state.dart';
import 'package:echoes/features/player/presentation/player_providers.dart';
import 'package:echoes/features/player/presentation/player_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final book = Book(
    id: 'b',
    sourceId: 's',
    scannedTitle: 'A Guerra dos Tronos',
    scannedAuthor: 'George R. R. Martin',
    chapterCount: 2,
    createdAt: DateTime(2026),
  );
  const chapters = [
    Chapter(id: 'c1', bookId: 'b', title: 'Prólogo', uri: 'u1', sortOrder: 0),
    Chapter(id: 'c2', bookId: 'b', title: 'Bran', uri: 'u2', sortOrder: 1),
  ];
  final state = PlayerState(
    book: book,
    chapters: chapters,
    chapterIndex: 0,
    duration: const Duration(minutes: 30),
  );

  Future<void> openPlayer(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => const Scaffold(body: Text('biblioteca')),
        ),
        GoRoute(path: '/player', builder: (context, _) => const PlayerScreen()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerStateProvider.overrideWith((ref) => Stream.value(state)),
          playerPositionProvider.overrideWith(
            (ref) => Stream.value(Duration.zero),
          ),
        ],
        child: MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(router.push('/player'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerScreen), findsOneWidget);
  }

  Future<void> dragDown(WidgetTester tester) async {
    await tester.drag(
      find.text('A Guerra dos Tronos'),
      const Offset(0, 300),
      touchSlopY: 20,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('arrastar para baixo fecha quando o conteúdo cabe', (
    tester,
  ) async {
    await openPlayer(tester, const Size(800, 1400));
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .maxScrollExtent,
      0,
    );
    await dragDown(tester);
    expect(find.byType(PlayerScreen), findsNothing);
  });

  testWidgets('arrastar para baixo fecha quando o conteúdo rola', (
    tester,
  ) async {
    await openPlayer(tester, const Size(360, 560));
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .maxScrollExtent,
      greaterThan(0),
    );
    await dragDown(tester);
    expect(find.byType(PlayerScreen), findsNothing);
  });

  testWidgets('arrasto curto devolve o Player', (tester) async {
    await openPlayer(tester, const Size(360, 560));
    await tester.timedDrag(
      find.text('A Guerra dos Tronos'),
      const Offset(0, 60),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PlayerScreen), findsOneWidget);
  });
}
