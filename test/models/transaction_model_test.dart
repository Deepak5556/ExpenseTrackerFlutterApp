import 'package:expense_journal_budget/models/transaction_model.dart';
import 'package:expense_journal_budget/services/google_sheets_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const headers = <Object?>[
    'transactionId',
    'type',
    'title',
    'amountMinor',
    'categoryId',
    'categoryName',
    'date',
    'time',
    'paymentMethod',
    'notes',
    'updatedAt',
  ];
  test('transaction row round trips with text dates and minor units', () {
    const item = TransactionModel(
      transactionId: 'tx-1',
      type: TransactionType.expense,
      title: 'Lunch',
      amountMinor: 12345,
      categoryId: 'food',
      categoryName: 'Food',
      date: '2026-11-15',
      time: '13:42',
      paymentMethod: 'UPI',
      notes: 'Cafe',
      updatedAt: 'v1',
    );
    final restored = TransactionModel.fromSheetRow(item.toSheetRow());
    expect(restored.transactionId, item.transactionId);
    expect(restored.title, item.title);
    expect(restored.amountMinor, item.amountMinor);
    expect(restored.date, item.date);
    expect(restored.time, item.time);
    expect(restored.updatedAt, startsWith('v1#'));
  });
  test('parser tolerates blanks, numeric text, bad rows and duplicate ids', () {
    final result = parsePhase4Transactions(<List<Object?>>[
      headers,
      <Object?>[],
      <Object?>[
        'a',
        'expense',
        'Food',
        '1250',
        'food',
        'Food',
        '2026-11-15',
        '09:30',
        '',
        '',
        'v1',
        'extra',
      ],
      <Object?>[
        'a',
        'expense',
        'Duplicate',
        '1250',
        'food',
        'Food',
        '2026-11-15',
        '09:30',
        '',
        '',
        'v2',
      ],
      <Object?>['bad', 'oops', 'Bad', 'nope'],
    ]);
    expect(result.transactions, hasLength(1));
    expect(result.transactions.single.amountMinor, 1250);
    expect(result.invalidRows, 2);
  });
}
