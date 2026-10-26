import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_scope.dart';

import '../models/set.dart';

/// Owns saved sets. A set only references move ids, so editing vocabulary
/// moves never corrupts a set.
class SetRepository extends ChangeNotifier {
  static const _storageKey = 'breaklog_sets_v1';

  List<MoveSet> _sets = const [];
  bool _loaded = false;

  bool get loaded => _loaded;
  List<MoveSet> get sets => List.unmodifiable(_sets);
  int get count => _sets.length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await UserScope.key(_storageKey);
    String? raw = prefs.getString(key);
    raw ??= prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _sets = decoded
            .whereType<Map<String, dynamic>>()
            .map(MoveSet.fromJson)
            .toList();
      } catch (_) {
        _sets = const [];
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(MoveSet set) async {
    _sets = [set, ..._sets];
    notifyListeners();
    await _persist();
  }

  Future<void> update(MoveSet set) async {
    _sets = _sets.map((s) => s.id == set.id ? set : s).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _sets = _sets.where((s) => s.id != id).toList();
    notifyListeners();
    await _persist();
  }

  MoveSet? byId(String id) => _sets.where((s) => s.id == id).firstOrNull;

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_sets.map((s) => s.toJson()).toList()),
    );
  }
}
