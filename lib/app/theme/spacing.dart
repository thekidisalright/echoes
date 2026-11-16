/// Espaçamentos e raios (ver docs/UI.md → Forma e espaçamento).
abstract final class AppSpacing {
  static const screenPadding = 20.0;
  static const screenPaddingWide = 36.0;

  /// Largura a partir da qual o padding de tela passa a ser [screenPaddingWide].
  static const wideBreakpoint = 700.0;

  static double screenPaddingFor(double width) =>
      width > wideBreakpoint ? screenPaddingWide : screenPadding;

  static const headerIconButton = 44.0;
  static const headerIcon = 20.0;
  static const dialogPadding = 20.0;
}

abstract final class AppRadii {
  static const cover = 12.0;
  static const coverSmall = 6.0;
  static const field = 12.0;
  static const chip = 999.0;
  static const dialog = 16.0;
  static const miniPlayer = 16.0;
  static const banner = 8.0;
}
