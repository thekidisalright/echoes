import 'dart:ui';

/// Tokens de cor do Echoes (ver docs/UI.md). Tema único escuro.
abstract final class AppColors {
  static const background = Color(0xFF171614);
  static const surface = Color(0xFF24221E);
  static const surfaceAlt = Color(0xFF262521);
  static const surfaceDialog = Color(0xFF201F1B);
  static const coverPlaceholder = Color(0xFF292720);
  static const border = Color(0xFF393833);
  static const borderStrong = Color(0xFF46443E);
  static const borderAccent = Color(0xFF514731);
  static const textPrimary = Color(0xFFD5D4CF);
  static const textHeading = Color(0xFFC9C8C2);
  static const textSecondary = Color(0xFFAAA9A3);
  static const textMuted = Color(0xFF85857F);
  static const textPlaceholder = Color(0xFF8E8E87);
  static const accent = Color(0xFFD1AA65);
  static const accentFill = Color(0xFF80683F);
  static const onAccent = Color(0xFFF0EEE7);
  static const iconOnDark = Color(0xFFFAFAFA);
  static const track = Color(0xFF3A3935);

  /// Fundo de botão destrutivo ("Remover").
  static const danger = Color(0xFF8C3F35);

  /// `#0A0A0A` a 85%.
  static const miniPlayerBg = Color(0xD90A0A0A);

  /// `#404040` a 50%, borda do MiniPlayer.
  static const miniPlayerBorder = Color(0x80404040);

  /// Preto a 60%, sombra do MiniPlayer.
  static const shadow = Color(0x99000000);

  /// Preto a 75%, fundo atrás de diálogos.
  static const scrim = Color(0xBF000000);
}
