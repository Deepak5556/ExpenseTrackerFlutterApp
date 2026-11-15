import 'dart:math';

import 'package:expense_journal_budget/core/errors/app_failure.dart';
import 'package:expense_journal_budget/core/utils/google_retry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retries transient server failures then returns the result', () async {
    int calls = 0;
    int waits = 0;
    final String result = await retryGoogleRequest<String>(
      () async {
        calls++;
        if (calls < 3) throw Exception('HTTP status 503');
        return 'ok';
      },
      wait: (Duration _) async {
        waits++;
      },
      random: Random(1),
    );
    expect(result, 'ok');
    expect(calls, 3);
    expect(waits, 2);
  });

  test('does not retry permission failures', () async {
    int calls = 0;
    await expectLater(
      retryGoogleRequest<void>(() async {
        calls++;
        throw const AppFailure(AppFailureKind.permission, 'denied');
      }, wait: (Duration _) async {}),
      throwsA(isA<AppFailure>()),
    );
    expect(calls, 1);
  });
}
