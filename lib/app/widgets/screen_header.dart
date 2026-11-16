import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../strings.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Cabeçalho das telas secundárias: voltar, título e subtítulo opcional.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return Row(
      children: [
        IconButton(
          tooltip: AppStrings.back,
          icon: const Icon(
            Ionicons.arrowBack,
            size: AppSpacing.backIcon,
            color: AppColors.textSecondary,
          ),
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.screenTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(subtitle, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
