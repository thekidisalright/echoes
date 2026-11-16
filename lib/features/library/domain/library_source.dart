import '../../import/domain/import_mode.dart';

enum SourceKind { folder, files }

/// Origem importada (pasta ou conjunto de arquivos soltos).
class LibrarySource {
  const LibrarySource({
    required this.id,
    required this.uri,
    required this.name,
    required this.kind,
    required this.available,
    required this.lastScannedAt,
    required this.bookCount,
    this.importMode,
  });

  final String id;
  final String uri;
  final String name;
  final SourceKind kind;

  /// Só para [SourceKind.folder].
  final ImportMode? importMode;

  /// A permissão SAF ainda é válida.
  final bool available;
  final DateTime lastScannedAt;
  final int bookCount;
}
