import 'package:echoes/core/utils/date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('data curta com dia e mês em dois dígitos', () {
    expect(formatShortDate(DateTime(2026, 3, 7, 23, 59)), '07/03/2026');
    expect(formatShortDate(DateTime(2026, 11, 16)), '16/11/2026');
  });
}
