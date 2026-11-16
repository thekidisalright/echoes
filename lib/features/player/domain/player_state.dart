import '../../library/domain/book.dart';
import '../../library/domain/chapter.dart';

/// Estado do player para a UI, sem a posição (que muda várias vezes por
/// segundo e vem num stream próprio).
class PlayerState {
  const PlayerState({
    this.book,
    this.chapters = const [],
    this.chapterIndex = 0,
    this.duration,
    this.playing = false,
    this.buffering = false,
    this.completed = false,
  });

  static const empty = PlayerState();

  final Book? book;
  final List<Chapter> chapters;
  final int chapterIndex;

  /// Duração do capítulo atual, quando conhecida.
  final Duration? duration;
  final bool playing;
  final bool buffering;

  /// Terminou o último capítulo.
  final bool completed;

  bool get hasBook => book != null && chapters.isNotEmpty;

  Chapter? get chapter => chapterIndex >= 0 && chapterIndex < chapters.length
      ? chapters[chapterIndex]
      : null;

  bool get isFirstChapter => chapterIndex == 0;
  bool get isLastChapter => chapterIndex >= chapters.length - 1;
}

/// O que o `ProgressSaver` precisa saber a cada atualização do player.
class PlaybackSnapshot {
  const PlaybackSnapshot({
    required this.bookId,
    required this.chapterId,
    required this.position,
    required this.playing,
  });

  final String bookId;
  final String chapterId;
  final Duration position;
  final bool playing;
}
