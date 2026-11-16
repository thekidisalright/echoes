import 'dart:async';

import 'package:echoes/app/theme/theme.dart';
import 'package:echoes/features/library/domain/book.dart';
import 'package:echoes/features/library/domain/chapter.dart';
import 'package:echoes/features/player/domain/player_state.dart';
import 'package:echoes/features/player/presentation/player_providers.dart';
import 'package:echoes/features/player/presentation/player_screen.dart';
import 'package:echoes/features/sleep_timer/data/sleep_timer_service.dart';
import 'package:echoes/features/sleep_timer/presentation/sleep_timer_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Timer que nunca dispara: o teste só confere o estado exibido.
class _IdleTimer implements Timer {
  bool _active = true;

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

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

  late SleepTimerService timer;
  late int pauses;

  Future<void> openPlayer(WidgetTester tester, Size size) async {
    pauses = 0;
    timer = SleepTimerService(
      player: Stream.value(state),
      pause: () async => pauses++,
      createTimer: (_, _) => _IdleTimer(),
    );
    addTearDown(timer.dispose);
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
          sleepTimerServiceProvider.overrideWithValue(timer),
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
    expect(find.byType(SingleChildScrollView), findsNothing);
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

  group('timer de sono', () {
    const size = Size(800, 1400);

    testWidgets('folha liga o timer por minutos e o botão mostra o resto', (
      tester,
    ) async {
      await openPlayer(tester, size);
      expect(find.text('Temporizador'), findsOneWidget);

      await tester.tap(find.text('Temporizador'));
      await tester.pumpAndSettle();
      expect(find.text('Quando deseja pausar?'), findsOneWidget);
      for (final label in [
        '15 minutos',
        '30 minutos',
        '45 minutos',
        '60 minutos',
        'Ao fim do capítulo',
        'Cancelar',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      expect(find.text('Desligar temporizador'), findsNothing);

      await tester.tap(find.text('30 minutos'));
      await tester.pumpAndSettle();
      expect(find.text('Quando deseja pausar?'), findsNothing);
      expect(find.text('Timer · 30 min'), findsOneWidget);

      // Desligar fica dentro da folha, só com timer ativo.
      await tester.tap(find.text('Timer · 30 min'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Desligar temporizador'));
      await tester.pumpAndSettle();
      expect(find.text('Quando deseja pausar?'), findsNothing);
      expect(find.text('Temporizador'), findsOneWidget);
      expect(pauses, 0);
    });

    testWidgets('fim do capítulo mostra "Timer ativo"', (tester) async {
      await openPlayer(tester, size);
      await tester.tap(find.text('Temporizador'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ao fim do capítulo'));
      await tester.pumpAndSettle();
      expect(find.text('Timer ativo'), findsOneWidget);
    });

    testWidgets('"Cancelar" na folha não liga nada', (tester) async {
      await openPlayer(tester, size);
      await tester.tap(find.text('Temporizador'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Temporizador'), findsOneWidget);
    });
  });

  testWidgets('em tela de celular tudo cabe sem rolar', (tester) async {
    await openPlayer(tester, const Size(393, 760));
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('Capítulos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
