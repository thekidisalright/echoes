import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

/// Arquivos de capa em `<appSupport>/covers/`.
///
/// Capa escaneada: `sha1(bookId).<ext>`. Capa do usuário:
/// `custom_<sha1(bookId)>_<epochMs>.<ext>` (o timestamp invalida o cache de
/// imagem). Ao trocar uma capa, o arquivo anterior é apagado.
class CoverStore {
  CoverStore(this._directory, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Diretório padrão do app.
  factory CoverStore.appSupport() => CoverStore(() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}${Platform.pathSeparator}covers');
  });

  final Future<Directory> Function() _directory;
  final DateTime Function() _clock;

  /// Grava a capa extraída na importação e devolve o caminho.
  Future<String> saveScanned(
    String bookId,
    Uint8List bytes,
    String extension,
  ) async {
    final dir = await _dir();
    final key = _key(bookId);
    final name = '$key.${_normalizeExtension(extension)}';
    final file = File(_join(dir, name));
    await file.writeAsBytes(bytes, flush: true);
    await _deleteWhere(dir, (n) => n.startsWith('$key.') && n != name);
    return file.path;
  }

  /// Copia a imagem escolhida pelo usuário e devolve o novo caminho.
  Future<String> saveCustom(String bookId, String sourcePath) async {
    final dir = await _dir();
    final prefix = _customPrefix(bookId);
    final dot = sourcePath.lastIndexOf('.');
    final extension = dot < 0 ? 'jpg' : sourcePath.substring(dot + 1);
    final name =
        '$prefix${_clock().millisecondsSinceEpoch}.'
        '${_normalizeExtension(extension)}';
    final copy = await File(sourcePath).copy(_join(dir, name));
    await _deleteWhere(dir, (n) => n.startsWith(prefix) && n != name);
    return copy.path;
  }

  /// Apaga a capa escolhida pelo usuário para o livro.
  Future<void> removeCustom(String bookId) async {
    final prefix = _customPrefix(bookId);
    await _deleteWhere(await _dir(), (n) => n.startsWith(prefix));
  }

  /// Apaga as capas que não estão em [pathsInUse] e devolve quantas apagou.
  Future<int> deleteOrphans(Set<String> pathsInUse) async {
    final keep = {for (final p in pathsInUse) File(p).absolute.path};
    var deleted = 0;
    await for (final entity in (await _dir()).list()) {
      if (entity is File && !keep.contains(entity.absolute.path)) {
        await entity.delete();
        deleted++;
      }
    }
    return deleted;
  }

  Future<Directory> _dir() async {
    final dir = await _directory();
    return dir.create(recursive: true);
  }

  Future<void> _deleteWhere(Directory dir, bool Function(String) test) async {
    await for (final entity in dir.list()) {
      if (entity is File && test(_basename(entity.path))) {
        await entity.delete();
      }
    }
  }

  static String _key(String bookId) =>
      sha1.convert(utf8.encode(bookId)).toString();

  static String _customPrefix(String bookId) => 'custom_${_key(bookId)}_';

  static String _normalizeExtension(String extension) {
    final ext = extension.replaceFirst(RegExp(r'^\.'), '').toLowerCase();
    return ext == 'jpeg' ? 'jpg' : ext;
  }

  static String _join(Directory dir, String name) =>
      '${dir.path}${Platform.pathSeparator}$name';

  static String _basename(String path) =>
      path.substring(path.lastIndexOf(Platform.pathSeparator) + 1);
}
