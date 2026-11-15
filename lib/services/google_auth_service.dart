import 'dart:async';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as google_auth;

import '../core/errors/auth_failure.dart';

const List<String> googleDriveFileScopes = <String>[
  'https://www.googleapis.com/auth/drive.file',
];

/// Keeps Google credentials in the platform sign-in SDK. No token is persisted
/// by this app or included in logs, errors, or UI.
class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? signIn})
    : _signIn = signIn ?? GoogleSignIn.instance;

  final GoogleSignIn _signIn;
  static Future<void>? _initialization;
  static GoogleSignInAccount? _account;
  static StreamSubscription<GoogleSignInAuthenticationEvent>? _events;

  GoogleSignInAccount? get account => _account;
  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      _signIn.authenticationEvents;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    const String serverClientId = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
    );
    if (!serverClientId.endsWith('.apps.googleusercontent.com')) {
      throw const AuthUnknownFailure(
        'Google OAuth is not configured. Start the app with '
        '--dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com.',
      );
    }
    await _signIn.initialize(serverClientId: serverClientId);
    _events ??= _signIn.authenticationEvents.listen(
      (GoogleSignInAuthenticationEvent event) {
        _account = switch (event) {
          GoogleSignInAuthenticationEventSignIn(:final user) => user,
          GoogleSignInAuthenticationEventSignOut() => null,
        };
      },
      onError: (Object _) {
        // Deliberately omit exception details: some native errors may contain
        // credential material. The controller exposes a safe, typed message.
      },
    );
  }

  Future<GoogleSignInAccount?> restore() async {
    await initialize();
    try {
      _account = await _signIn.attemptLightweightAuthentication();
      return _account;
    } on GoogleSignInException catch (error) {
      if (_isCancellation(error)) return null;
      throw _mapFailure(error);
    } on SocketException {
      throw const AuthNetworkFailure();
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  Future<GoogleSignInAccount> authenticate() async {
    await initialize();

    if (!_signIn.supportsAuthenticate()) {
      throw const AuthUnknownFailure(
        'Google sign-in is not supported on this platform.',
      );
    }

    try {
      _account = await _signIn.authenticate();
      return _account!;
    } on GoogleSignInException catch (error) {
      debugPrint('Google Sign-In code: ${error.code}');

      throw _mapFailure(error);
    } on SocketException {
      throw const AuthNetworkFailure();
    } catch (error) {
      debugPrint(
        'Google Sign-In unexpected failure type: ${error.runtimeType}',
      );
      throw _mapFailure(error);
    }
  }

  /// Convenience for explicit user actions in the existing spreadsheet
  /// connection flow. Account selection and consent are both user initiated.
  Future<GoogleSignInAccount> signIn() async {
    final GoogleSignInAccount user = _account ?? await authenticate();
    await requestScopes();
    return user;
  }

  /// Returns null when the requested scope is not yet granted. This path is
  /// silent and safe to call just before each Google API request.
  Future<GoogleSignInClientAuthorization?> authorizationForScopes() async {
    await initialize();
    final GoogleSignInAccount? user = _account;
    if (user == null) return null;
    try {
      return await user.authorizationClient.authorizationForScopes(
        googleDriveFileScopes,
      );
    } on GoogleSignInException catch (error) {
      throw _mapFailure(error);
    } on SocketException {
      throw const AuthNetworkFailure();
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  /// User-initiated OAuth consent. Call only from a tap handler.
  Future<GoogleSignInClientAuthorization> requestScopes() async {
    await initialize();
    final GoogleSignInAccount? user = _account;
    if (user == null) {
      throw const AuthUnknownFailure('Choose a Google account first.');
    }
    try {
      final GoogleSignInClientAuthorization? existing = await user
          .authorizationClient
          .authorizationForScopes(googleDriveFileScopes);
      return existing ??
          await user.authorizationClient.authorizeScopes(googleDriveFileScopes);
    } on GoogleSignInException catch (error) {
      if (_isCancellation(error)) throw const AuthScopeDenied();
      throw _mapFailure(error);
    } on SocketException {
      throw const AuthNetworkFailure();
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  /// Creates a fresh AuthClient from a just-in-time authorization result.
  Future<google_auth.AuthClient> authorizedClient({
    bool allowPrompt = false,
  }) async {
    await initialize();
    final GoogleSignInClientAuthorization? authorization =
        await authorizationForScopes();
    if (authorization != null) {
      return authorization.authClient(scopes: googleDriveFileScopes);
    }
    if (allowPrompt) {
      final GoogleSignInClientAuthorization prompted = await requestScopes();
      return prompted.authClient(scopes: googleDriveFileScopes);
    }
    throw const AuthScopeDenied();
  }

  /// Harmless Phase 2 connectivity proof: reads only the current user's
  /// Drive profile summary, and returns the visible account name/email.
  Future<String> verifyDriveAccess({bool allowPrompt = false}) async {
    for (int attempt = 0; attempt < 2; attempt++) {
      final google_auth.AuthClient client = await authorizedClient(
        allowPrompt: attempt == 0 && allowPrompt,
      );
      try {
        final drive.About about = await drive.DriveApi(client).about
            .get($fields: 'user');
        final drive.User? user = about.user;
        return user?.emailAddress ??
            user?.displayName ??
            'Google Drive connected';
      } catch (error) {
        final String message = error.toString().toLowerCase();
        if (message.contains('403') || message.contains('forbidden')) {
          throw const AuthPermissionRevoked();
        }
        if (message.contains('401') || message.contains('unauthenticated')) {
          if (attempt == 0) continue; // Re-request a fresh token silently once.
          throw const AuthTokenExpired();
        }
        if (error is SocketException || message.contains('socketexception')) {
          throw const AuthNetworkFailure();
        }
        throw const AuthUnknownFailure(
          'Could not verify Google Drive access. Try reconnecting.',
        );
      } finally {
        client.close();
      }
    }
    throw const AuthTokenExpired();
  }

  Future<void> signOut() async {
    await initialize();
    try {
      await _signIn.signOut();
      _account = null;
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  /// Revokes the app's Google authorization as well as ending the local session.
  Future<void> disconnect() async {
    await initialize();
    try {
      await _signIn.disconnect();
      _account = null;
    } catch (error) {
      throw _mapFailure(error);
    }
  }

  Future<GoogleSignInAccount> reconnect() => authenticate();

  static bool _isCancellation(Object error) {
    return error is GoogleSignInException &&
        error.code.name.toLowerCase().contains('cancel');
  }

  static AuthFailure _mapFailure(Object error) {
    if (error is AuthFailure) return error;
    if (error is SocketException) return const AuthNetworkFailure();
    if (error is GoogleSignInException) {
      final String code = error.code.name.toLowerCase();
      if (code.contains('cancel')) return const AuthCancelled();
      if (code.contains('playservices') || code.contains('play_services')) {
        return const AuthPlayServicesFailure();
      }
      if (code.contains('providerconfiguration')) {
        return const AuthPlayServicesFailure();
      }
      if (code.contains('network')) return const AuthNetworkFailure();
      if (code.contains('clientconfiguration')) {
        return const AuthUnknownFailure(
          'Google setup needs attention. Check the OAuth package name, SHA-1, and Web client ID.',
        );
      }
    }
    final String description = error.toString().toLowerCase();
    if (description.contains('play services')) {
      return const AuthPlayServicesFailure();
    }
    if (description.contains('socketexception') ||
        description.contains('network')) {
      return const AuthNetworkFailure();
    }
    return const AuthUnknownFailure();
  }
}
