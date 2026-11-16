import 'book.dart';

/// Onde o usuário parou num livro, com o que a barra de progresso precisa.
class ListeningProgress {
  const ListeningProgress({
    required this.chapterId,
    required this.chapterIndex,
    required this.position,
    required this.elapsedBeforeChapter,
  });

  final String chapterId;

  /// Índice (0-based) do capítulo atual na fila.
  final int chapterIndex;

  /// Posição dentro do capítulo atual.
  final Duration position;

  /// Soma das durações dos capítulos anteriores ao atual.
  final Duration elapsedBeforeChapter;
}

/// Livro como aparece na biblioteca e em "Continue ouvindo".
class BookSummary {
  const BookSummary({
    required this.book,
    required this.sourceAvailable,
    this.progress,
  });

  final Book book;
  final bool sourceAvailable;
  final ListeningProgress? progress;

  /// Fração do livro inteiro já ouvida, de 0 a 1.
  ///
  /// Com durações: (capítulos anteriores + posição) / total. Sem durações:
  /// índice do capítulo / quantidade de capítulos.
  double get fractionListened {
    final p = progress;
    if (p == null) return 0;
    final total = book.totalDuration?.inMilliseconds ?? 0;
    final double fraction;
    if (total > 0) {
      final done =
          p.elapsedBeforeChapter.inMilliseconds + p.position.inMilliseconds;
      fraction = done / total;
    } else if (book.chapterCount > 0) {
      fraction = p.chapterIndex / book.chapterCount;
    } else {
      fraction = 0;
    }
    return fraction.clamp(0, 1).toDouble();
  }
}
