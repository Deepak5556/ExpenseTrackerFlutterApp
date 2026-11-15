import 'dart:io';

import 'package:expense_journal_budget/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps Google status codes and transport failures', () {
    expect(
      mapGoogleFailure(Exception('HTTP status 401')).kind,
      AppFailureKind.auth,
    );
    expect(
      mapGoogleFailure(Exception('HTTP status 403')).kind,
      AppFailureKind.permission,
    );
    expect(
      mapGoogleFailure(Exception('HTTP status 403 quota exceeded')).kind,
      AppFailureKind.quota,
    );
    expect(
      mapGoogleFailure(Exception('HTTP status 404')).kind,
      AppFailureKind.missing,
    );
    expect(
      mapGoogleFailure(Exception('HTTP status 429')).kind,
      AppFailureKind.rateLimit,
    );
    expect(
      mapGoogleFailure(Exception('HTTP status 503')).kind,
      AppFailureKind.server,
    );
    expect(
      mapGoogleFailure(const SocketException('offline')).kind,
      AppFailureKind.network,
    );
  });
}
