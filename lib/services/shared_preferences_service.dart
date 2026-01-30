import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyIsAdmin = 'is_admin';
  static const String _keyUserId = 'user_id';

  // Save login state
  static Future<void> saveLoginState({
    required bool isLoggedIn,
    required bool isAdmin,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
    await prefs.setBool(_keyIsAdmin, isAdmin);
    await prefs.setString(_keyUserId, userId);
  }

  // Get login state
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get admin status
  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsAdmin) ?? false;
  }

  // Get user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  // Clear login state (logout)
  static Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyIsAdmin);
    await prefs.remove(_keyUserId);
  }
}

