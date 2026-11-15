import 'dart:async';
import 'dart:io';

enum AppFailureKind {
  auth,
  permission,
  quota,
  missing,
  rateLimit,
  server,
  timeout,
  network,
  invalid,
  unknown,
}

final class AppFailure implements Exception {
  const AppFailure(this.kind, this.message, {this.statusCode, this.cause});
  final AppFailureKind kind;
  final String message;
  final int? statusCode;
  final Object? cause;
  bool get retryable => <AppFailureKind>{
    AppFailureKind.quota,
    AppFailureKind.rateLimit,
    AppFailureKind.server,
    AppFailureKind.network,
    AppFailureKind.timeout,
  }.contains(kind);
  @override
  String toString() => message;
}

AppFailure mapGoogleFailure(Object error) {
  if (error is AppFailure) {
    return error;
  }
  if (error is TimeoutException) {
    return AppFailure(
      AppFailureKind.timeout,
      'Google request timed out.',
      cause: error,
    );
  }
  if (error is SocketException || error is HttpException) {
    return AppFailure(
      AppFailureKind.network,
      'Network connection failed.',
      cause: error,
    );
  }
  final String text = error.toString();
  final Match? match = RegExp(
    r'(?:status|code|response)\D{0,8}(\d{3})|\b(\d{3})\b',
    caseSensitive: false,
  ).firstMatch(text);
  final int? status = int.tryParse(match?.group(1) ?? match?.group(2) ?? '');
  if (status == 401) {
    return AppFailure(
      AppFailureKind.auth,
      'Google authorization expired. Reconnect and retry.',
      statusCode: status,
      cause: error,
    );
  }
  if (status == 403) {
    final bool quota =
        text.toLowerCase().contains('quota') ||
        text.toLowerCase().contains('rate limit');
    return AppFailure(
      quota ? AppFailureKind.quota : AppFailureKind.permission,
      quota
          ? 'Google API quota reached.'
          : 'Google denied access to this file.',
      statusCode: status,
      cause: error,
    );
  }
  if (status == 404) {
    return AppFailure(
      AppFailureKind.missing,
      'The spreadsheet could not be found.',
      statusCode: status,
      cause: error,
    );
  }
  if (status == 429) {
    return AppFailure(
      AppFailureKind.rateLimit,
      'Google is receiving too many requests.',
      statusCode: status,
      cause: error,
    );
  }
  if (status != null && status >= 500) {
    return AppFailure(
      AppFailureKind.server,
      'Google services are temporarily unavailable.',
      statusCode: status,
      cause: error,
    );
  }
  return AppFailure(
    AppFailureKind.unknown,
    'Google request failed. Please try again.',
    statusCode: status,
    cause: error,
  );
}
