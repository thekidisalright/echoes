import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/natural_sort.dart';
import '../../import/domain/import_mode.dart';
import '../../import/domain/scanned_source.dart';
import '../domain/book.dart';
import '../domain/book_summary.dart';
import '../domain/chapter.dart';
import '../domain/library_source.dart';
import '../domain/sort_order.dart';

/// Origens, livros e capítulos. Regras de persistência em docs/DATA_MODEL.md.
class LibraryRepository {
  LibraryRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// Salva o resultado de um escaneamento numa única transação.
  ///
  /// Atualiza só os campos `scanned*` dos livros (edições do usuário,
  /// `lastPlayedAt` e `createdAt` são preservados), remove livros e capítulos
  /// que não vieram no escaneamento e reposiciona no primeiro capítulo o
  /// progresso que apontava para um capítulo removido. Marcadores de
  /// capítulos removidos são apagados.
  Future<void> saveScannedSource(ScannedSource source) {
    final now = _clock().millisecondsSinceEpoch;
    return _db.transaction(() async {
      await _db
          .into(_db.sources)
          .insertOnConflictUpdate(
            SourcesCompanion.insert(
              id: source.id,
              uri: source.uri,
              name: source.name,
              kind: source.kind.name,
              importMode: Value(source.importMode?.name),
              available: const Value(true),
              lastScannedAt: now,
            ),
          );

      for (final book in source.books) {
        final scanned = BooksCompanion(
          sourceId: Value(source.id),
          scannedTitle: Value(book.title),
          scannedAuthor: Value(book.author),
          scannedCoverPath: Value(book.coverPath),
          totalDurationMs: Value(book.totalDuration?.inMilliseconds),
          chapterCount: Value(book.chapters.length),
        );
        await _db
            .into(_db.books)
            .insert(
              scanned.copyWith(id: Value(book.id), createdAt: Value(now)),
              onConflict: DoUpdate((_) => scanned),
            );

        final chapterIds = [for (final c in book.chapters) c.id];
        await (_db.delete(_db.chapters)..where(
              (c) => c.bookId.equals(book.id) & c.id.isNotIn(chapterIds),
            ))
            .go();
        await _db.batch((batch) {
          batch.insertAllOnConflictUpdate(_db.chapters, [
            for (final (index, chapter) in book.chapters.indexed)
              ChaptersCompanion.insert(
                id: chapter.id,
                bookId: book.id,
                title: chapter.title,
                uri: chapter.uri,
                sortOrder: index,
                trackNumber: Value(chapter.trackNumber),
                durationMs: Value(chapter.duration?.inMilliseconds),
              ),
          ]);
        });
      }

      final bookIds = [for (final b in source.books) b.id];
      await (_db.delete(
            _db.books,
          )..where((b) => b.sourceId.equals(source.id) & b.id.isNotIn(bookIds)))
          .go();

      await _db.customUpdate(
        'UPDATE progress SET '
        'chapter_id = (SELECT c.id FROM chapters c '
        'WHERE c.book_id = progress.book_id ORDER BY c.sort_order LIMIT 1), '
        'position_ms = 0, updated_at = ? '
        'WHERE book_id IN (SELECT id FROM books WHERE source_id = ?) '
        'AND chapter_id NOT IN (SELECT c.id FROM chapters c '
        'WHERE c.book_id = progress.book_id)',
        variables: [Variable.withInt(now), Variable.withString(source.id)],
        updates: {_db.progressEntries},
        updateKind: UpdateKind.update,
      );
      await _db.customUpdate(
        'DELETE FROM bookmarks '
        'WHERE book_id IN (SELECT id FROM books WHERE source_id = ?) '
        'AND chapter_id NOT IN (SELECT c.id FROM chapters c '
        'WHERE c.book_id = bookmarks.book_id)',
        variables: [Variable.withString(source.id)],
        updates: {_db.bookmarks},
        updateKind: UpdateKind.delete,
      );
    });
  }

  /// Remove a origem; livros, capítulos, progresso e marcadores vão junto.
  Future<void> removeSource(String sourceId) =>
      (_db.delete(_db.sources)..where((s) => s.id.equals(sourceId))).go();

  /// Marca as origens cujas permissões SAF ainda valem.
  Future<void> setSourceAvailability(
    String sourceId, {
    required bool available,
  }) => (_db.update(_db.sources)..where((s) => s.id.equals(sourceId))).write(
    SourcesCompanion(available: Value(available)),
  );

  /// Grava a edição do usuário. [coverPath] nulo mantém a capa atual.
  Future<void> updateBookDetails(
    String bookId, {
    required String title,
    required String author,
    String? coverPath,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(title, 'title', 'não pode ser vazio');
    }
    return (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
      BooksCompanion(
        customTitle: Value(trimmed),
        customAuthor: Value(author.trim()),
        customCoverPath: coverPath == null
            ? const Value.absent()
            : Value(coverPath),
      ),
    );
  }

  /// Volta a exibir os dados da importação.
  Future<void> resetBookDetails(String bookId) =>
      (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
        const BooksCompanion(
          customTitle: Value(null),
          customAuthor: Value(null),
          customCoverPath: Value(null),
        ),
      );

  /// Grade da biblioteca, filtrada por título/autor exibidos.
  Stream<List<BookSummary>> watchLibrary({
    String query = '',
    SortOrder sort = SortOrder.recent,
  }) {
    final needle = query.trim().toLowerCase();
    return _watchSummaries().map((summaries) {
      final visible = needle.isEmpty
          ? summaries
          : summaries
                .where(
                  (s) => '${s.book.title} ${s.book.author}'
                      .toLowerCase()
                      .contains(needle),
                )
                .toList();
      return visible..sort(switch (sort) {
        SortOrder.recent => _compareRecent,
        SortOrder.title => _compareTitle,
      });
    });
  }

  /// Até 3 livros já tocados, mais recentes primeiro.
  Stream<List<BookSummary>> watchContinueListening() => _watchSummaries(
    where: 'WHERE b.last_played_at IS NOT NULL',
    orderBy: 'ORDER BY b.last_played_at DESC LIMIT 3',
  );

  /// Origens com a contagem de livros, por nome.
  Stream<List<LibrarySource>> watchSources() {
    return _db
        .customSelect(
          'SELECT s.*, (SELECT COUNT(*) FROM books b '
          'WHERE b.source_id = s.id) AS book_count FROM sources s',
          readsFrom: {_db.sources, _db.books},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              _toSource(_db.sources.map(row.data), row.read<int>('book_count')),
          ]..sort((a, b) => compareNatural(a.name, b.name)),
        );
  }

  Future<LibrarySource?> getSource(String sourceId) async {
    final row = await (_db.select(
      _db.sources,
    )..where((s) => s.id.equals(sourceId))).getSingleOrNull();
    if (row == null) return null;
    final count = _db.books.id.count();
    final books =
        await (_db.selectOnly(_db.books)
              ..addColumns([count])
              ..where(_db.books.sourceId.equals(sourceId)))
            .map((r) => r.read(count)!)
            .getSingle();
    return _toSource(row, books);
  }

  Future<List<Chapter>> chaptersOf(String bookId) async {
    final rows =
        await (_db.select(_db.chapters)
              ..where((c) => c.bookId.equals(bookId))
              ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
            .get();
    return [for (final row in rows) _toChapter(row)];
  }

  Future<Book?> getBook(String bookId) async {
    final row = await (_db.select(
      _db.books,
    )..where((b) => b.id.equals(bookId))).getSingleOrNull();
    return row == null ? null : _toBook(row);
  }

  /// URIs de capítulos que pertencem a outras origens que não [sourceId]
  /// (todas, se nulo); o escaneamento as ignora para não duplicar arquivos.
  Future<Set<String>> chapterUrisOutside(String? sourceId) async {
    final query = _db.select(_db.chapters).join([
      innerJoin(_db.books, _db.books.id.equalsExp(_db.chapters.bookId)),
    ]);
    if (sourceId != null) {
      query.where(_db.books.sourceId.equals(sourceId).not());
    }
    final rows = await query.get();
    return {for (final row in rows) row.readTable(_db.chapters).uri};
  }

  /// URIs dos capítulos da origem (para liberar permissões de arquivos).
  Future<Set<String>> chapterUrisOf(String sourceId) async {
    final query = _db.select(_db.chapters).join([
      innerJoin(_db.books, _db.books.id.equalsExp(_db.chapters.bookId)),
    ])..where(_db.books.sourceId.equals(sourceId));
    final rows = await query.get();
    return {for (final row in rows) row.readTable(_db.chapters).uri};
  }

  /// Caminhos de capa ainda referenciados; o resto pode ser apagado.
  Future<Set<String>> coverPathsInUse() async {
    final rows = await _db.select(_db.books).get();
    return {
      for (final row in rows) ...[?row.scannedCoverPath, ?row.customCoverPath],
    };
  }

  Stream<List<BookSummary>> _watchSummaries({
    String where = '',
    String orderBy = '',
  }) {
    return _db
        .customSelect(
          'SELECT b.*, s.available AS source_available, '
          'p.chapter_id AS progress_chapter_id, '
          'p.position_ms AS progress_position_ms, '
          '(SELECT COUNT(*) FROM chapters x WHERE x.book_id = b.id '
          'AND x.sort_order < c.sort_order) AS progress_chapter_index, '
          '(SELECT COALESCE(SUM(x.duration_ms), 0) FROM chapters x '
          'WHERE x.book_id = b.id AND x.sort_order < c.sort_order) '
          'AS progress_elapsed_ms '
          'FROM books b '
          'JOIN sources s ON s.id = b.source_id '
          'LEFT JOIN progress p ON p.book_id = b.id '
          'LEFT JOIN chapters c ON c.id = p.chapter_id '
          '$where $orderBy',
          readsFrom: {
            _db.books,
            _db.sources,
            _db.progressEntries,
            _db.chapters,
          },
        )
        .watch()
        .map((rows) => [for (final row in rows) _toSummary(row)]);
  }

  BookSummary _toSummary(QueryRow row) {
    final chapterId = row.readNullable<String>('progress_chapter_id');
    return BookSummary(
      book: _toBook(_db.books.map(row.data)),
      sourceAvailable: row.read<bool>('source_available'),
      progress: chapterId == null
          ? null
          : ListeningProgress(
              chapterId: chapterId,
              chapterIndex: row.read<int>('progress_chapter_index'),
              position: Duration(
                milliseconds: row.read<int>('progress_position_ms'),
              ),
              elapsedBeforeChapter: Duration(
                milliseconds: row.read<int>('progress_elapsed_ms'),
              ),
            ),
    );
  }

  static int _compareRecent(BookSummary a, BookSummary b) {
    final pa = a.book.lastPlayedAt;
    final pb = b.book.lastPlayedAt;
    if (pa != null && pb != null && pa != pb) return pb.compareTo(pa);
    if (pa != null && pb == null) return -1;
    if (pa == null && pb != null) return 1;
    final created = b.book.createdAt.compareTo(a.book.createdAt);
    return created != 0 ? created : _compareTitle(a, b);
  }

  static int _compareTitle(BookSummary a, BookSummary b) =>
      compareNatural(a.book.title, b.book.title);

  static Book _toBook(BookRow row) => Book(
    id: row.id,
    sourceId: row.sourceId,
    scannedTitle: row.scannedTitle,
    scannedAuthor: row.scannedAuthor,
    scannedCoverPath: row.scannedCoverPath,
    customTitle: row.customTitle,
    customAuthor: row.customAuthor,
    customCoverPath: row.customCoverPath,
    totalDuration: _duration(row.totalDurationMs),
    chapterCount: row.chapterCount,
    lastPlayedAt: row.lastPlayedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.lastPlayedAt!),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
  );

  static Chapter _toChapter(ChapterRow row) => Chapter(
    id: row.id,
    bookId: row.bookId,
    title: row.title,
    uri: row.uri,
    sortOrder: row.sortOrder,
    trackNumber: row.trackNumber,
    duration: _duration(row.durationMs),
    start: _duration(row.startMs),
    end: _duration(row.endMs),
  );

  static LibrarySource _toSource(SourceRow row, int bookCount) => LibrarySource(
    id: row.id,
    uri: row.uri,
    name: row.name,
    kind: SourceKind.values.byName(row.kind),
    importMode: row.importMode == null
        ? null
        : ImportMode.values.byName(row.importMode!),
    available: row.available,
    lastScannedAt: DateTime.fromMillisecondsSinceEpoch(row.lastScannedAt),
    bookCount: bookCount,
  );

  static Duration? _duration(int? ms) =>
      ms == null ? null : Duration(milliseconds: ms);
}
