import 'dart:async';

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

  test('row fingerprint detects a direct edit in Google Sheets', () {
    final row = <Object?>[
      'a',
      'expense',
      'Food',
      1250,
      'food',
      'Food',
      '2026-11-15T09:30:00',
      '',
      '',
      '',
      'v1',
    ];
    final version = TransactionModel.fromSheetRow(row).updatedAt;
    final edited = List<Object?>.of(row)..[2] = 'Edited in Sheets';
    expect(TransactionModel.fromSheetRow(edited).updatedAt, isNot(version));
  });

  test(
    'unknown append outcome checks for the committed ID before retry',
    () async {
      var attempts = 0;
      var stored = false;
      await appendWithIdempotencyCheck(
        append: () async {
          attempts++;
          stored = true;
          throw TimeoutException('write committed but response timed out');
        },
        alreadyExists: () async => stored,
        wait: (_) async {},
      );
      expect(attempts, 1);
    },
  );

  test(
    'unknown append retries only after confirming the row is absent',
    () async {
      var attempts = 0;
      var stored = false;
      await appendWithIdempotencyCheck(
        append: () async {
          attempts++;
          if (attempts == 1) throw TimeoutException('not committed');
          stored = true;
        },
        alreadyExists: () async => stored,
        wait: (_) async {},
      );
      expect(attempts, 2);
      expect(stored, isTrue);
    },
  );
}
