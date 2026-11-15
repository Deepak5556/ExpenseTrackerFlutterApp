import 'package:expense_journal_budget/core/utils/money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatMoney', () {
    test('formats Indian grouped rupees without unnecessary decimals', () {
      expect(formatMoney(10000000), '₹1,00,000');
    });

    test('formats zero', () {
      expect(formatMoney(0), '₹0');
    });

    test('formats negative amounts and paise', () {
      expect(formatMoney(-123456), '−₹1,234.56');
    });

    test('supports compact display', () {
      expect(formatMoney(10000000, compact: true), '₹1L');
    });
  });
}
