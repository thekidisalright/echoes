/// Duração total de livro: "5h 03m" ou "45m".
String formatBookDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '${minutes}m';
  return '${hours}h ${_two(minutes)}m';
}

/// Posição no relógio: "12:34" ou, a partir de 1 hora, "1:05:34".
/// Valores negativos contam como zero.
String formatClock(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final hours = safe.inHours;
  final minutes = safe.inMinutes.remainder(60);
  final seconds = safe.inSeconds.remainder(60);
  if (hours == 0) return '${_two(minutes)}:${_two(seconds)}';
  return '$hours:${_two(minutes)}:${_two(seconds)}';
}

/// Tempo restante com sinal: "-03:21".
String formatRemaining(Duration position, Duration total) =>
    '-${formatClock(total - position)}';

String _two(int value) => value.toString().padLeft(2, '0');
