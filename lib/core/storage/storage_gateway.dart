import 'dart:typed_data';

/// Arquivo ou pasta de uma árvore SAF.
class StorageEntry {
  const StorageEntry({
    required this.uri,
    required this.name,
    required this.isDirectory,
    this.parentUri = '',
    this.mimeType = '',
    this.size = 0,
  });

  final String uri;

  /// URI da pasta que contém a entrada; vazio para arquivos soltos.
  final String parentUri;
  final String name;
  final String mimeType;
  final int size;
  final bool isDirectory;
}

/// Pasta escolhida pelo usuário, já com permissão persistida.
class PickedDirectory {
  const PickedDirectory({required this.uri, required this.name});

  final String uri;
  final String name;
}

/// Acesso a arquivos do usuário (Storage Access Framework no Android).
abstract interface class StorageGateway {
  /// Abre o seletor de pasta e persiste a permissão. Nulo se cancelado.
  Future<PickedDirectory?> pickDirectory();

  /// Abre o seletor de arquivos de áudio (vários) e persiste as permissões.
  /// Lista vazia se cancelado.
  Future<List<StorageEntry>> pickAudioFiles();

  /// Lista recursivamente a árvore, sem incluir a raiz.
  ///
  /// Lança [StoragePermissionException] se a permissão não vale mais.
  Future<List<StorageEntry>> listTree(String treeUri);

  /// Lê até [length] bytes a partir de [start]; menos no fim do arquivo.
  Future<Uint8List> readRange(String uri, int start, int length);

  /// URIs (pastas e arquivos) com permissão persistida de leitura.
  Future<Set<String>> persistedUris();

  /// Libera a permissão persistida de [uri], se houver.
  Future<void> releasePermission(String uri);
}

/// Falha de acesso a um arquivo ou pasta.
class StorageException implements Exception {
  const StorageException(this.message);

  final String message;

  @override
  String toString() => 'StorageException: $message';
}

/// A permissão SAF expirou ou foi revogada.
class StoragePermissionException extends StorageException {
  const StoragePermissionException(super.message);

  @override
  String toString() => 'StoragePermissionException: $message';
}
