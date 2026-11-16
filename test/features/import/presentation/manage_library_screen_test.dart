import 'package:echoes/app/strings.dart';
import 'package:echoes/app/theme/theme.dart';
import 'package:echoes/features/import/presentation/manage_library_screen.dart';
import 'package:echoes/features/library/domain/library_source.dart';
import 'package:echoes/features/library/presentation/library_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final folder = LibrarySource(
    id: 'folder:1',
    uri: 'content://tree/1',
    name: 'Audiobooks',
    kind: SourceKind.folder,
    available: true,
    lastScannedAt: DateTime(2026),
    bookCount: 3,
  );
  final files = LibrarySource(
    id: 'files:1',
    uri: 'files:1',
    name: AppStrings.selectedFilesSourceName,
    kind: SourceKind.files,
    available: false,
    lastScannedAt: DateTime(2026),
    bookCount: 1,
  );

  Future<void> pump(
    WidgetTester tester,
    List<LibrarySource> sources, {
    String? notice,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sourcesProvider.overrideWith((ref) => Stream.value(sources)),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: ManageLibraryScreen(notice: notice),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sem origens mostra a mensagem de vazio', (tester) async {
    await pump(tester, const []);
    expect(find.text(AppStrings.sourcesEmpty), findsOneWidget);
    expect(find.text(AppStrings.addFolder), findsOneWidget);
    expect(find.text(AppStrings.addFiles), findsOneWidget);
  });

  testWidgets('lista origens; atualizar só aparece para pastas', (
    tester,
  ) async {
    await pump(tester, [folder, files]);
    expect(find.text('Audiobooks'), findsOneWidget);
    expect(
      find.text(AppStrings.sourceSummary(3, available: true)),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.sourceSummary(1, available: false)),
      findsOneWidget,
    );
    expect(find.byTooltip(AppStrings.refreshSource), findsOneWidget);
    expect(find.byTooltip(AppStrings.removeSource), findsNWidgets(2));
  });

  testWidgets('remover pede confirmação e cancelar mantém a origem', (
    tester,
  ) async {
    await pump(tester, [folder]);
    await tester.tap(find.byTooltip(AppStrings.removeSource));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.removeSourceTitle), findsOneWidget);
    expect(find.text(AppStrings.removeSourceMessage('Audiobooks')), findsOne);

    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.removeSourceTitle), findsNothing);
    expect(find.text('Audiobooks'), findsOneWidget);
  });

  testWidgets('mostra o aviso recebido pela rota', (tester) async {
    await pump(tester, const [], notice: AppStrings.sourceUnavailableHint);
    expect(find.text(AppStrings.sourceUnavailableHint), findsOneWidget);
  });
}
