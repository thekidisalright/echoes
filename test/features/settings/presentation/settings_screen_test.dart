import 'package:echoes/app/strings.dart';
import 'package:echoes/app/theme/colors.dart';
import 'package:echoes/app/theme/theme.dart';
import 'package:echoes/features/library/domain/sort_order.dart';
import 'package:echoes/features/settings/presentation/settings_providers.dart';
import 'package:echoes/features/settings/presentation/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/accessibility.dart';

void main() {
  testWidgets('marca a ordem salva e mostra a versão', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySortProvider.overrideWith(
            (ref) => Stream.value(SortOrder.title),
          ),
          appVersionProvider.overrideWith((ref) async => '1.0.0'),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.librarySortTitle), findsOneWidget);
    expect(find.text(AppStrings.appVersion('1.0.0')), findsOneWidget);

    final selected = tester.widget<Icon>(
      find.descendant(
        of: find.bySemanticsLabel(AppStrings.librarySortTitleOption),
        matching: find.byIcon(Ionicons.radioButtonOn),
      ),
    );
    expect(selected.color, AppColors.accent);
    expect(
      find.descendant(
        of: find.bySemanticsLabel(AppStrings.librarySortRecent),
        matching: find.byIcon(Ionicons.radioButtonOff),
      ),
      findsOneWidget,
    );
    await expectAccessible(tester);
  });
}
