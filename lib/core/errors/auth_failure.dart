sealed class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

final class AuthCancelled extends AuthFailure {
  const AuthCancelled([super.message = 'Google sign-in was cancelled.']);
}

final class AuthNetworkFailure extends AuthFailure {
  const AuthNetworkFailure([
    super.message = 'Check your internet connection and try again.',
  ]);
}

final class AuthPlayServicesFailure extends AuthFailure {
  const AuthPlayServicesFailure([
    super.message = 'Google Play services is missing or needs an update.',
  ]);
}

final class AuthScopeDenied extends AuthFailure {
  const AuthScopeDenied([
    super.message =
        'Drive access was not approved. You can retry whenever you are ready.',
  ]);
}

final class AuthTokenExpired extends AuthFailure {
  const AuthTokenExpired([
    super.message = 'Your Google access expired. Reconnect to continue.',
  ]);
}

final class AuthPermissionRevoked extends AuthFailure {
  const AuthPermissionRevoked([
    super.message = 'Google access was revoked. Reconnect to continue.',
  ]);
}

final class AuthUnknownFailure extends AuthFailure {
  const AuthUnknownFailure([
    super.message = 'Google sign-in could not be completed. Please try again.',
  ]);
}
