import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_scope.dart';

import '../models/prep_item.dart';

/// Owns the battle prep checklist. Items keep their added order, with the
/// ticked ones sunk to the bottom so what is left to do stays on top.
class PrepRepository extends ChangeNotifier {
  static const _storageKey = 'breaklog_prep_v1';

  List<PrepItem> _items = const [];
  bool _loaded = false;

  bool get loaded => _loaded;

  /// Every item, open ones first in the order they were added.
  List<PrepItem> get items {
    final open = _items.where((item) => !item.done).toList();
    final done = _items.where((item) => item.done).toList();
    return List.unmodifiable([...open, ...done]);
  }

  int get openCount => _items.where((item) => !item.done).length;
  int get count => _items.length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await UserScope.key(_storageKey);
    String? raw = prefs.getString(key);
    raw ??= prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _items = decoded
            .whereType<Map<String, dynamic>>()
            .map(PrepItem.fromJson)
            .toList();
      } catch (_) {
        _items = const [];
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(PrepItem item) async {
    _items = [item, ..._items];
    notifyListeners();
    await _persist();
  }

  Future<void> update(PrepItem item) async {
    _items = _items.map((i) => i.id == item.id ? item : i).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _items = _items.where((i) => i.id != id).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_items.map((i) => i.toJson()).toList()),
    );
  }
}
