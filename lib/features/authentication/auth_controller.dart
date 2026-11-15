import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/auth_failure.dart';
import '../../services/google_auth_service.dart';
import 'auth_state.dart';

final Provider<GoogleAuthService> googleAuthServiceProvider =
    Provider<GoogleAuthService>((Ref ref) => GoogleAuthService());

final NotifierProvider<AuthController, AuthState> authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  late final GoogleAuthService _service;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  bool _onboarding = false;

  @override
  AuthState build() {
    _service = ref.read(googleAuthServiceProvider);
    ref.onDispose(() => _subscription?.cancel());
    unawaited(_restore());
    return const AuthRestoring();
  }

  Future<void> _restore() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      _onboarding = !(preferences.getBool('onboarding_complete') ?? false);
      await _service.initialize();
      _subscription = _service.authenticationEvents.listen(
        (GoogleSignInAuthenticationEvent event) {
          if (event case GoogleSignInAuthenticationEventSignOut()) {
            state = AuthSignedOut(onboarding: _onboarding);
          }
        },
        onError: (Object _) {
          state = AuthSignedOut(onboarding: _onboarding);
        },
      );
      final GoogleSignInAccount? user = await _service.restore();
      if (user == null) {
        state = AuthSignedOut(onboarding: _onboarding);
        return;
      }
      final authorization = await _service.authorizationForScopes();
      if (authorization == null) {
        state = AuthNeedsAuthorization(user, onboarding: _onboarding);
        return;
      }
      final String result = await _service.verifyDriveAccess();
      state = AuthSignedIn(
        user: user,
        grantedScopes: googleDriveFileScopes,
        tokenTestResult: result,
      );
    } on AuthFailure catch (failure) {
      final GoogleSignInAccount? user = _service.account;
      state = user == null
          ? AuthSignedOut(failure: failure, onboarding: _onboarding)
          : AuthReconnectRequired(user, failure);
    } catch (_) {
      state = AuthSignedOut(
        failure: const AuthUnknownFailure(),
        onboarding: _onboarding,
      );
    }
  }

  Future<void> signIn() async {
    final AuthState previous = state;
    final bool onboarding = previous.onboardingRequired;
    state = AuthBusy(
      onboarding: onboarding,
      step: 'Connecting your Google account…',
    );
    try {
      final GoogleSignInAccount user = await _service.authenticate();
      state = AuthBusy(
        onboarding: onboarding,
        step: 'Requesting Drive access…',
      );
      await _service.requestScopes();
      state = AuthBusy(
        onboarding: onboarding,
        step: 'Checking the connection…',
      );
      final String result = await _service.verifyDriveAccess();
      state = AuthSignedIn(
        user: user,
        grantedScopes: googleDriveFileScopes,
        tokenTestResult: result,
      );
    } on AuthFailure catch (failure) {
      final GoogleSignInAccount? user = _service.account;
      if (user != null &&
          (failure is AuthTokenExpired || failure is AuthPermissionRevoked)) {
        state = AuthReconnectRequired(user, failure);
      } else {
        state = user == null
            ? AuthSignedOut(failure: failure, onboarding: onboarding)
            : AuthNeedsAuthorization(
                user,
                failure: failure,
                onboarding: onboarding,
              );
      }
    } catch (_) {
      state = AuthSignedOut(
        failure: const AuthUnknownFailure(),
        onboarding: onboarding,
      );
    }
  }

  Future<void> authorizeAndContinue() async {
    final AuthState previous = state;
    final GoogleSignInAccount? user = previous.account;
    if (user == null) return signIn();
    state = AuthBusy(
      onboarding: previous.onboardingRequired,
      step: 'Requesting Drive access…',
    );
    try {
      await _service.requestScopes();
      final String result = await _service.verifyDriveAccess();
      state = AuthSignedIn(
        user: user,
        grantedScopes: googleDriveFileScopes,
        tokenTestResult: result,
      );
    } on AuthFailure catch (failure) {
      state = failure is AuthTokenExpired || failure is AuthPermissionRevoked
          ? AuthReconnectRequired(user, failure)
          : AuthNeedsAuthorization(
              user,
              failure: failure,
              onboarding: previous.onboardingRequired,
            );
    } catch (_) {
      state = AuthNeedsAuthorization(
        user,
        failure: const AuthUnknownFailure(),
        onboarding: previous.onboardingRequired,
      );
    }
  }

  Future<void> reconnect() async {
    state = const AuthBusy(onboarding: false, step: 'Reconnecting to Google…');
    try {
      final GoogleSignInAccount user = await _service.reconnect();
      await _service.requestScopes();
      final String result = await _service.verifyDriveAccess();
      state = AuthSignedIn(
        user: user,
        grantedScopes: googleDriveFileScopes,
        tokenTestResult: result,
      );
    } on AuthFailure catch (failure) {
      final GoogleSignInAccount? user = _service.account;
      state = user == null
          ? AuthSignedOut(failure: failure)
          : AuthReconnectRequired(user, failure);
    } catch (_) {
      final GoogleSignInAccount? user = _service.account;
      state = user == null
          ? const AuthSignedOut(failure: AuthUnknownFailure())
          : AuthReconnectRequired(user, const AuthUnknownFailure());
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AuthSignedOut();
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    state = const AuthSignedOut();
  }

  Future<void> completeOnboarding() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_complete', true);
    _onboarding = false;
    final AuthState current = state;
    if (current is AuthSignedOut) {
      state = AuthSignedOut(failure: current.failure);
    } else if (current is AuthNeedsAuthorization) {
      state = AuthNeedsAuthorization(current.user, failure: current.failure);
    }
  }
}
