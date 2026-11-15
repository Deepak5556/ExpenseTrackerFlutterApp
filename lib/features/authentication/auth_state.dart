import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/auth_failure.dart';

sealed class AuthState {
  const AuthState();
  bool get onboardingRequired => false;
  bool get isBusy => false;
  GoogleSignInAccount? get account => null;
}

final class AuthRestoring extends AuthState {
  const AuthRestoring();
}

final class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.failure, this.onboarding = false});
  final AuthFailure? failure;
  final bool onboarding;
  @override
  bool get onboardingRequired => onboarding;
}

final class AuthBusy extends AuthState {
  const AuthBusy({required this.onboarding, required this.step});
  final bool onboarding;
  final String step;
  @override
  bool get onboardingRequired => onboarding;
  @override
  bool get isBusy => true;
}

final class AuthNeedsAuthorization extends AuthState {
  const AuthNeedsAuthorization(
    this.user, {
    this.failure,
    this.onboarding = false,
  });
  final GoogleSignInAccount user;
  final AuthFailure? failure;
  final bool onboarding;
  @override
  GoogleSignInAccount get account => user;
  @override
  bool get onboardingRequired => onboarding;
}

final class AuthSignedIn extends AuthState {
  const AuthSignedIn({
    required this.user,
    required this.grantedScopes,
    required this.tokenTestResult,
  });
  final GoogleSignInAccount user;
  final List<String> grantedScopes;
  final String tokenTestResult;
  @override
  GoogleSignInAccount get account => user;
}

final class AuthReconnectRequired extends AuthState {
  const AuthReconnectRequired(this.user, this.failure);
  final GoogleSignInAccount user;
  final AuthFailure failure;
  @override
  GoogleSignInAccount get account => user;
}
