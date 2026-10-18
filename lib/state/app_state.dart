import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  })  : moves = moves ?? MoveRepository(),
        categories = categories ?? CategoryRepository(),
        sets = sets ?? SetRepository(),
        updateNotifier = updates ?? UpdateNotifier() {
    // Re-broadcast repository changes so a single watch(AppState) rebuilds
    // any screen that reads any repository.
    for (final repo in <Listenable>[
      this.moves,
      this.categories,
      this.sets,
      updateNotifier,
    ]) {
      repo.addListener(notifyListeners);
    }
  }

  final MoveRepository moves;
  final CategoryRepository categories;
  final SetRepository sets;
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
    await Future.wait([
      moves.load(),
      categories.load(),
      sets.load(),
    ]);
    _inited = true;
    notifyListeners();
    unawaitedCheck();
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
}
