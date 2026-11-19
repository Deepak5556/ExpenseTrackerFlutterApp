import 'package:flutter_test/flutter_test.dart';
import 'package:expense_journal_budget/core/utils/validators.dart';

void main() {
  group('FormValidators Unit Tests', () {
    test('validateTitle checks empty and length constraints', () {
      expect(FormValidators.validateTitle(null), 'Title is required');
      expect(FormValidators.validateTitle(''), 'Title is required');
      expect(FormValidators.validateTitle('   '), 'Title is required');
      expect(FormValidators.validateTitle('Groceries'), isNull);
      final longTitle = 'a' * 61;
      expect(
        FormValidators.validateTitle(longTitle),
        'Title must be 60 characters or less',
      );
      final validTitle = 'a' * 60;
      expect(FormValidators.validateTitle(validTitle), isNull);
    });

    test('validateAmount checks formatting, positivity and decimal precision', () {
      expect(FormValidators.validateAmount(null), 'Amount is required');
      expect(FormValidators.validateAmount(''), 'Amount is required');
      expect(FormValidators.validateAmount('0'), 'Amount must be greater than 0');
      expect(FormValidators.validateAmount('-50'), 'Enter a valid amount with up to 2 decimal places');
      expect(FormValidators.validateAmount('12.345'), 'Enter a valid amount with up to 2 decimal places');
      expect(FormValidators.validateAmount('abc'), 'Enter a valid amount with up to 2 decimal places');
      expect(FormValidators.validateAmount('150.00'), isNull);
      expect(FormValidators.validateAmount('150.5'), isNull);
      expect(FormValidators.validateAmount('150'), isNull);
      expect(FormValidators.validateAmount('1,500.50'), isNull);
    });

    test('parseAmountMinor converts to paise accurately', () {
      expect(FormValidators.parseAmountMinor('100'), 10000);
      expect(FormValidators.parseAmountMinor('100.50'), 10050);
      expect(FormValidators.parseAmountMinor('100.5'), 10050);
      expect(FormValidators.parseAmountMinor('100.05'), 10005);
      expect(FormValidators.parseAmountMinor('0.99'), 99);
      expect(FormValidators.parseAmountMinor('1,250.75'), 125075);
      expect(FormValidators.parseAmountMinor('invalid'), isNull);
    });

    test('validateCategory ensures category is selected', () {
      expect(FormValidators.validateCategory(null), 'Please choose a category');
      expect(FormValidators.validateCategory(''), 'Please choose a category');
      expect(FormValidators.validateCategory('cat-food'), isNull);
    });

    test('validateDate checks sanity range', () {
      expect(FormValidators.validateDate(null), 'Date is required');
      expect(FormValidators.validateDate(DateTime(1999, 12, 31)), 'Date is too far in the past');
      expect(FormValidators.validateDate(DateTime(2000, 1, 1)), isNull);
      expect(FormValidators.validateDate(DateTime.now()), isNull);
      expect(
        FormValidators.validateDate(DateTime.now().add(const Duration(days: 365 * 6))),
        'Date is too far in the future',
      );
    });
  });
}
