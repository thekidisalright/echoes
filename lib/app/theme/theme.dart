import 'package:material_ui/material_ui.dart';

import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// `ThemeData` escuro do Echoes.
ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.accent,
    onPrimary: AppColors.background,
    primaryContainer: AppColors.accentFill,
    onPrimaryContainer: AppColors.onAccent,
    secondary: AppColors.accent,
    onSecondary: AppColors.background,
    surface: AppColors.background,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surfaceDialog,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.border,
    scrim: AppColors.scrim,
  );

  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.field),
    borderSide: BorderSide.none,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: AppTypography.display,
      headlineMedium: AppTypography.screenTitle,
      headlineSmall: AppTypography.sectionTitle,
      titleLarge: AppTypography.subsectionTitle,
      labelMedium: AppTypography.overline,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.bodySmall,
      bodySmall: AppTypography.caption,
    ),
    iconTheme: const IconThemeData(color: AppColors.textSecondary),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearTrackColor: AppColors.track,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: AppColors.track,
      thumbColor: AppColors.accent,
      trackHeight: 5,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.textPlaceholder),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceDialog,
      barrierColor: AppColors.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.dialog),
        side: const BorderSide(color: AppColors.borderStrong),
      ),
      titleTextStyle: AppTypography.sectionTitle,
      contentTextStyle: AppTypography.bodySmall,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceDialog,
      modalBarrierColor: AppColors.scrim,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accentFill,
        foregroundColor: AppColors.onAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: AppTypography.bodySmall,
    ),
  );
}
