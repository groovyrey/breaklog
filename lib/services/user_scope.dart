import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserScope {
  static String get uid => FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  static Future<String> key(String base) async {
    final id = uid;
    if (id == 'guest') return base;
    return '${base}_$id';
  }

  static Future<String?> getString(String base) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(await key(base)) ?? prefs.getString(base);
  }

  static Future<void> setString(String base, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final k = await key(base);
    await prefs.setString(k, value);
  }

  static Future<void> remove(String base) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(await key(base));
  }
}
