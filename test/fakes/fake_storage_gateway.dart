import 'dart:typed_data';

import 'package:echoes/core/storage/storage_gateway.dart';

/// Árvore de arquivos em memória.
///
/// Monte com [addFile] usando caminhos relativos à raiz
/// (`'CD 1/01 - Início.mp3'`); as pastas intermediárias são criadas sozinhas.
/// URIs: `<raiz>/<caminho>`.
class FakeStorageGateway implements StorageGateway {
  final Map<String, List<StorageEntry>> _trees = {};
  final Map<String, Uint8List> _bytes = {};

  /// URIs com permissão persistida.
  final Set<String> permissions = {};
  final List<String> released = [];

  PickedDirectory? nextDirectory;
  List<StorageEntry> nextFiles = const [];

  /// URIs cuja leitura falha com [StorageException].
  final Set<String> unreadable = {};
  int listTreeCalls = 0;

  String addFile(String root, String path, {List<int> bytes = const [0]}) {
    final tree = _trees.putIfAbsent(root, () => []);
    final parts = path.split('/');
    var parent = root;
    for (final dir in parts.take(parts.length - 1)) {
      final uri = '$parent/$dir';
      if (!tree.any((e) => e.uri == uri)) {
        tree.add(
          StorageEntry(
            uri: uri,
            parentUri: parent,
            name: dir,
            isDirectory: true,
          ),
        );
      }
      parent = uri;
    }
    final uri = '$parent/${parts.last}';
    tree.add(
      StorageEntry(
        uri: uri,
        parentUri: parent,
        name: parts.last,
        size: bytes.length,
        isDirectory: false,
      ),
    );
    _bytes[uri] = Uint8List.fromList(bytes);
    return uri;
  }

  void removeFile(String root, String uri) =>
      _trees[root]!.removeWhere((e) => e.uri == uri);

  StorageEntry entry(String root, String uri) =>
      _trees[root]!.firstWhere((e) => e.uri == uri);

  StorageEntry looseFile(String uri, {List<int> bytes = const [0]}) {
    _bytes[uri] = Uint8List.fromList(bytes);
    return StorageEntry(
      uri: uri,
      name: uri.split('/').last,
      size: bytes.length,
      isDirectory: false,
    );
  }

  @override
  Future<PickedDirectory?> pickDirectory() async {
    final dir = nextDirectory;
    if (dir != null) permissions.add(dir.uri);
    return dir;
  }

  @override
  Future<List<StorageEntry>> pickAudioFiles() async {
    permissions.addAll(nextFiles.map((f) => f.uri));
    return nextFiles;
  }

  @override
  Future<List<StorageEntry>> listTree(String treeUri) async {
    listTreeCalls++;
    if (!permissions.contains(treeUri)) {
      throw const StoragePermissionException('sem permissão');
    }
    return List.of(_trees[treeUri] ?? const []);
  }

  @override
  Future<Uint8List> readRange(String uri, int start, int length) async {
    if (unreadable.contains(uri)) throw const StorageException('falhou');
    final bytes = _bytes[uri];
    if (bytes == null) throw const StorageException('não existe');
    final end = (start + length).clamp(0, bytes.length);
    return Uint8List.sublistView(bytes, start.clamp(0, end), end);
  }

  @override
  Future<Set<String>> persistedUris() async => Set.of(permissions);

  @override
  Future<void> releasePermission(String uri) async {
    released.add(uri);
    permissions.remove(uri);
  }
}
