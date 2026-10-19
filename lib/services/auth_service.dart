import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config.dart';

/// Google sign in through Firebase Auth.
///
/// google_sign_in produces the Google ID token, Firebase turns it into the
/// session the worker trusts, and the same Google session is asked for a Drive
/// access token when media is backed up.
class AuthService extends ChangeNotifier {
  AuthService({FirebaseAuth? firebase, GoogleSignIn? google})
      : _firebase = firebase ?? FirebaseAuth.instance,
        _google = google ?? GoogleSignIn.instance;

  final FirebaseAuth _firebase;
  final GoogleSignIn _google;

  bool _inited = false;
  bool _busy = false;
  String? _error;

  bool get configured => AppConfig.cloudConfigured;
  bool get signedIn => _firebase.currentUser != null;
  bool get busy => _busy;
  String? get error => _error;

  String get email => _firebase.currentUser?.email ?? '';
  String get displayName => _firebase.currentUser?.displayName ?? email;
  String get photoUrl => _firebase.currentUser?.photoURL ?? '';

  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    _firebase.authStateChanges().listen((_) => notifyListeners());
    if (!configured) return;
    await _google.initialize(serverClientId: AppConfig.googleServerClientId);
    if (signedIn) await _restoreGoogleSession();
  }

  Future<bool> signIn() async {
    if (!configured) {
      _error = 'This build has no Google client id';
      notifyListeners();
      return false;
    }
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw StateError('Google returned no id token');
      await _firebase
          .signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
      return true;
    } catch (error) {
      _error = _describe(error);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _google.signOut();
    } on Exception {
      // The local Google session is best effort; Firebase owns the session the
      // rest of the app reads.
    }
    await _firebase.signOut();
    _busy = false;
    notifyListeners();
  }

  /// Fresh ID token for the worker, or null when signed out.
  Future<String?> idToken() async {
    final user = _firebase.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  /// Access token for Drive, prompting for the scope the first time. Null means
  /// the user did not grant it.
  Future<String?> driveAccessToken() async {
    if (!configured) return null;
    final headers = await _google.authorizationClient
        .authorizationHeaders([AppConfig.driveScope], promptIfNecessary: true);
    final value = headers?['Authorization'] ?? headers?['authorization'];
    if (value == null) return null;
    return value.startsWith('Bearer ') ? value.substring(7) : value;
  }

  Future<void> _restoreGoogleSession() async {
    try {
      final attempt = _google.attemptLightweightAuthentication();
      if (attempt != null) await attempt;
    } on Exception {
      // Nothing to restore; Drive access can prompt on next use.
    }
  }

  String _describe(Object error) {
    if (error is GoogleSignInException) {
      return error.description ?? 'Google sign in failed';
    }
    if (error is FirebaseAuthException) {
      return error.message ?? error.code;
    }
    return error.toString();
  }
}
