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

  // Escala geral.
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Margem do topo das telas, abaixo da área segura.
  static const screenTop = 18.0;

  /// Espaço no fim das listas.
  static const listBottom = 40.0;

  // Ícones.
  static const backIcon = 23.0;
  static const listIcon = 22.0;
  static const actionIcon = 20.0;
  static const statusIcon = 18.0;
  static const emptyStateIcon = 42.0;

  /// Quadrado do ícone de origem em Gerenciar biblioteca.
  static const sourceIconBox = 44.0;

  /// Espaço reservado no fim das listas quando o MiniPlayer aparece.
  static const miniPlayerClearance = 96.0;

  /// Área mínima de toque.
  static const minTouch = 44.0;

  /// Barras de progresso finas.
  static const progressBar = 4.0;
  static const miniProgressBar = 2.0;
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
