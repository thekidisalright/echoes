import 'dart:typed_data';

import '../storage/storage_gateway.dart';

/// Imagem embutida num arquivo de áudio.
class EmbeddedPicture {
  const EmbeddedPicture({required this.bytes, required this.mimeType});

  final Uint8List bytes;

  /// Ex.: `image/jpeg`.
  final String mimeType;
}

/// Tags e duração de um arquivo de áudio. Campos ausentes ficam nulos.
class AudioFileMetadata {
  const AudioFileMetadata({
    this.title,
    this.album,
    this.artist,
    this.albumArtist,
    this.trackNumber,
    this.duration,
    this.picture,
  });

  final String? title;
  final String? album;
  final String? artist;
  final String? albumArtist;
  final int? trackNumber;
  final Duration? duration;
  final EmbeddedPicture? picture;
}

/// Lê metadados de arquivos de áudio.
abstract interface class MetadataReader {
  /// Lança [MetadataException] se o arquivo não puder ser lido.
  /// Com [includePicture] falso, a capa embutida não é extraída.
  Future<AudioFileMetadata> read(
    StorageEntry file, {
    bool includePicture = true,
  });
}

class MetadataException implements Exception {
  const MetadataException(this.message);

  final String message;

  @override
  String toString() => 'MetadataException: $message';
}
