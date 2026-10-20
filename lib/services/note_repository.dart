import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/note.dart';

/// Owns the dated notes written from Home and persists them as JSON in
/// shared_preferences, like the rest of the library.
class NoteRepository extends ChangeNotifier {
  static const _storageKey = 'breaklog_notes_v1';

  List<LogNote> _notes = const [];
  bool _loaded = false;

  bool get loaded => _loaded;
  List<LogNote> get notes => List.unmodifiable(_notes);
  int get count => _notes.length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _notes = decoded
            .whereType<Map<String, dynamic>>()
            .map(LogNote.fromJson)
            .toList();
      } catch (_) {
        _notes = const [];
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(LogNote note) async {
    _notes = [note, ..._notes];
    notifyListeners();
    await _persist();
  }

  Future<void> update(LogNote note) async {
    _notes = _notes.map((n) => n.id == note.id ? note : n).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _notes = _notes.where((n) => n.id != id).toList();
    notifyListeners();
    await _persist();
  }

  /// Notes written on [day], ignoring the time of day they were written.
  List<LogNote> onDay(DateTime day, {String search = ''}) => _results(
        _notes.where((n) =>
            n.createdAt.year == day.year &&
            n.createdAt.month == day.month &&
            n.createdAt.day == day.day),
        search,
      );

  /// Notes whose body contains the search text, newest first.
  List<LogNote> query({String search = ''}) => _results(_notes, search);

  List<LogNote> _results(Iterable<LogNote> source, String search) {
    final needle = search.trim().toLowerCase();
    final matching = needle.isEmpty
        ? source.toList()
        : source
            .where((n) => n.body.toLowerCase().contains(needle))
            .toList();
    return matching..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_notes.map((n) => n.toJson()).toList()),
    );
  }
}
