import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/move.dart';

/// Owns the move list and persists it as JSON in shared_preferences.
///
/// One source of truth: every screen reads through this instance and calls
/// mutations here. [AppState] re-emits these notifications so widgets that
/// watch the app root rebuild on every add, edit, favorite, or delete.
class MoveRepository extends ChangeNotifier {
  static const _storageKey = 'breaklog_moves_v1';

  List<BboyMove> _moves = const [];
  bool _loaded = false;

  bool get loaded => _loaded;
  List<BboyMove> get moves => List.unmodifiable(_moves);

  int get count => _moves.length;
  int get favoriteCount => _moves.where((m) => m.favorite).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _moves = decoded
            .whereType<Map<String, dynamic>>()
            .map(BboyMove.fromJson)
            .toList();
      } catch (_) {
        _moves = const [];
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(BboyMove move) async {
    _moves = [move, ..._moves];
    notifyListeners();
    await _persist();
  }

  Future<void> update(BboyMove move) async {
    _moves = _moves.map((m) => m.id == move.id ? move : m).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _moves = _moves.where((m) => m.id != id).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> toggleFavorite(String id) async {
    _moves = _moves
        .map((m) => m.id == id ? m.copyWith(favorite: !m.favorite) : m)
        .toList();
    notifyListeners();
    await _persist();
  }

  BboyMove? byId(String id) => _moves.where((m) => m.id == id).firstOrNull;

  /// Always returns a fresh, growable list sorted newest-first so callers can
  /// sort or filter without touching the unmodifiable backing view.
  List<BboyMove> query({String search = '', String? category}) {
    final needle = search.trim().toLowerCase();
    var result = _moves.toList();
    if (category != null && category.isNotEmpty) {
      result = result.where((m) => m.category == category).toList();
    }
    if (needle.isNotEmpty) {
      result = result
          .where((m) =>
              m.name.toLowerCase().contains(needle) ||
              m.notes.toLowerCase().contains(needle))
          .toList();
    }
    return result..sort((a, b) => b.learnedAt.compareTo(a.learnedAt));
  }

  Map<String, int> countsByCategory() {
    final counts = <String, int>{};
    for (final m in _moves) {
      final key = m.category.isEmpty ? 'Uncategorised' : m.category;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  Map<MoveDepth, int> countsByDepth() {
    final counts = {for (final d in MoveDepth.values) d: 0};
    for (final m in _moves) {
      counts[m.depth] = (counts[m.depth] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_moves.map((m) => m.toJson()).toList()),
    );
  }
}
