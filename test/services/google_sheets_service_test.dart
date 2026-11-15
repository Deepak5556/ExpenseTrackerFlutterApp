import 'package:expense_journal_budget/services/google_sheets_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseTransactions reads paise as integer minor units and hides soft-deleted rows', () {
    final transactions = parseTransactions(<List<Object?>>[
      <Object?>[
        'id',
        'type',
        'title',
        'amountMinor',
        'categoryId',
        'categoryName',
        'occurredAt',
        'paymentMethod',
        'notes',
        'deletedAt',
      ],
      <Object?>[
        'txn-1',
        'expense',
        'Groceries',
        12345,
        'food',
        'Food',
        '2026-11-13T12:30:00.000',
        'UPI',
        'Vegetables',
        '',
      ],
      <Object?>[
        'txn-2',
        'income',
        'Refund',
        5500,
        'other-income',
        'Other income',
        '2026-11-13T12:45:00.000',
        '',
        '',
        '2026-11-13T13:00:00.000Z',
      ],
    ]);

    expect(transactions, hasLength(1));
    expect(transactions.single.id, 'txn-1');
    expect(transactions.single.amountMinor, 12345);
    expect(transactions.single.paymentMethod, 'UPI');
    expect(transactions.single.monthKey, '2026-11');
  });
}
