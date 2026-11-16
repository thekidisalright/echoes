import 'package:echoes/app/strings.dart';
import 'package:echoes/app/theme/theme.dart';
import 'package:echoes/core/images/image_gateway.dart';
import 'package:echoes/core/providers.dart';
import 'package:echoes/features/library/domain/book.dart';
import 'package:echoes/features/library/presentation/widgets/book_cover.dart';
import 'package:echoes/features/library/presentation/widgets/book_edit_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeImageGateway implements ImageGateway {
  _FakeImageGateway(this.result);

  final String? result;
  int calls = 0;

  @override
  Future<String?> pickImage() async {
    calls++;
    return result;
  }
}

Book _book({String? customTitle}) => Book(
  id: 'b',
  sourceId: 's',
  scannedTitle: 'Original',
  scannedAuthor: 'Stephen King',
  customTitle: customTitle,
  chapterCount: 1,
  createdAt: DateTime(2026),
);

void main() {
  Future<_FakeImageGateway> pump(WidgetTester tester, Book book) async {
    final images = _FakeImageGateway('/tmp/nova.jpg');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [imageGatewayProvider.overrideWithValue(images)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: BookEditDialog(book: book)),
        ),
      ),
    );
    return images;
  }

  FilledButton saveButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Salvar'));

  testWidgets('preenche título e autor; salvar some com título vazio', (
    tester,
  ) async {
    await pump(tester, _book());
    expect(find.text(AppStrings.editBook), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Stephen King'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNotNull);

    await tester.enterText(find.widgetWithText(TextField, 'Original'), '  ');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('restaurar só aparece com dados editados', (tester) async {
    await pump(tester, _book());
    expect(find.text(AppStrings.restoreOriginal), findsNothing);

    await pump(tester, _book(customTitle: 'Editado'));
    expect(find.text(AppStrings.restoreOriginal), findsOneWidget);
  });

  testWidgets('alterar capa mostra a imagem escolhida', (tester) async {
    final images = await pump(tester, _book());
    await tester.tap(find.bySemanticsLabel(AppStrings.changeCover));
    await tester.pump();
    expect(images.calls, 1);
    final cover = tester.widget<BookCover>(find.byType(BookCover));
    expect(cover.path, '/tmp/nova.jpg');
  });
}
