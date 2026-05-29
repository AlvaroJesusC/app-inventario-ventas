import 'package:flutter_test/flutter_test.dart';
import 'package:app_inventario_ventas/utils/formatters.dart';

void main() {
  group('StringExtension capitalizeFirst tests', () {
    test('Capitalizes the first letter of a lowercase word', () {
      expect('manzana'.capitalizeFirst(), 'Manzana');
    });

    test('Capitalizes the first letter of a sentence/multiple words', () {
      expect('detergente líquido'.capitalizeFirst(), 'Detergente líquido');
    });

    test('Keeps the rest of the string unmodified', () {
      expect('detergente Líquido'.capitalizeFirst(), 'Detergente Líquido');
    });

    test('Handles empty string', () {
      expect(''.capitalizeFirst(), '');
    });

    test('Handles single character', () {
      expect('a'.capitalizeFirst(), 'A');
      expect('A'.capitalizeFirst(), 'A');
    });

    test('Does not modify already capitalized string', () {
      expect('Manzana'.capitalizeFirst(), 'Manzana');
    });

    test('Handles strings with leading spaces or non-alphabetic chars', () {
      expect(' 123 manzana'.capitalizeFirst(), ' 123 manzana');
      expect('123 manzana'.capitalizeFirst(), '123 manzana');
    });
  });
}
