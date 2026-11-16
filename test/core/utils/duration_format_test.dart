import 'package:echoes/core/utils/duration_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatBookDuration', () {
    test('com horas usa minutos com 2 dígitos', () {
      expect(
        formatBookDuration(const Duration(hours: 5, minutes: 3)),
        '5h 03m',
      );
      expect(
        formatBookDuration(const Duration(hours: 26, minutes: 24, seconds: 47)),
        '26h 24m',
      );
    });

    test('sem horas mostra só minutos', () {
      expect(formatBookDuration(const Duration(minutes: 45)), '45m');
      expect(formatBookDuration(Duration.zero), '0m');
    });
  });

  group('formatClock', () {
    test('minutos e segundos com 2 dígitos', () {
      expect(formatClock(const Duration(minutes: 12, seconds: 34)), '12:34');
      expect(formatClock(const Duration(seconds: 5)), '00:05');
    });

    test('a partir de 1 hora inclui as horas', () {
      expect(
        formatClock(const Duration(hours: 1, minutes: 5, seconds: 34)),
        '1:05:34',
      );
    });

    test('negativo vira zero', () {
      expect(formatClock(const Duration(seconds: -3)), '00:00');
    });
  });

  test('formatRemaining mostra o tempo que falta com sinal', () {
    expect(
      formatRemaining(
        const Duration(minutes: 1),
        const Duration(minutes: 4, seconds: 21),
      ),
      '-03:21',
    );
  });
}
