import 'dart:typed_data';

import '../../../core/files/cover_store.dart';
import '../../../core/storage/storage_gateway.dart';
import '../../../core/utils/file_names.dart';
import '../../library/data/library_repository.dart';
import '../../library/domain/library_source.dart';
import '../domain/import_mode.dart';
import '../domain/import_progress.dart';
import '../domain/import_result.dart';
import '../domain/scanned_source.dart';
import 'library_scanner.dart';

typedef ProgressCallback = void Function(ImportProgress progress);

/// Orquestra seletor, escaneamento, capas e gravação no banco.
///
/// Não abre diálogos: devolve um [ImportResult] ou lança
/// [StorageException] / [StoragePermissionException].
class ImportService {
  ImportService({
    required this._storage,
    required this._scanner,
    required this._library,
    required this._covers,
    required this.filesSourceName,
    required this.fallbackFolderName,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final StorageGateway _storage;
  final LibraryScanner _scanner;
  final LibraryRepository _library;
  final CoverStore _covers;
  final DateTime Function() _clock;

  /// Nome da origem de arquivos soltos ("Arquivos selecionados").
  final String filesSourceName;

  /// Nome usado quando a pasta escolhida não tem nome.
  final String fallbackFolderName;

  /// Maior capa lida de uma pasta quando o tamanho é desconhecido.
  static const _maxCoverBytes = 20 * 1024 * 1024;

  /// Abre o seletor de pasta; a UI pergunta o modo e chama [importFolder].
  Future<PickedDirectory?> pickDirectory() => _storage.pickDirectory();

  Future<ImportResult> importFolder(
    PickedDirectory dir,
    ImportMode mode, {
    ProgressCallback? onProgress,
  }) async {
    onProgress?.call(const ImportPreparing());
    final existing = await _library.getSource(dir.uri);
    final scans = await _scanner.scanFolder(
      rootUri: dir.uri,
      rootName: dir.name,
      sourceId: dir.uri,
      mode: mode,
      skipUris: await _library.chapterUrisOutside(dir.uri),
      onProgress: onProgress,
    );
    if (scans.isEmpty && existing == null) {
      await _storage.releasePermission(dir.uri);
      return const ImportNothingNew();
    }
    onProgress?.call(const ImportSaving());
    await _save(
      ScannedSource(
        id: dir.uri,
        uri: dir.uri,
        name: dir.name.trim().isEmpty ? fallbackFolderName : dir.name,
        kind: SourceKind.folder,
        importMode: mode,
        books: await _withCovers(scans),
      ),
    );
    return scans.isEmpty
        ? const ImportNothingNew()
        : ImportCompleted(scans.length);
  }

  /// Abre o seletor de arquivos e importa os escolhidos como um livro.
  Future<ImportResult> importFiles({ProgressCallback? onProgress}) async {
    final picked = await _storage.pickAudioFiles();
    if (picked.isEmpty) return const ImportCancelled();

    final audio = picked.where((f) => isAudio(f.name)).toList();
    for (final f in picked.where((f) => !isAudio(f.name))) {
      await _storage.releasePermission(f.uri);
    }
    if (audio.isEmpty) return const ImportNoAudioSelected();

    final sourceId = 'files:${_clock().millisecondsSinceEpoch}';
    final skip = await _library.chapterUrisOutside(null);
    // Permissões de arquivos que já estão na biblioteca continuam valendo
    // para a origem antiga; não são liberadas.
    if (audio.every((f) => skip.contains(f.uri))) {
      return const ImportFilesAlreadyAdded();
    }

    onProgress?.call(
      ImportReadingFiles(audio.where((f) => !skip.contains(f.uri)).length),
    );
    final scan = await _scanner.scanFiles(
      audio,
      sourceId: sourceId,
      skipUris: skip,
    );
    if (scan == null) return const ImportFilesAlreadyAdded();

    onProgress?.call(const ImportSaving());
    await _save(
      ScannedSource(
        id: sourceId,
        uri: sourceId,
        name: filesSourceName,
        kind: SourceKind.files,
        books: await _withCovers([scan]),
      ),
    );
    return const ImportCompleted(1);
  }

  /// Reescaneia uma origem de pasta com o modo salvo.
  ///
  /// Sem permissão, marca a origem como indisponível e lança
  /// [StoragePermissionException].
  Future<ImportResult> rescan(
    LibrarySource source, {
    ProgressCallback? onProgress,
  }) async {
    if (source.kind != SourceKind.folder) {
      throw ArgumentError.value(source.id, 'source', 'não é uma pasta');
    }
    onProgress?.call(const ImportPreparing());
    try {
      if (!(await _storage.persistedUris()).contains(source.uri)) {
        throw const StoragePermissionException('permissão expirada');
      }
      final mode = source.importMode ?? ImportMode.booksInFolders;
      final scans = await _scanner.scanFolder(
        rootUri: source.uri,
        rootName: source.name,
        sourceId: source.id,
        mode: mode,
        skipUris: await _library.chapterUrisOutside(source.id),
        onProgress: onProgress,
      );
      onProgress?.call(const ImportSaving());
      await _save(
        ScannedSource(
          id: source.id,
          uri: source.uri,
          name: source.name,
          kind: SourceKind.folder,
          importMode: mode,
          books: await _withCovers(scans),
        ),
      );
      return scans.isEmpty
          ? const ImportNothingNew()
          : ImportCompleted(scans.length);
    } on StoragePermissionException {
      await _library.setSourceAvailability(source.id, available: false);
      rethrow;
    }
  }

  /// Remove a origem, libera as permissões e apaga as capas órfãs.
  Future<void> remove(LibrarySource source) async {
    final uris = source.kind == SourceKind.folder
        ? {source.uri}
        : await _library.chapterUrisOf(source.id);
    await _library.removeSource(source.id);
    for (final uri in uris) {
      await _storage.releasePermission(uri);
    }
    await _covers.deleteOrphans(await _library.coverPathsInUse());
  }

  /// Compara as origens com as permissões persistidas e marca
  /// `available`. Origem de arquivos fica disponível se todos os arquivos
  /// ainda têm permissão.
  Future<void> refreshAvailability() async {
    final granted = await _storage.persistedUris();
    for (final source in await _library.watchSources().first) {
      final bool available;
      if (source.kind == SourceKind.folder) {
        available = granted.contains(source.uri);
      } else {
        available = (await _library.chapterUrisOf(source.id))
            .every(granted.contains);
      }
      if (available != source.available) {
        await _library.setSourceAvailability(source.id, available: available);
      }
    }
  }

  Future<void> _save(ScannedSource source) async {
    await _library.saveScannedSource(source);
    await _covers.deleteOrphans(await _library.coverPathsInUse());
  }

  Future<List<ScannedBook>> _withCovers(List<BookScan> scans) async => [
    for (final scan in scans) scan.book.withCover(await _saveCover(scan)),
  ];

  /// Capa ilegível não impede a importação: o livro fica sem capa.
  Future<String?> _saveCover(BookScan scan) async {
    final bookId = scan.book.id;
    try {
      switch (scan.cover) {
        case null:
          return null;
        case EmbeddedCover(:final picture):
          return await _covers.saveScanned(
            bookId,
            picture.bytes,
            _extensionForMime(picture.mimeType),
          );
        case FolderImageCover(:final image):
          final Uint8List bytes = await _storage.readRange(
            image.uri,
            0,
            image.size > 0 ? image.size : _maxCoverBytes,
          );
          if (bytes.isEmpty) return null;
          final dot = image.name.lastIndexOf('.');
          return await _covers.saveScanned(
            bookId,
            bytes,
            dot < 0 ? 'jpg' : image.name.substring(dot + 1),
          );
      }
    } on StoragePermissionException {
      rethrow;
    } on StorageException {
      return null;
    }
  }

  static String _extensionForMime(String mime) => switch (mime.toLowerCase()) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    _ => 'jpg',
  };
}
