import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/admin_models.dart';

class AuthService {
  static const String _sessionKey = 'jbf_admin_session_data';
  final http.Client _http;
  AdminUser? _currentUser;

  AuthService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  AdminUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  static bool isAdminRole(String role) {
    final value = role.trim().toLowerCase();
    return value == 'admin' ||
        value == 'super_admin' ||
        value == 'sous_admin' ||
        value.contains('administrateur');
  }

  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_sessionKey);
      if (jsonStr == null) return false;
      final map = jsonDecode(jsonStr);
      final token = (map['token'] ?? '').toString();
      if (!token.contains('.')) return false;
      final user = AdminUser.fromJson(map);
      if (!isAdminRole(user.role)) return false;
      _currentUser = user;
      return true;
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>> verifyPasswordOnly(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || password.isEmpty) {
      return {'success': false, 'error': 'Email et mot de passe requis.'};
    }

    final signed = await _passwordGrant(cleanEmail, password);
    if (signed['success'] != true) return signed;

    final profile = await _loadRow(
      'profiles?id=eq.${signed['userId']}&select=*',
      signed['token'] as String,
    );
    final account = await _loadRow(
      'admin_accounts?email=eq.$cleanEmail&select=*',
      signed['token'] as String,
    );
    final role = (account?['role'] ?? profile?['role'] ?? '').toString();
    if (!isAdminRole(role)) {
      return {
        'success': false,
        'error': 'Ce compte n\'a pas un rôle administrateur. Accès refusé.',
      };
    }
    if (account != null && account['is_active'] == false) {
      return {'success': false, 'error': 'Ce compte administrateur est désactivé.'};
    }

    final source = account ?? profile ?? <String, dynamic>{};
    _currentUser = AdminUser.fromJson({
      ...source,
      'id': source['id'] ?? signed['userId'],
      'email': source['email'] ?? cleanEmail,
      'role': role,
      'token': signed['token'],
      'permissions': source['permissions'] ?? <String>[],
    });
    return {'success': true};
  }

  Future<Map<String, dynamic>> _passwordGrant(String email, String password) async {
    try {
      final res = await _http.post(
        Uri.parse('${AppConfig.supabaseUrl}/auth/v1/token?grant_type=password'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 12));
      final data = _asMap(res.body);
      if (res.statusCode != 200) {
        return {'success': false, 'error': _authError(data) ?? 'Identifiants refusés.'};
      }
      final token = data['access_token']?.toString() ?? '';
      final user = data['user'];
      final userId = user is Map ? user['id']?.toString() ?? '' : '';
      if (token.isEmpty || userId.isEmpty) {
        return {'success': false, 'error': 'Réponse d\'authentification incomplète.'};
      }
      return {'success': true, 'token': token, 'userId': userId};
    } catch (_) {
      return {'success': false, 'error': 'Service d\'authentification injoignable.'};
    }
  }

  Future<Map<String, dynamic>?> _loadRow(String query, String token) async {
    try {
      final res = await _http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/$query'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final list = jsonDecode(res.body);
      if (list is List && list.isNotEmpty && list.first is Map) {
        return Map<String, dynamic>.from(list.first as Map);
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _asMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  String? _authError(Map<String, dynamic> data) {
    final msg = data['msg'] ?? data['error_description'] ?? data['message'] ?? data['error'];
    if (msg == null) return null;
    return msg.toString();
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
