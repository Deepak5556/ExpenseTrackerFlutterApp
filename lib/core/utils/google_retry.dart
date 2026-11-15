import 'dart:async';
import 'dart:math';

import '../errors/app_failure.dart';

typedef RetryDelay = Future<void> Function(Duration duration);

Future<T> retryGoogleRequest<T>(
  Future<T> Function() request, {
  int maxAttempts = 4,
  Duration timeout = const Duration(seconds: 20),
  RetryDelay? wait,
  Random? random,
}) async {
  final Random jitter = random ?? Random();
  final RetryDelay delay = wait ?? Future<void>.delayed;
  for (int attempt = 0; ; attempt++) {
    try {
      return await request().timeout(timeout);
    } catch (error) {
      final AppFailure failure = mapGoogleFailure(error);
      if (!failure.retryable || attempt + 1 >= maxAttempts) throw failure;
      final int exponentialMs = 250 * (1 << attempt);
      final int jitterMs = jitter.nextInt(251);
      await delay(Duration(milliseconds: exponentialMs + jitterMs));
    }
  }
}
