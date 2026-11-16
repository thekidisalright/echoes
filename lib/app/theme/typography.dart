import 'package:material_ui/material_ui.dart';

import 'colors.dart';

/// Estilos de texto (ver docs/UI.md → Tipografia).
abstract final class AppTypography {
  static const serif = 'CormorantGaramond';

  static const display = TextStyle(
    fontFamily: serif,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const screenTitle = TextStyle(
    fontFamily: serif,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const sectionTitle = TextStyle(
    fontFamily: serif,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
  );

  static const subsectionTitle = TextStyle(
    fontFamily: serif,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
  );

  /// Usar com o texto já em caixa alta.
  static const overline = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 2,
    color: AppColors.accent,
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
}
