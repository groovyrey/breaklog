import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/battle_stages.dart';
import '../models/battle.dart';

/// Owns the battle plans the user is working on. Persisted as JSON in
/// shared_preferences, like the rest of the library.
class BattleRepository extends ChangeNotifier {
  static const _storageKey = 'breaklog_battle_plans_v1';
  static const _legacyKey = 'breaklog_battle_plan_v1';

  List<BattlePlan> _plans = const [];
  bool _loaded = false;

  bool get loaded => _loaded;

  /// Every plan, nearest event first.
  List<BattlePlan> get plans {
    final sorted = [..._plans]..sort((a, b) => a.eventAt.compareTo(b.eventAt));
    return List.unmodifiable(sorted);
  }

  BattlePlan? byId(String id) {
    for (final plan in _plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      _plans = _parseList(raw);
    } else {
      final legacy = prefs.getString(_legacyKey);
      final migrated = legacy == null || legacy.isEmpty
          ? null
          : _parseOne(legacy);
      if (migrated != null) {
        _plans = [migrated];
        await _persist();
        await prefs.remove(_legacyKey);
      }
    }
    _loaded = true;
    notifyListeners();
  }

  /// Adds a plan seeded with the common stages, each at its usual rounds.
  Future<BattlePlan> start({
    required String name,
    required DateTime eventAt,
  }) async {
    final plan = BattlePlan(
      id: _newId(),
      name: name.trim(),
      eventAt: eventAt,
      stages: [
        for (final stage in defaultBattleStages)
          PlannedStage(stage: stage, rounds: defaultRoundsFor(stage)),
      ],
      updatedAt: DateTime.now(),
    );
    _plans = [plan, ..._plans];
    notifyListeners();
    await _persist();
    return plan;
  }

  Future<void> save(BattlePlan plan) async {
    final stamped = plan.copyWith(updatedAt: DateTime.now());
    final index = _plans.indexWhere((p) => p.id == stamped.id);
    _plans = index < 0
        ? [stamped, ..._plans]
        : ([..._plans]..[index] = stamped);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _plans = _plans.where((p) => p.id != id).toList();
    notifyListeners();
    await _persist();
  }

  List<BattlePlan> _parseList(String raw) {
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(BattlePlan.fromJson)
          .map(_withId)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  BattlePlan? _parseOne(String raw) {
    try {
      return _withId(BattlePlan.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    } catch (_) {
      return null;
    }
  }

  /// Plans written before multiple plans existed have no id.
  BattlePlan _withId(BattlePlan plan) =>
      plan.id.isEmpty ? plan.copyWith(id: _newId()) : plan;

  static String _newId() => 'plan-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_plans.isEmpty) {
      await prefs.remove(_storageKey);
      return;
    }
    await prefs.setString(
      _storageKey,
      jsonEncode(_plans.map((plan) => plan.toJson()).toList()),
    );
  }
}
