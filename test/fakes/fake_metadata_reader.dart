import 'dart:typed_data';

import 'package:echoes/core/metadata/metadata_reader.dart';
import 'package:echoes/core/storage/storage_gateway.dart';

/// Metadados configurados por URI; arquivos sem entrada não têm tags.
class FakeMetadataReader implements MetadataReader {
  final Map<String, AudioFileMetadata> byUri = {};

  /// URIs cuja leitura falha com [MetadataException].
  final Set<String> broken = {};

  /// URIs lidos, com o pedido de capa: (uri, includePicture).
  final List<(String, bool)> reads = [];

  @override
  Future<AudioFileMetadata> read(
    StorageEntry file, {
    bool includePicture = true,
  }) async {
    reads.add((file.uri, includePicture));
    if (broken.contains(file.uri)) {
      throw MetadataException('ilegível: ${file.uri}');
    }
    final m = byUri[file.uri] ?? const AudioFileMetadata();
    if (includePicture) return m;
    return AudioFileMetadata(
      title: m.title,
      album: m.album,
      artist: m.artist,
      albumArtist: m.albumArtist,
      trackNumber: m.trackNumber,
      duration: m.duration,
    );
  }
}

EmbeddedPicture picture(List<int> bytes, [String mime = 'image/jpeg']) =>
    EmbeddedPicture(bytes: Uint8List.fromList(bytes), mimeType: mime);
