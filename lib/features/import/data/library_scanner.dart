import '../../../core/metadata/metadata_reader.dart';
import '../../../core/storage/storage_gateway.dart';
import '../../../core/utils/file_names.dart';
import '../../../core/utils/natural_sort.dart';
import '../domain/import_mode.dart';
import '../domain/import_progress.dart';
import '../domain/scanned_source.dart';

/// De onde vem a capa de um livro escaneado.
sealed class CoverCandidate {
  const CoverCandidate();
}

/// Imagem dentro da pasta do livro.
class FolderImageCover extends CoverCandidate {
  const FolderImageCover(this.image);

  final StorageEntry image;
}

/// Capa embutida num dos arquivos de áudio.
class EmbeddedCover extends CoverCandidate {
  const EmbeddedCover(this.picture);

  final EmbeddedPicture picture;
}

/// Livro escaneado, ainda sem a capa gravada no diretório do app.
class BookScan {
  const BookScan({required this.book, this.cover});

  /// Sempre com `coverPath` nulo.
  final ScannedBook book;
  final CoverCandidate? cover;
}

/// Percorre pastas e arquivos e os agrupa em livros (docs/FEATURES.md §1.3).
///
/// Não grava nada: devolve os livros e as candidatas a capa.
class LibraryScanner {
  LibraryScanner(this._storage, this._metadata);

  final StorageGateway _storage;
  final MetadataReader _metadata;

  /// Escaneia a árvore [rootUri].
  ///
  /// Em [ImportMode.oneBook] o livro único usa [sourceId] como id; em
  /// [ImportMode.booksInFolders] cada pasta com áudio vira um livro com o
  /// URI da pasta como id. Arquivos em [skipUris] são ignorados.
  Future<List<BookScan>> scanFolder({
    required String rootUri,
    required String rootName,
    required String sourceId,
    required ImportMode mode,
    Set<String> skipUris = const {},
    void Function(ImportProgress progress)? onProgress,
  }) async {
    final entries = await _storage.listTree(rootUri);
    final dirs = {
      for (final e in entries)
        if (e.isDirectory) e.uri: e,
    };
    final filesByDir = <String, List<StorageEntry>>{};
    for (final e in entries) {
      if (!e.isDirectory) (filesByDir[e.parentUri] ??= []).add(e);
    }

    final paths = {
      for (final dirUri in filesByDir.keys) dirUri: _pathOf(dirUri, dirs),
    };
    final orderedDirs = filesByDir.keys.toList()
      ..sort((a, b) => _comparePaths(paths[a]!, paths[b]!));

    List<StorageEntry> audioIn(String dirUri) =>
        filesByDir[dirUri]!
            .where((f) => isAudio(f.name) && !skipUris.contains(f.uri))
            .toList()
          ..sort((a, b) => compareTrackNames(a.name, b.name));
    List<StorageEntry> imagesIn(String dirUri) =>
        filesByDir[dirUri]!.where((f) => isImage(f.name)).toList()
          ..sort((a, b) => compareNatural(a.name, b.name));

    final groups = [
      for (final dirUri in orderedDirs)
        if (filesByDir[dirUri]!.any((f) => isAudio(f.name))) dirUri,
    ];

    if (mode == ImportMode.oneBook) {
      final audio = [for (final d in groups) ...audioIn(d)];
      if (audio.isEmpty) return const [];
      onProgress?.call(ImportReadingFiles(audio.length));
      final book = await _scanBook(
        id: sourceId,
        folderName: rootName,
        audio: audio,
        images: [for (final d in orderedDirs) ...imagesIn(d)],
      );
      return [book];
    }

    final books = <BookScan>[];
    for (final (index, dirUri) in groups.indexed) {
      onProgress?.call(ImportReadingFolder(index + 1, groups.length));
      final audio = audioIn(dirUri);
      if (audio.isEmpty) continue;
      books.add(
        await _scanBook(
          id: dirUri,
          folderName: dirs[dirUri]?.name ?? rootName,
          audio: audio,
          images: imagesIn(dirUri),
        ),
      );
    }
    return books;
  }

  /// Arquivos soltos viram um único livro com id [sourceId]. Nulo se nenhum
  /// arquivo é áudio fora de [skipUris].
  Future<BookScan?> scanFiles(
    List<StorageEntry> files, {
    required String sourceId,
    Set<String> skipUris = const {},
  }) async {
    final audio =
        files
            .where((f) => isAudio(f.name) && !skipUris.contains(f.uri))
            .toList()
          ..sort((a, b) => compareTrackNames(a.name, b.name));
    if (audio.isEmpty) return null;
    return _scanBook(id: sourceId, audio: audio, images: const []);
  }

  Future<BookScan> _scanBook({
    required String id,
    required List<StorageEntry> audio,
    required List<StorageEntry> images,
    String? folderName,
  }) async {
    final preferred = images.where((i) => isPreferredCover(i.name)).firstOrNull;
    EmbeddedPicture? embedded;
    final metadata = <AudioFileMetadata?>[];
    for (final file in audio) {
      final wantPicture = preferred == null && embedded == null;
      final m = await _read(file, includePicture: wantPicture);
      embedded ??= m?.picture;
      metadata.add(m);
    }

    final chapters = [
      for (final (index, file) in audio.indexed)
        ScannedChapter(
          id: file.uri,
          uri: file.uri,
          title: metadata[index]?.title ?? cleanTitle(file.name),
          trackNumber:
              metadata[index]?.trackNumber ?? parseTrackNumber(file.name),
          duration: metadata[index]?.duration,
        ),
    ];
    final tagged = metadata.nonNulls
        .where(
          (m) => m.album != null || m.artist != null || m.albumArtist != null,
        )
        .firstOrNull;
    final name = folderName?.trim();
    final title =
        tagged?.album ??
        (name == null || name.isEmpty ? cleanTitle(audio.first.name) : name);

    final CoverCandidate? cover = preferred != null
        ? FolderImageCover(preferred)
        : embedded != null
        ? EmbeddedCover(embedded)
        : images.isNotEmpty
        ? FolderImageCover(images.first)
        : null;

    return BookScan(
      book: ScannedBook(
        id: id,
        title: title,
        author: tagged?.albumArtist ?? tagged?.artist ?? '',
        chapters: chapters,
      ),
      cover: cover,
    );
  }

  /// Metadados ilegíveis não quebram a importação: o capítulo usa o nome do
  /// arquivo e fica sem duração. Só a perda de permissão interrompe.
  Future<AudioFileMetadata?> _read(
    StorageEntry file, {
    required bool includePicture,
  }) async {
    try {
      return await _metadata.read(file, includePicture: includePicture);
    } on StoragePermissionException {
      rethrow;
    } on StorageException {
      return null;
    } on MetadataException {
      return null;
    }
  }

  /// Nomes das pastas da raiz até [dirUri]; a raiz é a lista vazia.
  static List<String> _pathOf(String dirUri, Map<String, StorageEntry> dirs) {
    final names = <String>[];
    var current = dirs[dirUri];
    while (current != null) {
      names.insert(0, current.name);
      current = dirs[current.parentUri];
    }
    return names;
  }

  static int _comparePaths(List<String> a, List<String> b) {
    for (var i = 0; i < a.length && i < b.length; i++) {
      final cmp = compareNatural(a[i], b[i]);
      if (cmp != 0) return cmp;
    }
    return a.length.compareTo(b.length);
  }
}
