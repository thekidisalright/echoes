import 'package:echoes/core/utils/file_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isAudio', () {
    test('aceita mp3, m4a e m4b sem diferenciar maiúsculas', () {
      expect(isAudio('a.mp3'), isTrue);
      expect(isAudio('a.M4A'), isTrue);
      expect(isAudio('livro.m4b'), isTrue);
    });

    test('rejeita outros formatos', () {
      expect(isAudio('a.flac'), isFalse);
      expect(isAudio('a.mp3.txt'), isFalse);
      expect(isAudio('mp3'), isFalse);
    });
  });

  group('isImage', () {
    test('aceita jpg, jpeg, png e webp', () {
      for (final name in ['a.jpg', 'a.JPEG', 'a.png', 'a.webp']) {
        expect(isImage(name), isTrue, reason: name);
      }
    });

    test('rejeita gif e bmp', () {
      expect(isImage('a.gif'), isFalse);
      expect(isImage('a.bmp'), isFalse);
    });
  });

  group('isPreferredCover', () {
    test('reconhece nomes de capa conhecidos', () {
      for (final name in [
        'cover.jpg',
        'Folder.png',
        'front.webp',
        'artwork.jpeg',
        'album.jpg',
        'cover-hd.jpg',
        'cover_1.png',
        'Cover Art.jpg',
      ]) {
        expect(isPreferredCover(name), isTrue, reason: name);
      }
    });

    test('ignora nomes que só começam parecido ou não são imagem', () {
      expect(isPreferredCover('coverage.jpg'), isFalse);
      expect(isPreferredCover('my cover.jpg'), isFalse);
      expect(isPreferredCover('cover.mp3'), isFalse);
    });
  });

  group('parseTrackNumber', () {
    test('lê o número inicial seguido de separador', () {
      expect(parseTrackNumber('01 - Prólogo.mp3'), 1);
      expect(parseTrackNumber('12.mp3'), 12);
      expect(parseTrackNumber('003_capitulo.mp3'), 3);
      expect(parseTrackNumber('  7-x.mp3'), 7);
      expect(parseTrackNumber('Track 5.mp3'), 5);
      expect(parseTrackNumber('track09 abc.mp3'), 9);
      expect(parseTrackNumber('42'), 42);
    });

    test('não lê números longos, no meio do nome ou sem separador', () {
      expect(parseTrackNumber('1234 - x.mp3'), isNull);
      expect(parseTrackNumber('Capítulo 1.mp3'), isNull);
      expect(parseTrackNumber('1984.mp3'), isNull);
      expect(parseTrackNumber('01abc.mp3'), isNull);
    });
  });

  group('cleanTitle', () {
    test('remove extensão, número inicial e troca . e _ por espaço', () {
      expect(cleanTitle('01 - Prólogo.mp3'), 'Prólogo');
      expect(cleanTitle('01_O_inicio.mp3'), 'O inicio');
      expect(cleanTitle('02.Capitulo.dois.m4b'), 'Capitulo dois');
      expect(cleanTitle('Epílogo.mp3'), 'Epílogo');
    });

    test('devolve o nome original quando sobra vazio', () {
      expect(cleanTitle('01.mp3'), '01');
      expect(cleanTitle('.mp3'), '.mp3');
    });
  });

  group('compareTrackNames', () {
    List<String> sorted(List<String> names) =>
        [...names]..sort(compareTrackNames);

    test('ordena pelo número de faixa, não pelo texto', () {
      expect(sorted(['10 - c.mp3', '2 - b.mp3', '1 - a.mp3']), [
        '1 - a.mp3',
        '2 - b.mp3',
        '10 - c.mp3',
      ]);
    });

    test('desempata números iguais em ordem natural', () {
      expect(sorted(['01 parte b.mp3', '1 parte a.mp3']), [
        '1 parte a.mp3',
        '01 parte b.mp3',
      ]);
    });

    test('numerados antes dos não numerados', () {
      expect(
        sorted(['Epílogo.mp3', '02 x.mp3', 'Apresentação.mp3', '01 y.mp3']),
        ['01 y.mp3', '02 x.mp3', 'Apresentação.mp3', 'Epílogo.mp3'],
      );
    });

    test('sem números de faixa usa ordem natural', () {
      expect(sorted(['Capítulo 10.mp3', 'Capítulo 2.mp3', 'Capítulo 1.mp3']), [
        'Capítulo 1.mp3',
        'Capítulo 2.mp3',
        'Capítulo 10.mp3',
      ]);
    });
  });
}
