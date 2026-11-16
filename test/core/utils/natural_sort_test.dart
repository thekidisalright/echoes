import 'package:echoes/core/utils/natural_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> sorted(List<String> names) => [...names]..sort(compareNatural);

  test('compara trechos numéricos pelo valor', () {
    expect(sorted(['a10', 'a2', 'a1']), ['a1', 'a2', 'a10']);
  });

  test('ignora maiúsculas e acentos', () {
    expect(compareNatural('Capitulo', 'capítulo'), 0);
    expect(sorted(['banana', 'Ábaco', 'casa']), ['Ábaco', 'banana', 'casa']);
  });

  test('zeros à esquerda têm o mesmo valor', () {
    expect(compareNatural('parte 02', 'parte 2'), 0);
  });

  test('números longos não estouram', () {
    expect(
      compareNatural('x 123456789012345678901', 'x 99999999999999999999'),
      greaterThan(0),
    );
  });

  test('prefixo vem antes', () {
    expect(compareNatural('livro', 'livro 2'), lessThan(0));
  });
}
