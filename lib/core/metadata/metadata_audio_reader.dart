import 'dart:typed_data';

import 'package:metadata_audio/metadata_audio.dart';

import '../storage/storage_gateway.dart';
import 'metadata_reader.dart';

/// [MetadataReader] com o pacote `metadata_audio`, lendo só os trechos
/// necessários do arquivo via [StorageGateway.readRange].
///
/// Começa com o cabeçalho e o final do arquivo; quando o parser pede bytes
/// que ainda não foram lidos, busca o trecho e tenta de novo. Detalhes em
/// "Registro de decisões" de docs/PLAN.md.
class MetadataAudioReader implements MetadataReader {
  MetadataAudioReader(this._storage);

  final StorageGateway _storage;

  static const _headSize = 128 * 1024;
  static const _tailSize = 8 * 1024;
  static const _minWindow = 256 * 1024;
  static const _maxAttempts = 10;

  @override
  Future<AudioFileMetadata> read(
    StorageEntry file, {
    bool includePicture = true,
  }) async {
    final source = _RangeSource(_storage, file);
    try {
      await source.ensure(0, _headSize);
      if (file.size > _headSize) {
        await source.ensure(file.size - _tailSize, _tailSize);
      }
      final metadata = await _parse(source, file, includePicture);
      return _convert(metadata, includePicture);
    } on StorageException {
      rethrow;
    } catch (e) {
      // Parsers podem lançar Error (RangeError etc.) com arquivos corrompidos.
      throw MetadataException('${file.name}: $e');
    }
  }

  Future<AudioMetadata> _parse(
    _RangeSource source,
    StorageEntry file,
    bool includePicture,
  ) async {
    final options = ParseOptions(skipCovers: !includePicture);
    final info = FileInfo(
      path: file.name,
      mimeType: file.mimeType,
      size: file.size,
    );
    var attempts = 0;
    while (true) {
      attempts++;
      final tokenizer = _SparseTokenizer(source, info);
      try {
        final metadata = await parseFromTokenizer(tokenizer, options: options);
        // Alguns parsers (ex.: MP4) engolem a falta de bytes e seguem com
        // dados incompletos; se houve falta, busca o trecho e tenta de novo.
        final miss = tokenizer.lastMiss;
        if (miss != null && attempts < _maxAttempts) {
          await source.ensure(miss.$1, _window(miss.$2));
          continue;
        }
        return metadata;
      } on TokenizerException {
        final miss = tokenizer.lastMiss;
        if (miss == null || attempts >= _maxAttempts) rethrow;
        await source.ensure(miss.$1, _window(miss.$2));
      }
    }
  }

  static int _window(int length) => length > _minWindow ? length : _minWindow;

  static AudioFileMetadata _convert(AudioMetadata m, bool includePicture) {
    final common = m.common;
    final seconds = m.format.duration;
    final picture = includePicture ? common.picture?.firstOrNull : null;
    return AudioFileMetadata(
      title: _clean(common.title),
      album: _clean(common.album),
      artist: _clean(common.artist),
      albumArtist: _clean(common.albumartist),
      trackNumber: common.track.no,
      duration: seconds == null || !seconds.isFinite || seconds <= 0
          ? null
          : Duration(milliseconds: (seconds * 1000).round()),
      picture: picture == null || picture.data.isEmpty
          ? null
          : EmbeddedPicture(
              bytes: Uint8List.fromList(picture.data),
              mimeType: picture.format,
            ),
    );
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

/// Trechos já lidos de um arquivo.
class _RangeSource {
  _RangeSource(this._storage, this.file);

  final StorageGateway _storage;
  final StorageEntry file;
  final List<(int, Uint8List)> _ranges = [];

  int get size => file.size;

  Future<void> ensure(int start, int length) async {
    final s = start.clamp(0, size);
    final e = (start + length).clamp(0, size);
    if (e <= s || _find(s, e - s) != null) return;
    _ranges.add((s, await _storage.readRange(file.uri, s, e - s)));
  }

  (int, Uint8List)? _find(int start, int length) {
    for (final r in _ranges) {
      if (start >= r.$1 && start + length <= r.$1 + r.$2.length) return r;
    }
    return null;
  }

  List<int>? read(int start, int length) {
    final r = _find(start, length);
    if (r == null) return null;
    final offset = start - r.$1;
    return Uint8List.sublistView(r.$2, offset, offset + length);
  }
}

/// Tokenizer com acesso aleatório sobre os trechos já lidos.
///
/// Estende [HttpBasedTokenizer] só para receber os pedidos de `prefetchRange`
/// que os parsers fazem (ex.: o MP4 pede o `moov` inteiro antes de lê-lo).
class _SparseTokenizer extends HttpBasedTokenizer {
  _SparseTokenizer(this._source, FileInfo fileInfo)
    : super(url: _source.file.uri, fileInfo: fileInfo);

  final _RangeSource _source;
  int _position = 0;

  /// Último trecho pedido que não estava carregado: (início, tamanho).
  (int, int)? lastMiss;

  @override
  void close() {}

  @override
  Future<void> prefetchRange(int start, int end) =>
      _source.ensure(start, end - start);

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
