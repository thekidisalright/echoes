/// Comparação "natural" de nomes: trechos numéricos são comparados pelo valor
/// ("2" < "10"), letras sem diferenciar maiúsculas nem acentos.
///
/// Equivale ao `Intl.Collator(undefined, {numeric: true, sensitivity: "base"})`
/// usado na versão anterior.
int compareNatural(String a, String b) {
  final ka = _normalize(a);
  final kb = _normalize(b);
  var i = 0;
  var j = 0;
  while (i < ka.length && j < kb.length) {
    final ca = ka.codeUnitAt(i);
    final cb = kb.codeUnitAt(j);
    if (_isDigit(ca) && _isDigit(cb)) {
      final endA = _digitsEnd(ka, i);
      final endB = _digitsEnd(kb, j);
      final cmp = _compareDigits(ka.substring(i, endA), kb.substring(j, endB));
      if (cmp != 0) return cmp;
      i = endA;
      j = endB;
    } else {
      if (ca != cb) return ca.compareTo(cb);
      i++;
      j++;
    }
  }
  return (ka.length - i).compareTo(kb.length - j);
}

bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

int _digitsEnd(String s, int start) {
  var end = start;
  while (end < s.length && _isDigit(s.codeUnitAt(end))) {
    end++;
  }
  return end;
}

/// Compara duas sequências de dígitos pelo valor, sem limite de tamanho.
int _compareDigits(String a, String b) {
  final ta = _trimZeros(a);
  final tb = _trimZeros(b);
  if (ta.length != tb.length) return ta.length.compareTo(tb.length);
  return ta.compareTo(tb);
}

String _trimZeros(String s) {
  var k = 0;
  while (k < s.length - 1 && s.codeUnitAt(k) == 0x30) {
    k++;
  }
  return s.substring(k);
}

const _diacritics = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
  'ç': 'c', 'ñ': 'n', 'ý': 'y', 'ÿ': 'y',
};

String _normalize(String s) {
  final lower = s.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_diacritics[char] ?? char);
  }
  return buffer.toString();
}
