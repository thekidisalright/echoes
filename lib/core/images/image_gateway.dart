/// Escolha de imagem do aparelho (capa personalizada).
abstract interface class ImageGateway {
  /// Abre o seletor de imagens do sistema e devolve o caminho de uma cópia
  /// local da imagem escolhida, ou nulo se o usuário cancelou.
  Future<String?> pickImage();
}
