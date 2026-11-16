// SPIKE — código descartável (Fase 0). Será removido no fim da fase.
import 'dart:typed_data';

import 'package:metadata_audio/metadata_audio.dart';

import 'saf_native.dart';

/// Lê metadados de um arquivo SAF sem carregar o arquivo inteiro:
/// busca cabeçalho + final e, se o parser pedir bytes fora do que já foi
/// lido, busca a janela que faltou e tenta de novo.
Future<SafMetadataResult> readSafMetadata(SafNode file) async {
  final tokenizerSource = SafRangeSource(file);
  const headSize = 512 * 1024;
  const tailSize = 256 * 1024;
  await tokenizerSource.ensure(0, headSize);
  if (file.size > headSize) {
    await tokenizerSource.ensure(file.size - tailSize, tailSize);
  }

  var attempts = 0;
  while (true) {
    attempts++;
    final tokenizer = SparseTokenizer(
      tokenizerSource,
      FileInfo(path: file.name, mimeType: file.mimeType, size: file.size),
    );
    try {
      final metadata = await parseFromTokenizer(tokenizer);
      return SafMetadataResult(
        metadata: metadata,
        attempts: attempts,
        bytesRead: tokenizerSource.bytesLoaded,
      );
    } on TokenizerException {
      final miss = tokenizer.lastMiss;
      if (miss == null || attempts >= 10) rethrow;
      final windowSize = miss.$2 > 512 * 1024 ? miss.$2 : 512 * 1024;
      await tokenizerSource.ensure(miss.$1, windowSize);
    }
  }
}

class SafMetadataResult {
  SafMetadataResult({
    required this.metadata,
    required this.attempts,
    required this.bytesRead,
  });

  final AudioMetadata metadata;
  final int attempts;
  final int bytesRead;
}

class SafRangeSource {
  SafRangeSource(this.file);

  final SafNode file;
  final List<(int, Uint8List)> ranges = [];

  int get size => file.size;
  int get bytesLoaded => ranges.fold(0, (sum, r) => sum + r.$2.length);

  Future<void> ensure(int start, int length) async {
    final s = start.clamp(0, size);
    final e = (start + length).clamp(0, size);
    if (e <= s || _covers(s, e - s)) return;
    ranges.add((s, await readRange(file.uri, s, e - s)));
  }

  bool _covers(int start, int length) => _find(start, length) != null;

  (int, Uint8List)? _find(int start, int length) {
    for (final r in ranges) {
      if (start >= r.$1 && start + length <= r.$1 + r.$2.length) return r;
    }
    return null;
  }

  List<int>? read(int start, int length) {
    final r = _find(start, length);
    if (r == null) return null;
    final offset = start - r.$1;
    return r.$2.sublist(offset, offset + length);
  }
}

/// Tokenizer com acesso aleatório sobre os trechos já lidos de um arquivo SAF.
class SparseTokenizer extends Tokenizer {
  SparseTokenizer(this._source, this.fileInfo);

  final SafRangeSource _source;
  int _position = 0;

  /// Último trecho pedido que não estava carregado: (início, tamanho).
  (int, int)? lastMiss;

  @override
  final FileInfo? fileInfo;

  @override
  bool get canSeek => true;

  @override
  bool get hasCompleteData => false;

  @override
  int get position => _position;

  List<int> _get(int length, {required bool advance}) {
    if (_position + length > _source.size) {
      throw TokenizerException('Fim do arquivo em $_position (+$length)');
    }
    final bytes = _source.read(_position, length);
    if (bytes == null) {
      lastMiss = (_position, length);
      throw TokenizerException('Trecho não carregado: $_position (+$length)');
    }
    if (advance) _position += length;
    return bytes;
  }

  @override
  int readUint8() => _get(1, advance: true)[0];

  @override
  int readUint16() {
    final b = _get(2, advance: true);
    return (b[0] << 8) | b[1];
  }

  @override
  int readUint32() {
    final b = _get(4, advance: true);
    return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3];
  }

  @override
  List<int> readBytes(int length) => _get(length, advance: true);

  @override
  int peekUint8() => _get(1, advance: false)[0];

  @override
  List<int> peekBytes(int length) => _get(length, advance: false);

  @override
  void skip(int length) {
    if (_position + length > _source.size) {
      throw TokenizerException('Não é possível pular $length em $_position');
    }
    _position += length;
  }

  @override
  void seek(int position) {
    if (position < 0 || position > _source.size) {
      throw TokenizerException('Posição inválida: $position');
    }
    _position = position;
  }
}
