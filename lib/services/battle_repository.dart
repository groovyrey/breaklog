import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/battle_stages.dart';
import '../models/battle.dart';

/// Owns the one battle plan the user works on. Persisted as JSON in
/// shared_preferences, like the rest of the library.
class BattleRepository extends ChangeNotifier {
  static const _storageKey = 'breaklog_battle_plan_v1';

  BattlePlan? _plan;
  bool _loaded = false;

  bool get loaded => _loaded;

  /// The plan being edited, or null when the user has not started one.
  BattlePlan? get plan => _plan;

  bool get hasPlan => _plan != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _plan = BattlePlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _plan = null;
      }
    }
    _loaded = true;
    notifyListeners();
  }

  /// Starts a plan seeded with the common stages, each at its usual rounds.
  Future<void> start({required String name, required DateTime eventAt}) async {
    _plan = BattlePlan(
      name: name.trim(),
      eventAt: eventAt,
      stages: [
        for (final stage in defaultBattleStages)
          PlannedStage(stage: stage, rounds: defaultRoundsFor(stage)),
      ],
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> save(BattlePlan plan) async {
    _plan = plan.copyWith(updatedAt: DateTime.now());
    notifyListeners();
    await _persist();
  }

  /// Clears the plan so the user can start another one.
  Future<void> clear() async {
    _plan = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _persist() async {
    final plan = _plan;
    if (plan == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(plan.toJson()));
  }
}
