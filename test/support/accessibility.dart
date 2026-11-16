import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Áreas de toque de pelo menos 44 × 44 (docs/PLAN.md, Fase 6).
const _minTapTarget = MinimumTapTargetGuideline(
  size: Size(44, 44),
  link: 'docs/PLAN.md',
);

/// Confere áreas de toque mínimas e rótulos em tudo que é tocável.
Future<void> expectAccessible(WidgetTester tester) async {
  final semantics = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(_minTapTarget));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  semantics.dispose();
}
