import 'package:flutter_test/flutter_test.dart';
import 'package:format_anything/services/formatter_service.dart';

void main() {
  group('Formatter', () {
    test('pretty-prints valid JSON', () {
      expect(Formatter.format('{"a":1}', 'JSON'), '{\n  "a": 1\n}');
    });

    test('removes common tracking query parameters', () {
      expect(
        Formatter.format('https://example.com/?utm_source=news&id=7', 'Clean URL'),
        'https://example.com/?id=7',
      );
    });

    test('normalizes excessive blank lines in plain text', () {
      expect(Formatter.format('hello   world\n\n\nnext', 'Plain Text'), 'hello world\n\nnext');
    });
  });
}
