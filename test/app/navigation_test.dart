import 'package:echoes/app/app.dart';
import 'package:echoes/app/strings.dart';
import 'package:echoes/features/library/presentation/library_providers.dart';
import 'package:echoes/features/player/domain/player_state.dart';
import 'package:echoes/features/player/presentation/player_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Os streams do drift não terminam dentro do FakeAsync dos testes de
  // widget (o pumpAndSettle nunca assenta); as listas vêm de streams fixos.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryBooksProvider.overrideWith((ref) => Stream.value(const [])),
          sourcesProvider.overrideWith((ref) => Stream.value(const [])),
          playerStateProvider.overrideWith(
            (ref) => Stream.value(PlayerState.empty),
          ),
          playerPositionProvider.overrideWith(
            (ref) => Stream.value(Duration.zero),
          ),
        ],
        child: const EchoesApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('abre na biblioteca com o título Echoes', (tester) async {
    await pumpApp(tester);
    expect(find.text(AppStrings.appName), findsOneWidget);
  });

  testWidgets('navega para Gerenciar biblioteca e volta', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel(AppStrings.manageLibrary));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.manageLibrary), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.appName), findsOneWidget);
  });

  testWidgets('navega para Configurações', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel(AppStrings.settings));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.settings), findsOneWidget);
  });

  testWidgets('abre o Player e dele os Capítulos', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text(AppStrings.openPlayer));
    await tester.pumpAndSettle();
    expect(find.byTooltip(AppStrings.closePlayer), findsOneWidget);

    await tester.tap(find.text(AppStrings.chapters));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.chaptersAndBookmarks), findsOneWidget);
  });
}
