import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/book_progress.dart';

/// Capítulo e posição salvos de cada livro, e o `lastPlayedAt`.
class ProgressRepository {
  ProgressRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// Grava a posição. Não faz nada se o livro já não existe (por exemplo,
  /// a origem foi removida enquanto tocava).
  Future<void> saveProgress(
    String bookId,
    String chapterId,
    Duration position,
  ) {
    return _db.transaction(() async {
      if (!await _bookExists(bookId)) return;
      await _db
          .into(_db.progressEntries)
          .insertOnConflictUpdate(
            ProgressEntriesCompanion.insert(
              bookId: bookId,
              chapterId: chapterId,
              positionMs: position.inMilliseconds,
              updatedAt: _clock().millisecondsSinceEpoch,
            ),
          );
    });
  }

  Future<BookProgress?> getProgress(String bookId) async {
    final row = await (_db.select(
      _db.progressEntries,
    )..where((p) => p.bookId.equals(bookId))).getSingleOrNull();
    if (row == null) return null;
    return BookProgress(
      bookId: row.bookId,
      chapterId: row.chapterId,
      position: Duration(milliseconds: row.positionMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  /// Marca o livro como tocado agora (ordem "Recentes" e "Continue ouvindo").
  Future<void> touchLastPlayed(String bookId) =>
      (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
        BooksCompanion(lastPlayedAt: Value(_clock().millisecondsSinceEpoch)),
      );

  Future<bool> _bookExists(String bookId) async {
    final row =
        await (_db.selectOnly(_db.books)
              ..addColumns([_db.books.id])
              ..where(_db.books.id.equals(bookId)))
            .getSingleOrNull();
    return row != null;
  }
}
