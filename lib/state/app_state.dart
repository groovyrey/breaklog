import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/breaklog_api.dart';
import '../services/category_repository.dart';
import '../services/move_repository.dart';
import '../services/set_repository.dart';
import 'update_notifier.dart';

/// App-wide composition root.
///
/// Widgets watch this one object. Every repository below re-emits through
/// [notifyListeners], so a favorite toggle in one screen refreshes every other
/// screen that reads app state.
class AppState extends ChangeNotifier {
  AppState({
    MoveRepository? moves,
    CategoryRepository? categories,
    SetRepository? sets,
    UpdateNotifier? updates,
    AuthService? auth,
    BreaklogApi? api,
  })  : moves = moves ?? MoveRepository(),
        categories = categories ?? CategoryRepository(),
        sets = sets ?? SetRepository(),
        updateNotifier = updates ?? UpdateNotifier(),
        auth = auth ?? AuthService(),
        api = api ?? BreaklogApi() {
    // Re-broadcast repository changes so a single watch(AppState) rebuilds
    // any screen that reads any repository.
    for (final repo in <Listenable>[
      this.moves,
      this.categories,
      this.sets,
      updateNotifier,
      this.auth,
    ]) {
      repo.addListener(notifyListeners);
    }
    this.auth.addListener(_onAuthChanged);
  }

  final MoveRepository moves;
  final CategoryRepository categories;
  final SetRepository sets;
  final UpdateNotifier updateNotifier;
  final AuthService auth;

  /// Client for the worker that stores the account. The library itself never
  /// leaves this device.
  final BreaklogApi api;

  static const _betaKey = 'breaklog_beta_channel';
  static const _aliasKey = 'breaklog_alias_v1';

  bool _betaChannel = false;
  String _alias = '';
  bool _inited = false;
  bool _registering = false;
  bool _aliasPending = false;
  bool _wasSignedIn = false;

  bool get betaChannel => _betaChannel;
  bool get inited => _inited;

  /// The name the user battles under.
  String get alias => _alias;

  /// True when the saved alias has not reached the account yet, which happens
  /// when the device is offline. The next sign in retries it.
  bool get aliasPending => _aliasPending;

  /// True when a newer release exists on the channel the user opted into.
  bool get hasUpdate => updateNotifier.hasUpdateOn(_betaChannel);

  Future<void> init() async {
    if (_inited) return;
    final prefs = await SharedPreferences.getInstance();
    _betaChannel = prefs.getBool(_betaKey) ?? false;
    _alias = prefs.getString(_aliasKey) ?? '';
    await Future.wait([
      moves.load(),
      categories.load(),
      sets.load(),
      auth.init(),
    ]);
    _inited = true;
    notifyListeners();
    _wasSignedIn = auth.signedIn;
    if (auth.signedIn) await _register();
    unawaitedCheck();
  }

  /// Saves the alias on this device and, when signed in, on the account.
  Future<void> setAlias(String value) async {
    _alias = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aliasKey, _alias);
    notifyListeners();

    final token = await auth.idToken();
    if (token == null) {
      _aliasPending = true;
      notifyListeners();
      return;
    }
    try {
      await api.saveProfile(token, _alias);
      _aliasPending = false;
    } on Exception {
      _aliasPending = true;
    }
    notifyListeners();
  }

  Future<void> setBetaChannel(bool enabled) async {
    _betaChannel = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_betaKey, enabled);
    notifyListeners();
    await checkForUpdates();
  }

  Future<void> checkForUpdates({bool force = false}) => updateNotifier.check(
        includePrerelease: _betaChannel,
        enabled: true,
        force: force,
      );

  void unawaitedCheck() {
    checkForUpdates().catchError((_) {});
  }

  /// Registers the account after a sign in and adopts the alias stored for it
  /// when this device has none.
  Future<void> _register() async {
    if (_registering) return;
    _registering = true;
    try {
      final token = await auth.idToken();
      if (token == null) return;
      final row = await api.session(
        token,
        alias: _alias.isEmpty ? null : _alias,
      );
      final remoteAlias = row['alias'];
      if (_alias.isEmpty && remoteAlias is String && remoteAlias.isNotEmpty) {
        _alias = remoteAlias;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_aliasKey, _alias);
      } else if (_alias.isNotEmpty) {
        _aliasPending = false;
      }
      notifyListeners();
    } on Exception {
      // Signing in offline is fine. The account catches up on the next sign in.
      _aliasPending = _alias.isNotEmpty;
    } finally {
      _registering = false;
    }
  }

  void _onAuthChanged() {
    final signedIn = auth.signedIn;
    if (signedIn == _wasSignedIn) return;
    _wasSignedIn = signedIn;
    if (signedIn) _register();
  }
}
