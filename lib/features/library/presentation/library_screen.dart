import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/strings.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';

/// Tela inicial. Placeholder da Fase 1: cabeçalho e navegação.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = AppSpacing.screenPaddingFor(
      MediaQuery.sizeOf(context).width,
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      AppStrings.appName,
                      style: AppTypography.display,
                    ),
                  ),
                  _HeaderButton(
                    icon: Ionicons.libraryOutline,
                    label: AppStrings.manageLibrary,
                    onPressed: () => context.push(AppRoutes.manage),
                  ),
                  const SizedBox(width: 10),
                  _HeaderButton(
                    icon: Ionicons.settingsOutline,
                    label: AppStrings.settings,
                    onPressed: () => context.push(AppRoutes.settings),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(AppStrings.library, style: AppTypography.sectionTitle),
              const SizedBox(height: 16),
              // Temporário (Fase 1): acesso ao Player até existir o MiniPlayer.
              FilledButton(
                onPressed: () => context.push(AppRoutes.player),
                child: const Text(AppStrings.openPlayer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox.square(
        dimension: AppSpacing.headerIconButton,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: const BorderSide(color: AppColors.borderStrong),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.field),
            ),
          ),
          child: Icon(
            icon,
            size: AppSpacing.headerIcon,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}
