/// Marcador numa posição de um capítulo.
class Bookmark {
  const Bookmark({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.position,
    required this.createdAt,
  });

  final int id;
  final String bookId;
  final String chapterId;
  final Duration position;
  final DateTime createdAt;
}
