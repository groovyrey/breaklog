import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_scope.dart';

import '../models/battle_session.dart';

/// Owns the recorded simulation sessions. Kept apart from the plans so a plan
/// edit never rewrites history, and persisted as JSON like the rest.
class BattleSessionRepository extends ChangeNotifier {
  static const _storageKey = 'breaklog_battle_sessions_v1';

  List<BattleSession> _sessions = const [];
  bool _loaded = false;

  bool get loaded => _loaded;

  /// Sessions for one plan, newest first.
  List<BattleSession> forPlan(String planId) {
    final matches = _sessions.where((s) => s.planId == planId).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return List.unmodifiable(matches);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await UserScope.key(_storageKey);
    String? raw = prefs.getString(key);
    raw ??= prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      _sessions = _parse(raw);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> save(BattleSession session) async {
    final tagged = session.id.isEmpty
        ? BattleSession(
            id: 'session-${DateTime.now().microsecondsSinceEpoch}',
            planId: session.planId,
            stages: session.stages,
            turnSeconds: session.turnSeconds,
            restSeconds: session.restSeconds,
            elapsedSeconds: session.elapsedSeconds,
            recordedAt: session.recordedAt,
            videoPath: session.videoPath,
          )
        : session;
    final index = _sessions.indexWhere((s) => s.id == tagged.id);
    _sessions = index < 0
        ? [tagged, ..._sessions]
        : ([..._sessions]..[index] = tagged);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _sessions = _sessions.where((s) => s.id != id).toList();
    notifyListeners();
    await _persist();
  }

  /// Drops every session attached to [planId], used when the plan is deleted.
  Future<void> removeForPlan(String planId) async {
    _sessions = _sessions.where((s) => s.planId != planId).toList();
    notifyListeners();
    await _persist();
  }

  List<BattleSession> _parse(String raw) {
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(BattleSession.fromJson)
          .where((session) => session.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_sessions.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }
    await prefs.setString(
      _storageKey,
      jsonEncode(_sessions.map((session) => session.toJson()).toList()),
    );
  }
}
