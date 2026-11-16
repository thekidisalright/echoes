// SPIKE — código descartável (Fase 0). Será removido no fim da fase.
import 'package:flutter/services.dart';

const _channel = MethodChannel('dev.alexandre.echoes/saf');

class SafNode {
  SafNode({
    required this.uri,
    required this.parentUri,
    required this.name,
    required this.mimeType,
    required this.size,
    required this.isDirectory,
  });

  factory SafNode.fromMap(Map<Object?, Object?> m) => SafNode(
    uri: m['uri']! as String,
    parentUri: m['parentUri']! as String,
    name: m['name'] as String? ?? '',
    mimeType: m['mimeType'] as String? ?? '',
    size: (m['size'] as num?)?.toInt() ?? 0,
    isDirectory: m['isDirectory']! as bool,
  );

  final String uri;
  final String parentUri;
  final String name;
  final String mimeType;
  final int size;
  final bool isDirectory;
}

Future<List<SafNode>> listTree(String treeUri) async {
  final raw = await _channel.invokeListMethod<Map<Object?, Object?>>(
    'listTree',
    {'uri': treeUri},
  );
  return [
    for (final m in raw ?? const <Map<Object?, Object?>>[]) SafNode.fromMap(m),
  ];
}

Future<Uint8List> readRange(String uri, int start, int length) async {
  final bytes = await _channel.invokeMethod<Uint8List>('readRange', {
    'uri': uri,
    'start': start,
    'length': length,
  });
  return bytes ?? Uint8List(0);
}
