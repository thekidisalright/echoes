import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/bookmark.dart';

class BookmarkRepository {
  BookmarkRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;

  /// Cria um marcador e devolve o id.
  Future<int> add(String bookId, String chapterId, Duration position) => _db
      .into(_db.bookmarks)
      .insert(
        BookmarksCompanion.insert(
          bookId: bookId,
          chapterId: chapterId,
          positionMs: position.inMilliseconds,
          createdAt: _clock().millisecondsSinceEpoch,
        ),
      );

  Future<void> remove(int id) =>
      (_db.delete(_db.bookmarks)..where((b) => b.id.equals(id))).go();

  /// Marcadores do livro, mais recentes primeiro.
  Stream<List<Bookmark>> watchByBook(String bookId) {
    final query = _db.select(_db.bookmarks)
      ..where((b) => b.bookId.equals(bookId))
      ..orderBy([
        (b) => OrderingTerm.desc(b.createdAt),
        (b) => OrderingTerm.desc(b.id),
      ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          Bookmark(
            id: row.id,
            bookId: row.bookId,
            chapterId: row.chapterId,
            position: Duration(milliseconds: row.positionMs),
            createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
          ),
      ],
    );
  }
}
