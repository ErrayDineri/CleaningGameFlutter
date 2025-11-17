import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _userNameKey = 'user_name';
  static const String _userLevelKey = 'user_level';
  static const String _userXpKey = 'user_xp';
  static const String _isFirstLaunchKey = 'is_first_launch';

  // XP required for each level (exponential growth)
  static int getXpForLevel(int level) {
    return (level * 100 * 1.5).round();
  }

  // Check if first launch
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(_isFirstLaunchKey) ?? true;
    
    if (isFirst) {
      await prefs.setBool(_isFirstLaunchKey, false);
    }
    
    return isFirst;
  }

  // Save user name
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    
    // Initialize level and XP if first time
    if (!prefs.containsKey(_userLevelKey)) {
      await prefs.setInt(_userLevelKey, 1);
      await prefs.setInt(_userXpKey, 0);
    }
  }

  // Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Get user level
  static Future<int> getUserLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userLevelKey) ?? 1;
  }

  // Get user XP
  static Future<int> getUserXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userXpKey) ?? 0;
  }

  // Add XP and check for level up
  static Future<bool> addXp(int xp) async {
    final prefs = await SharedPreferences.getInstance();
    final currentXp = await getUserXp();
    final currentLevel = await getUserLevel();
    
    final newXp = currentXp + xp;
    final xpNeeded = getXpForLevel(currentLevel);
    
    bool leveledUp = false;
    
    if (newXp >= xpNeeded) {
      // Level up!
      final remainingXp = newXp - xpNeeded;
      await prefs.setInt(_userLevelKey, currentLevel + 1);
      await prefs.setInt(_userXpKey, remainingXp);
      leveledUp = true;
    } else {
      await prefs.setInt(_userXpKey, newXp);
    }
    
    return leveledUp;
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    final name = await getUserName();
    final level = await getUserLevel();
    final xp = await getUserXp();
    final xpNeeded = getXpForLevel(level);
    
    return {
      'name': name ?? 'مستخدم',
      'level': level,
      'xp': xp,
      'xpNeeded': xpNeeded,
      'progress': xp / xpNeeded,
    };
  }

  // Reset user data (for testing)
  static Future<void> resetUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
    await prefs.remove(_userLevelKey);
    await prefs.remove(_userXpKey);
    await prefs.setBool(_isFirstLaunchKey, true);
  }
}
