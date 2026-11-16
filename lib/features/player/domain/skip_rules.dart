/// Regras dos botões de navegação do player (docs/FEATURES.md §3).
abstract final class SkipRules {
  /// Tamanho dos saltos de voltar/avançar.
  static const jump = Duration(seconds: 15);

  /// Acima disso, "capítulo anterior" volta ao início do capítulo atual.
  static const restartThreshold = Duration(seconds: 3);

  /// Índice do capítulo para onde "capítulo anterior" leva, sempre na
  /// posição 0. Igual a [index] significa voltar ao início do atual.
  static int previousChapter(int index, Duration position) {
    if (position > restartThreshold || index <= 0) return index;
    return index - 1;
  }

  /// Índice do próximo capítulo, ou nulo se [index] é o último.
  static int? nextChapter(int index, int chapterCount) =>
      index + 1 < chapterCount ? index + 1 : null;

  /// Posição após voltar 15 s, sem passar do início.
  static Duration rewind(Duration position) {
    final target = position - jump;
    return target.isNegative ? Duration.zero : target;
  }

  /// Posição após avançar 15 s, sem passar de [duration] (se conhecida).
  static Duration fastForward(Duration position, Duration? duration) {
    final target = position + jump;
    if (duration == null || target < duration) return target;
    return duration;
  }
}
