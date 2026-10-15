import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:format_anything/services/formatter_service.dart';

void main() {
  group('Receipt currency extraction', () {
    test('detects an explicit dollar symbol', () {
      final result = jsonDecode(Formatter.format(
        'Spiral Diner\nReal Smooth \$7.99\nSubtotal: \$46.54\nTax: \$3.84\nTotal: \$50.38',
        'Receipt JSON',
      )) as Map<String, dynamic>;

      expect(result['currency_symbol'], '\$');
      expect(result['currency_detection'], 'symbol_detected');
      expect(result['total'], 50.38);
      expect(result['items'], isA<List<dynamic>>());
      expect(result['items'].first['currency_symbol'], '\$');
    });

    test('does not invent a currency symbol when none is printed', () {
      final result = jsonDecode(Formatter.format(
        'Cafe Example\nCoffee 2.99\nSubtotal: 46.54\nTax: 3.84\nTotal: 50.38',
        'Receipt JSON',
      )) as Map<String, dynamic>;

      expect(result['currency_symbol'], isNull);
      expect(result['currency_detection'], 'symbol_not_detected');
      expect(result['total'], 50.38);
      expect(result['items'].first.containsKey('currency_symbol'), isFalse);
    });

    test('does not claim one currency when multiple symbols are detected', () {
      final result = jsonDecode(Formatter.format(
        'Shop\nItem \$5.00\nOther €4.00\nTotal 9.00',
        'Receipt JSON',
      )) as Map<String, dynamic>;

      expect(result['currency_symbol'], isNull);
      expect(result['currency_detection'], 'multiple_symbols_detected');
    });
  });
}
