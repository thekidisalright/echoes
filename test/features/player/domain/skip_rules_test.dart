import 'package:echoes/features/player/domain/skip_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('capítulo anterior (regra dos 3 s)', () {
    test('depois de 3 s volta ao início do capítulo atual', () {
      expect(SkipRules.previousChapter(4, const Duration(seconds: 4)), 4);
      expect(
        SkipRules.previousChapter(4, const Duration(milliseconds: 3001)),
        4,
      );
    });

    test('até 3 s vai para o capítulo anterior', () {
      expect(SkipRules.previousChapter(4, const Duration(seconds: 3)), 3);
      expect(SkipRules.previousChapter(4, Duration.zero), 3);
    });

    test('no primeiro capítulo sempre volta ao início', () {
      expect(SkipRules.previousChapter(0, Duration.zero), 0);
      expect(SkipRules.previousChapter(0, const Duration(minutes: 9)), 0);
    });
  });

  test('próximo capítulo não existe no último', () {
    expect(SkipRules.nextChapter(0, 3), 1);
    expect(SkipRules.nextChapter(2, 3), isNull);
  });

  test('voltar 15 s para no início', () {
    expect(
      SkipRules.rewind(const Duration(seconds: 40)),
      const Duration(seconds: 25),
    );
    expect(SkipRules.rewind(const Duration(seconds: 10)), Duration.zero);
  });

  test('avançar 15 s para no fim do capítulo', () {
    const total = Duration(minutes: 1);
    expect(
      SkipRules.fastForward(const Duration(seconds: 30), total),
      const Duration(seconds: 45),
    );
    expect(SkipRules.fastForward(const Duration(seconds: 50), total), total);
    expect(
      SkipRules.fastForward(const Duration(seconds: 50), null),
      const Duration(seconds: 65),
    );
  });
}
