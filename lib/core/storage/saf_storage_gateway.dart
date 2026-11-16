import 'package:docman/docman.dart';
import 'package:flutter/services.dart';

import 'storage_gateway.dart';

/// [StorageGateway] do Android.
///
/// Seletor e permissões persistidas via `docman`; listagem e leitura de
/// trechos via canal nativo próprio (`SafChannel.kt`), que é muito mais
/// rápido (ver "Registro de decisões" em docs/PLAN.md).
class SafStorageGateway implements StorageGateway {
  SafStorageGateway({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('dev.alexandre.echoes/saf');

  final MethodChannel _channel;

  static const _maxPickedFiles = 500;

  @override
  Future<PickedDirectory?> pickDirectory() async {
    final dir = await DocMan.pick.directory();
    if (dir == null) return null;
    return PickedDirectory(uri: dir.uri, name: dir.name);
  }

  @override
  Future<List<StorageEntry>> pickAudioFiles() async {
    final files = await DocMan.pick.documents(
      mimeTypes: const ['audio/*'],
      grantPermissions: true,
      limit: _maxPickedFiles,
    );
    return [
      for (final f in files)
        StorageEntry(
          uri: f.uri,
          name: f.name,
          mimeType: f.type,
          size: f.size,
          isDirectory: false,
        ),
    ];
  }

  @override
  Future<List<StorageEntry>> listTree(String treeUri) async {
    final raw = await _invoke(
      () => _channel.invokeListMethod<Map<Object?, Object?>>('listTree', {
        'uri': treeUri,
      }),
    );
    return [
      for (final m in raw ?? const <Map<Object?, Object?>>[])
        StorageEntry(
          uri: m['uri']! as String,
          parentUri: m['parentUri'] as String? ?? '',
          name: m['name'] as String? ?? '',
          mimeType: m['mimeType'] as String? ?? '',
          size: (m['size'] as num?)?.toInt() ?? 0,
          isDirectory: m['isDirectory']! as bool,
        ),
    ];
  }

  @override
  Future<Uint8List> readRange(String uri, int start, int length) async {
    final bytes = await _invoke(
      () => _channel.invokeMethod<Uint8List>('readRange', {
        'uri': uri,
        'start': start,
        'length': length,
      }),
    );
    return bytes ?? Uint8List(0);
  }

  @override
  Future<Set<String>> persistedUris() async {
    final perms = await DocMan.perms.list();
    return {
      for (final p in perms)
        if (p.read) p.uri,
    };
  }

  @override
  Future<void> releasePermission(String uri) async {
    try {
      await DocMan.perms.release(uri);
    } on PlatformException {
      // Sem permissão para liberar: nada a fazer.
    }
  }

  Future<T> _invoke<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      final message = e.message ?? e.code;
      if (e.code == 'permission') throw StoragePermissionException(message);
      throw StorageException(message);
    }
  }
}
