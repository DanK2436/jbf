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

    // 1. Master admin credentials
    if (cleanEmail == AppConfig.masterAdminEmail && cleanPass == AppConfig.masterAdminPassword) {
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
      await completeLogin();
      return {'success': true};
    }

    // 2. Check Supabase Auth
    try {
      final authUrl = '${AppConfig.supabaseUrl}/auth/v1/token?grant_type=password';
      final authRes = await http.post(
        Uri.parse(authUrl),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': cleanEmail,
          'password': cleanPass,
        }),
      ).timeout(const Duration(seconds: 6));

      if (authRes.statusCode == 200) {
        final authData = jsonDecode(authRes.body);
        final accessToken = authData['access_token'];
        final userId = authData['user']?['id'];

        // Vérifier dans profiles
        final profRes = await http.get(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.$userId&select=*'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer $accessToken',
          },
        );

        if (profRes.statusCode == 200) {
          final List<dynamic> list = jsonDecode(profRes.body);
          if (list.isNotEmpty) {
            final p = list.first;
            final role = p['role']?.toString().toLowerCase() ?? '';
            if (role == 'admin' || role == 'sous_admin' || role == 'super_admin') {
              _currentUser = AdminUser(
                id: p['id']?.toString() ?? userId,
                fullName: p['full_name'] ?? 'Administrateur JBF',
                email: cleanEmail,
                role: role == 'sous_admin' ? 'Sous-Administrateur' : 'Super Administrateur',
                site: p['province'] ?? 'Lubumbashi',
                avatar: (p['full_name'] ?? 'AD').toString().substring(0, 2).toUpperCase(),
                permissions: (p['permissions'] as List?)?.map((e) => e.toString()).toList() ?? ['*'],
                token: accessToken,
              );
              await completeLogin();
              return {'success': true};
            }
          }
        }
      }
    } catch (_) {}

    // 3. Fallback: Query Supabase admin_accounts table
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
          if (acc['is_active'] == true && (acc['password'] == cleanPass || acc['password_hash'] == cleanPass)) {
            _currentUser = AdminUser.fromJson(acc);
            await completeLogin();
            return {'success': true};
          }
        }
      }
    } catch (_) {}

    return {
      'success': false,
      'error': 'Identifiants administrateur incorrects ou compte non autorisé.',
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
