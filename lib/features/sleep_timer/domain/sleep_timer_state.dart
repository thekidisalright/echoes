/// Estado do timer de sono.
sealed class SleepTimerState {
  const SleepTimerState();

  bool get active => this is! SleepTimerOff;
}

/// Sem timer.
class SleepTimerOff extends SleepTimerState {
  const SleepTimerOff();
}

/// Pausa quando [remaining] chegar a zero.
class SleepTimerCountdown extends SleepTimerState {
  const SleepTimerCountdown(this.remaining);

  final Duration remaining;

  /// Minutos exibidos, arredondados para cima ("Timer · 12 min").
  int get minutesLeft =>
      (remaining.inMilliseconds + Duration.millisecondsPerMinute - 1) ~/
      Duration.millisecondsPerMinute;

  @override
  bool operator ==(Object other) =>
      other is SleepTimerCountdown && other.remaining == remaining;

  @override
  int get hashCode => remaining.hashCode;
}

/// Pausa quando o capítulo [chapterIndex] do livro [bookId] terminar.
class SleepTimerEndOfChapter extends SleepTimerState {
  const SleepTimerEndOfChapter({
    required this.bookId,
    required this.chapterIndex,
  });

  final String bookId;
  final int chapterIndex;

  @override
  bool operator ==(Object other) =>
      other is SleepTimerEndOfChapter &&
      other.bookId == bookId &&
      other.chapterIndex == chapterIndex;

  @override
  int get hashCode => Object.hash(bookId, chapterIndex);
}
