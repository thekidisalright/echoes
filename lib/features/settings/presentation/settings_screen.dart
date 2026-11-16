import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme/typography.dart';

/// Configurações. Placeholder da Fase 1.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          icon: const Icon(Ionicons.arrowBack),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          AppStrings.settings,
          style: AppTypography.sectionTitle,
        ),
      ),
    );
  }
}
