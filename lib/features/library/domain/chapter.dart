/// Capítulo de um livro. Na v1, um arquivo de áudio é um capítulo.
class Chapter {
  const Chapter({
    required this.id,
    required this.bookId,
    required this.title,
    required this.uri,
    required this.sortOrder,
    this.trackNumber,
    this.duration,
    this.start,
    this.end,
  });

  final String id;
  final String bookId;
  final String title;
  final String uri;
  final int sortOrder;
  final int? trackNumber;
  final Duration? duration;

  /// Reservados para capítulos internos de M4B (Fase 7).
  final Duration? start;
  final Duration? end;
}
