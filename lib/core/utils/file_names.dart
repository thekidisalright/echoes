import 'natural_sort.dart';

final _audioExt = RegExp(r'\.(mp3|m4a|m4b)$', caseSensitive: false);
final _imageExt = RegExp(r'\.(jpe?g|png|webp)$', caseSensitive: false);
final _preferredCover = RegExp(
  r'^(cover|folder|front|artwork|album)([-_ .]|$)',
  caseSensitive: false,
);
final _trackNumber = RegExp(
  r'^\s*(?:track\s*)?(\d{1,3})(?:[\s._-]|$)',
  caseSensitive: false,
);
final _extension = RegExp(r'\.[^.]+$');
final _leadingNumber = RegExp(r'^\d+[\s._-]+');
final _separators = RegExp(r'[._]+');

/// `.mp3`, `.m4a` ou `.m4b`, sem diferenciar maiúsculas.
bool isAudio(String name) => _audioExt.hasMatch(name);

/// `.jpg`, `.jpeg`, `.png` ou `.webp`, sem diferenciar maiúsculas.
bool isImage(String name) => _imageExt.hasMatch(name);

/// Imagem com nome de capa conhecido: `cover`, `folder`, `front`, `artwork`
/// ou `album`, seguido de separador ou extensão.
bool isPreferredCover(String name) =>
    isImage(name) && _preferredCover.hasMatch(name);

/// Número de faixa no início do nome ("01 - Prólogo.mp3", "Track 3.mp3").
int? parseTrackNumber(String name) {
  final match = _trackNumber.firstMatch(name);
  return match == null ? null : int.parse(match.group(1)!);
}

/// Título legível a partir do nome do arquivo: sem extensão, sem número
/// inicial e com `.`/`_` trocados por espaço. Se sobrar vazio, devolve o nome.
String cleanTitle(String name) {
  final title = name
      .replaceFirst(_extension, '')
      .replaceFirst(_leadingNumber, '')
      .replaceAll(_separators, ' ')
      .trim();
  return title.isEmpty ? name : title;
}

/// Ordem das faixas de um livro (docs/FEATURES.md §1.3): numeradas primeiro,
/// pelo número com desempate natural; o resto em ordem natural.
int compareTrackNames(String a, String b) {
  final ta = parseTrackNumber(a);
  final tb = parseTrackNumber(b);
  if (ta != null && tb != null) {
    final byNumber = ta.compareTo(tb);
    return byNumber != 0 ? byNumber : compareNatural(a, b);
  }
  if (ta != null) return -1;
  if (tb != null) return 1;
  return compareNatural(a, b);
}
