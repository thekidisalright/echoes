/// Capítulo e posição salvos de um livro.
class BookProgress {
  const BookProgress({
    required this.bookId,
    required this.chapterId,
    required this.position,
    required this.updatedAt,
  });

  final String bookId;
  final String chapterId;
  final Duration position;
  final DateTime updatedAt;
}
