import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/auth_failure.dart';
import '../../core/storage/cache_manager.dart';
import '../../services/google_auth_service.dart';
import 'auth_state.dart';

final Provider<GoogleAuthService> googleAuthServiceProvider =
    Provider<GoogleAuthService>((Ref ref) => GoogleAuthService());

final NotifierProvider<AuthController, AuthState> authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  late final GoogleAuthService _service;
  late final CacheManager _cacheManager;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  bool _onboarding = false;

  @override
  AuthState build() {
    _service = ref.read(googleAuthServiceProvider);
    _cacheManager = ref.read(cacheManagerProvider);
    ref.onDispose(() => _subscription?.cancel());
    unawaited(_restore());
    return const AuthRestoring();
  }

  Future<void> _restore() async {
    try {
      _onboarding = !_cacheManager.onboardingComplete;
      await _service.initialize();
      _subscription = _service.authenticationEvents.listen(
        (GoogleSignInAuthenticationEvent event) {
          switch (event) {
            case GoogleSignInAuthenticationEventSignIn(:final user):
              unawaited(_handleAccountChanged(user));
            case GoogleSignInAuthenticationEventSignOut():
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

  Future<void> _handleAccountChanged(GoogleSignInAccount user) async {
    final AuthState current = state;
    if (current is AuthSignedIn && current.user.id == user.id) {
      return;
    }
    try {
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
    } catch (error) {
      state = AuthReconnectRequired(
        user,
        error is AuthFailure ? error : const AuthUnknownFailure(),
      );
    }
  }

  /// Validates session status when the application returns to foreground.
  Future<void> handleAppResumed() async {
    if (state is! AuthSignedIn && state is! AuthReconnectRequired) return;

    try {
      final authorization = await _service.authorizationForScopes();
      if (authorization == null) {
        final GoogleSignInAccount? user = _service.account;
        if (user != null) {
          state = AuthNeedsAuthorization(
            user,
            failure: const AuthPermissionRevoked(),
            onboarding: _onboarding,
          );
        } else {
          state = AuthSignedOut(onboarding: _onboarding);
        }
        return;
      }

      if (state is AuthReconnectRequired) {
        final GoogleSignInAccount? user = _service.account;
        if (user != null) {
          final String result = await _service.verifyDriveAccess();
          state = AuthSignedIn(
            user: user,
            grantedScopes: googleDriveFileScopes,
            tokenTestResult: result,
          );
        }
      }
    } on AuthFailure catch (failure) {
      final GoogleSignInAccount? user = _service.account;
      if (user != null) {
        state = AuthReconnectRequired(user, failure);
      } else {
        state = AuthSignedOut(failure: failure, onboarding: _onboarding);
      }
    } catch (_) {
      // Retain current session on transient network blips.
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
    await _cacheManager.clearConnection();
    state = const AuthSignedOut();
  }

  Future<void> completeOnboarding() async {
    await _cacheManager.setOnboardingComplete(true);
    _onboarding = false;
    final AuthState current = state;
    if (current is AuthSignedOut) {
      state = AuthSignedOut(failure: current.failure);
    } else if (current is AuthNeedsAuthorization) {
      state = AuthNeedsAuthorization(current.user, failure: current.failure);
    }
  }
}
