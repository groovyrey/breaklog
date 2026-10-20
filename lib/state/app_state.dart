import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../services/auth_service.dart';
import '../services/breaklog_api.dart';
import '../services/category_repository.dart';
import '../services/move_repository.dart';
import '../services/note_repository.dart';
import '../services/set_repository.dart';
import 'update_notifier.dart';

/// What a profile save did, so the screen can say it plainly.
enum ProfileSaveOutcome {
  /// Reached the account.
  saved,

  /// Kept on this device only; the account catches up at the next sign in.
  localOnly,

  /// Refused: the weekly window is still shut.
  tooSoon,

  /// A save was already running.
  busy,
}

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
    NoteRepository? notes,
    UpdateNotifier? updates,
    AuthService? auth,
    BreaklogApi? api,
  })  : moves = moves ?? MoveRepository(),
        categories = categories ?? CategoryRepository(),
        sets = sets ?? SetRepository(),
        notes = notes ?? NoteRepository(),
        updateNotifier = updates ?? UpdateNotifier(),
        auth = auth ?? AuthService(),
        api = api ?? BreaklogApi() {
    // Re-broadcast repository changes so a single watch(AppState) rebuilds
    // any screen that reads any repository.
    for (final repo in <Listenable>[
      this.moves,
      this.categories,
      this.sets,
      this.notes,
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

  /// Journal notes written from Home, on this device only.
  final NoteRepository notes;
  final UpdateNotifier updateNotifier;
  final AuthService auth;

  /// Client for the worker that stores the account. The library itself never
  /// leaves this device.
  final BreaklogApi api;

  static const _betaKey = 'breaklog_beta_channel';
  static const _aliasKey = 'breaklog_alias_v1';
  static const _startedKey = 'breaklog_started_v1';
  static const _whyKey = 'breaklog_why_v1';
  static const _profileUpdatedKey = 'breaklog_profile_updated_v1';

  bool _betaChannel = false;
  String _alias = '';
  DateTime? _startedAt;
  String _why = '';
  bool _inited = false;
  bool _registering = false;
  bool _profileSaving = false;
  DateTime? _profileUpdatedAt;
  bool _wasSignedIn = false;
  bool _online = true;
  Timer? _connectivity;

  bool get betaChannel => _betaChannel;
  bool get inited => _inited;

  /// False while the accounts backend cannot be reached. The library is local,
  /// so the app stays usable; this only flags that the account is out of sync.
  bool get online => _online;

  /// The name the user battles under.
  String get alias => _alias;

  /// The day the user started breaking, if they have set it.
  DateTime? get startedAt => _startedAt;

  /// Why the user breaks.
  String get why => _why;

  /// True while a profile save is running, so Save cannot be tapped twice.
  bool get profileSaving => _profileSaving;

  /// When profile edits open again, or null while they are open right now.
  DateTime? get profileLockEndsAt {
    final at = _profileUpdatedAt;
    if (at == null) return null;
    final ends = at.add(AppConfig.profileCooldown);
    return ends.isAfter(DateTime.now()) ? ends : null;
  }

  /// True while the weekly window is shut and a save would be refused.
  bool get profileLocked => profileLockEndsAt != null;

  /// True when a newer release exists on the channel the user opted into.
  bool get hasUpdate => updateNotifier.hasUpdateOn(_betaChannel);

  Future<void> init() async {
    if (_inited) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _betaChannel = prefs.getBool(_betaKey) ?? false;
      _alias = prefs.getString(_aliasKey) ?? '';
      _startedAt = _parseDate(prefs.getString(_startedKey));
      _why = prefs.getString(_whyKey) ?? '';
      final profileUpdated = prefs.getInt(_profileUpdatedKey);
      if (profileUpdated != null) {
        _profileUpdatedAt = DateTime.fromMillisecondsSinceEpoch(profileUpdated);
      }
      await Future.wait([
        moves.load(),
        categories.load(),
        sets.load(),
        notes.load(),
        auth.init(),
      ]);
    } catch (error, stack) {
      // An empty library that recovers beats a spinner that never resolves, so
      // a failed load must not trap startup. Report it rather than swallow it.
      debugPrint('BreakLog init failed: $error\n$stack');
    }
    _inited = true;
    notifyListeners();
    _wasSignedIn = auth.signedIn;
    if (auth.signedIn) unawaited(_register());
    unawaitedCheck();
    _watchConnectivity();
  }

  void _watchConnectivity() {
    _checkConnectivity();
    _connectivity?.cancel();
    _connectivity = Timer.periodic(
      const Duration(seconds: 25),
      (_) => _checkConnectivity(),
    );
  }

  Future<void> _checkConnectivity() async {
    final reachable = await api.ping();
    if (reachable == _online) return;
    _online = reachable;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivity?.cancel();
    super.dispose();
  }

  /// Saves the profile on this device and, when signed in, on the account.
  /// The weekly window is checked first, so a refused save changes nothing.
  Future<ProfileSaveOutcome> saveProfile({
    required String alias,
    DateTime? startedAt,
    required String why,
  }) async {
    if (_profileSaving) return ProfileSaveOutcome.busy;
    if (profileLocked) return ProfileSaveOutcome.tooSoon;

    _profileSaving = true;
    notifyListeners();
    try {
      _alias = alias.trim();
      _startedAt = startedAt;
      _why = why.trim();
      final started = _formatDate(_startedAt);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_aliasKey, _alias);
      await prefs.setString(_whyKey, _why);
      if (started == null) {
        await prefs.remove(_startedKey);
      } else {
        await prefs.setString(_startedKey, started);
      }
      notifyListeners();

      // The edit is spent here, online or not, so the device cannot keep
      // reopening the window while the account stays behind.
      await _markProfileUpdated(DateTime.now());

      final token = await auth.idToken();
      if (token == null) {
        return ProfileSaveOutcome.localOnly;
      }
      try {
        final row = await api.saveProfile(
          token,
          alias: _alias,
          startedAt: started,
          why: _why,
        );
        await _adoptAccountProfileUpdated(row['profileUpdatedAt']);
        return ProfileSaveOutcome.saved;
      } on ProfileCooldownException catch (error) {
        // Another device got there first. The account's clock is the real one.
        final nextAt = error.nextAt;
        await _markProfileUpdated(
          nextAt == null
              ? DateTime.now()
              : nextAt.subtract(AppConfig.profileCooldown),
        );
        return ProfileSaveOutcome.tooSoon;
      } on Exception {
        return ProfileSaveOutcome.localOnly;
      }
    } finally {
      _profileSaving = false;
      notifyListeners();
    }
  }

  Future<void> _markProfileUpdated(DateTime at) async {
    _profileUpdatedAt = at;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_profileUpdatedKey, at.millisecondsSinceEpoch);
  }

  /// Adopts the account's edit time, which this device cannot know on its own.
  Future<void> _adoptAccountProfileUpdated(Object? epoch) async {
    if (epoch is! int) return;
    final at = DateTime.fromMillisecondsSinceEpoch(epoch);
    if (_profileUpdatedAt != null && !at.isAfter(_profileUpdatedAt!)) return;
    await _markProfileUpdated(at);
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static String? _formatDate(DateTime? value) {
    if (value == null) return null;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}-$month-$day';
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

  /// Registers the account after a sign in, sending what this device already
  /// has and adopting anything the account has that this device lacks.
  Future<void> _register() async {
    if (_registering) return;
    _registering = true;
    try {
      final token = await auth.idToken();
      if (token == null) return;
      final row = await api.session(
        token,
        alias: _alias.isEmpty ? null : _alias,
        startedAt: _formatDate(_startedAt),
        why: _why.isEmpty ? null : _why,
      );

      final prefs = await SharedPreferences.getInstance();

      final remoteAlias = row['alias'];
      if (_alias.isEmpty && remoteAlias is String && remoteAlias.isNotEmpty) {
        _alias = remoteAlias;
        await prefs.setString(_aliasKey, _alias);
      }

      final remoteStarted = row['startedAt'];
      final started = remoteStarted is String ? _parseDate(remoteStarted) : null;
      if (_startedAt == null && started != null) {
        _startedAt = started;
        await prefs.setString(_startedKey, remoteStarted as String);
      }

      final remoteWhy = row['why'];
      if (_why.isEmpty && remoteWhy is String && remoteWhy.isNotEmpty) {
        _why = remoteWhy;
        await prefs.setString(_whyKey, _why);
      }

      await _adoptAccountProfileUpdated(row['profileUpdatedAt']);
      notifyListeners();
    } on Exception {
      // Signing in offline is fine. The account catches up on the next sign in.
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
