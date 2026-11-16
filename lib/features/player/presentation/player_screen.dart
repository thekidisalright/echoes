import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/strings.dart';
import '../../../app/theme/typography.dart';

/// Player em tela cheia. Placeholder da Fase 1.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.closePlayer,
          icon: const Icon(Ionicons.chevronDown),
          onPressed: () => context.pop(),
        ),
        title: const Text(AppStrings.audiobookFallback),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppStrings.untitled, style: AppTypography.screenTitle),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.chapters),
              icon: const Icon(Ionicons.listOutline),
              label: const Text(AppStrings.chapters),
            ),
          ],
        ),
      ),
    );
  }
}
