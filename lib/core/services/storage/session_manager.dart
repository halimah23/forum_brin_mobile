import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/auth/models/user_model.dart';

class SessionManager {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserData = 'user_data';
  static const String _keyUserRole = 'user_role';

  /// Menyimpan sesi dan data profil user ke SharedPreferences
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserData, jsonEncode(user.toJson()));
    if (user.role != null && user.role!.isNotEmpty) {
      await prefs.setString(_keyUserRole, user.role!.toLowerCase());
    }
  }

  /// Mengambil data user yang tersimpan di SharedPreferences
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyUserData);
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return UserModel.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  /// Mengambil role user dari SharedPreferences
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole);
  }

  /// Mengecek apakah ada sesi login aktif
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Membersihkan data sesi lokal (saat logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserData);
    await prefs.remove(_keyUserRole);
  }
}
