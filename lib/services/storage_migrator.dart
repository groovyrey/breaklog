import 'package:shared_preferences/shared_preferences.dart';

import 'user_scope.dart';

class StorageMigrator {
  static const _migratedKey = 'breaklog_storage_migrated_v2';

  static Future<void> migrate() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migratedKey) == true) return;
    final uid = UserScope.uid;
    if (uid == 'guest') return;

    final bases = [
      'breaklog_moves_v1',
      'breaklog_categories_v1',
      'breaklog_sets_v1',
      'breaklog_notes_v1',
      'breaklog_battle_v1',
      'breaklog_battle_sessions_v1',
      'breaklog_prep_v1',
      'breaklog_alias_v1',
      'breaklog_started_v1',
      'breaklog_why_v1',
      'breaklog_profile_updated_v1',
      'breaklog_reminders_v1',
    ];

    for (final base in bases) {
      final old = prefs.getString(base);
      if (old == null) continue;
      final newKey = '${base}_$uid';
      if (prefs.getString(newKey) == null) {
        await prefs.setString(newKey, old);
      }
    }

    final bools = ['breaklog_beta_channel'];
    for (final base in bools) {
      if (prefs.containsKey(base)) {
        final v = prefs.getBool(base);
        if (v != null && prefs.getBool('${base}_$uid') == null) {
          await prefs.setBool('${base}_$uid', v);
        }
      }
    }

    await prefs.setBool(_migratedKey, true);
  }

  static Future<void> clearUser(String base) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('${base}_')).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
