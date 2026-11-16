import 'package:echoes/app/theme/theme.dart';
import 'package:echoes/features/player/presentation/widgets/seek_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('arrastar só busca ao soltar; tempos acompanham o dedo', (
    tester,
  ) async {
    final seeks = <Duration>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SeekBar(
            position: const Duration(minutes: 1),
            duration: const Duration(minutes: 10),
            onSeek: seeks.add,
          ),
        ),
      ),
    );
    expect(find.text('01:00'), findsOneWidget);
    expect(find.text('-09:00'), findsOneWidget);

    final slider = find.byType(Slider);
    final gesture = await tester.startGesture(tester.getCenter(slider));
    await tester.pump();
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    expect(seeks, isEmpty);
    expect(find.text('01:00'), findsNothing);

    await gesture.up();
    await tester.pump();
    expect(seeks, hasLength(1));
    expect(seeks.single, greaterThan(const Duration(minutes: 4)));
  });

  testWidgets('sem duração a barra fica desativada', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SeekBar(
            position: Duration.zero,
            duration: null,
            onSeek: (_) => fail('não deveria buscar'),
          ),
        ),
      ),
    );
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
  });
}
