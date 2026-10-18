import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/move_repository.dart';
import 'update_notifier.dart';

/// App-wide composition root: the move library, update checks, and the
/// settings that gate them. Screens read through this provider.
class AppState extends ChangeNotifier {
  AppState({MoveRepository? repository, UpdateNotifier? updates})
      : moves = repository ?? MoveRepository(),
        updateNotifier = updates ?? UpdateNotifier();

  final MoveRepository moves;
  final UpdateNotifier updateNotifier;

  static const _betaKey = 'breaklog_beta_channel';

  bool _betaChannel = false;
  bool _inited = false;

  bool get betaChannel => _betaChannel;
  bool get inited => _inited;

  /// True when a newer release exists on the channel the user opted into.
  bool get hasUpdate => updateNotifier.hasUpdateOn(_betaChannel);

  Future<void> init() async {
    if (_inited) return;
    final prefs = await SharedPreferences.getInstance();
    _betaChannel = prefs.getBool(_betaKey) ?? false;
    await moves.load();
    _inited = true;
    notifyListeners();
    // Fire and forget: a failed check must not block the app shell.
    unawaitedCheck();
  }

  Future<void> setBetaChannel(bool enabled) async {
    _betaChannel = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_betaKey, enabled);
    notifyListeners();
    await checkForUpdates();
  }

  Future<void> checkForUpdates({bool force = false}) =>
      updateNotifier.check(
        includePrerelease: _betaChannel,
        enabled: true,
        force: force,
      );

  void unawaitedCheck() {
    checkForUpdates().catchError((_) {});
  }
}
