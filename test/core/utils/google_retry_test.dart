import 'dart:math';

import 'package:expense_journal_budget/core/errors/app_failure.dart';
import 'package:expense_journal_budget/core/utils/google_retry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retries retryable failures and returns the eventual value', () async {
    int calls = 0;
    final int result = await retryGoogleRequest<int>(
      () async {
        calls++;
        if (calls < 3) {
          throw const AppFailure(AppFailureKind.server, 'temporary');
        }
        return 42;
      },
      random: Random(1),
      wait: (_) async {},
    );
    expect(result, 42);
    expect(calls, 3);
  });

  test('does not retry non-retryable permission failures', () async {
    int calls = 0;
    await expectLater(
      retryGoogleRequest<void>(() async {
        calls++;
        throw const AppFailure(
          AppFailureKind.permission,
          'denied',
          statusCode: 403,
        );
      }, wait: (_) async {}),
      throwsA(isA<AppFailure>()),
    );
    expect(calls, 1);
  });
}
