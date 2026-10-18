import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';

/// Owns the move type list: the five built-in defaults plus anything the user
/// creates. Persisted so custom categories survive restarts.
class CategoryRepository extends ChangeNotifier {
  static const _storageKey = 'breaklog_categories_v1';

  List<MoveCategory> _categories = MoveCategory.defaults;
  bool _loaded = false;

  bool get loaded => _loaded;
  List<MoveCategory> get categories => List.unmodifiable(_categories);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final parsed = decoded
            .map(MoveCategory.fromJson)
            .where((c) => c.name.isNotEmpty)
            .toList();
        if (parsed.isNotEmpty) _categories = parsed;
      } catch (_) {
        // Keep defaults when storage is unreadable.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  bool exists(String name) => _categories.any(
      (c) => c.name.toLowerCase() == name.trim().toLowerCase());

  Future<bool> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || exists(trimmed)) return false;
    _categories = [..._categories, MoveCategory(trimmed)];
    notifyListeners();
    await _persist();
    return true;
  }

  Future<void> remove(String name) async {
    _categories = _categories.where((c) => c.name != name).toList();
    notifyListeners();
    await _persist();
  }

  /// Returns the name if the category exists, otherwise the first default.
  String resolve(String name) =>
      exists(name) ? name : (MoveCategory.defaults.firstOrNull?.name ?? '');

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_categories.map((c) => c.toJson()).toList()),
    );
  }
}
