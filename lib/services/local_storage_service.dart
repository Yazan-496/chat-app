import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _lastEmailKey = 'last_email';
  static const _lastPasswordKey = 'last_password';
  static const _recentUidsKey = 'recent_uids';

  Future<void> saveLastEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastEmailKey, email);
  }

  Future<String?> getLastEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastEmailKey);
  }

  Future<void> saveLastPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPasswordKey, password);
  }

  Future<String?> getLastPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastPasswordKey);
  }

  Future<void> addRecentUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentUids = prefs.getStringList(_recentUidsKey) ?? [];
    if (!recentUids.contains(uid)) {
      recentUids.insert(0, uid); // Add to the beginning
      if (recentUids.length > 5) { // Keep only the last 5 recent UIDs
        recentUids = recentUids.sublist(0, 5);
      }
      await prefs.setStringList(_recentUidsKey, recentUids);
    }
  }

  Future<List<String>> getRecentUids() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentUidsKey) ?? [];
  }

  Future<void> removeRecentUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentUids = prefs.getStringList(_recentUidsKey) ?? [];
    recentUids.remove(uid);
    await prefs.setStringList(_recentUidsKey, recentUids);
  }

  Future<void> saveAvatarColor(String userId, int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('avatar_color_$userId', colorValue);
  }

  Future<int?> getAvatarColor(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('avatar_color_$userId');
  }

  Future<void> saveLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }

  Future<String?> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language_code');
  }
}
