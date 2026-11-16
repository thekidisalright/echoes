import '../../library/domain/library_source.dart';
import 'import_mode.dart';

/// Resultado do escaneamento de uma origem, pronto para ser salvo.
class ScannedSource {
  const ScannedSource({
    required this.id,
    required this.uri,
    required this.name,
    required this.kind,
    required this.books,
    this.importMode,
  });

  final String id;
  final String uri;
  final String name;
  final SourceKind kind;
  final ImportMode? importMode;
  final List<ScannedBook> books;
}

/// Livro encontrado no escaneamento. A ordem de [chapters] é a ordem da fila.
class ScannedBook {
  const ScannedBook({
    required this.id,
    required this.title,
    required this.author,
    required this.chapters,
    this.coverPath,
  }) : assert(chapters.length > 0, 'Um livro precisa de ao menos um capítulo');

  final String id;
  final String title;
  final String author;

  /// Caminho local da capa já copiada pelo `CoverStore`.
  final String? coverPath;
  final List<ScannedChapter> chapters;

  /// Soma das durações conhecidas; nula se nenhum capítulo tem duração.
  Duration? get totalDuration {
    Duration? total;
    for (final chapter in chapters) {
      final duration = chapter.duration;
      if (duration != null) total = (total ?? Duration.zero) + duration;
    }
    return total;
  }
}

/// Arquivo de áudio encontrado no escaneamento.
class ScannedChapter {
  const ScannedChapter({
    required this.id,
    required this.title,
    required this.uri,
    this.trackNumber,
    this.duration,
  });

  final String id;
  final String title;
  final String uri;
  final int? trackNumber;
  final Duration? duration;
}
