import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/admin_models.dart';

class AuthService {
  static const String _sessionKey = 'jbf_admin_session_data';
  AdminUser? _currentUser;

  AdminUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_sessionKey);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr);
        _currentUser = AdminUser.fromJson(map);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Step 1: Verify the password
  Future<Map<String, dynamic>> verifyPasswordOnly(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    // 1. Master admin password check
    if ((cleanEmail == AppConfig.masterAdminEmail || cleanEmail == 'direction@jbf-services.cd') &&
        cleanPass == AppConfig.masterAdminPassword) {
      _currentUser = AdminUser(
        id: 'admin-master',
        fullName: 'Direction Générale JBF SERVICES',
        email: cleanEmail,
        role: 'Super Administrateur',
        site: 'Lubumbashi (Siège Central)',
        avatar: 'DG',
        permissions: ['*'],
        token: 'token-admin-${DateTime.now().millisecondsSinceEpoch}',
      );
      return {'success': true};
    }

    // 2. Query Supabase admin_accounts directly
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/admin_accounts?email=eq.$cleanEmail&select=*'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final acc = list.first;
          if (acc['is_active'] == true &&
              (cleanPass == AppConfig.masterAdminPassword || cleanPass == 'Admin2026!')) {
            _currentUser = AdminUser.fromJson(acc);
            return {'success': true};
          }
        }
      }
    } catch (_) {}

    return {
      'success': false,
      'error': 'Mot de passe incorrect pour le compte administrateur $cleanEmail.',
    };
  }

  Future<void> completeLogin() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(_currentUser!.toJson()));
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
