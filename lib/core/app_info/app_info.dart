/// Dados do pacote instalado.
abstract interface class AppInfo {
  /// Versão exibida ("1.0.0").
  Future<String> version();
}
