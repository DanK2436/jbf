import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/membre_models.dart';

class AuthService {
  static const String _sessionKey = 'jbf_membre_session_data';
  final http.Client _http;
  MembreUser? _currentUser;
  String? _pendingEmail;

  AuthService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  MembreUser? get currentUser => _currentUser;
  String? get pendingEmail => _pendingEmail;
  bool get isLoggedIn => _currentUser != null;

  static bool isMemberRole(String role) {
    final value = role.trim().toLowerCase();
    return value == 'membre' || value == 'member' || value == 'collaborateur';
  }

  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_sessionKey);
      if (jsonStr == null) return false;
      final map = jsonDecode(jsonStr);
      final token = (map['token'] ?? '').toString();
      if (!token.contains('.')) return false;
      _currentUser = MembreUser.fromJson(map);
      return true;
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>> verifyPasswordOnly(String identifier, String password) async {
    final cleanId = identifier.trim();
    final cleanPass = password;
    if (!cleanId.contains('@')) {
      return {
        'success': false,
        'error': 'La connexion membre exige l\'email du compte. Un matricule seul ne vérifie pas le mot de passe.',
      };
    }
    if (cleanPass.isEmpty) {
      return {'success': false, 'error': 'Mot de passe requis.'};
    }

    final signed = await _passwordGrant(cleanId.toLowerCase(), cleanPass);
    if (signed['success'] != true) return signed;

    final profile = await _loadProfile(signed['userId'] as String, signed['token'] as String);
    if (profile == null) {
      return {
        'success': false,
        'error': 'Compte authentifié, mais le profil membre est introuvable ou refusé.',
      };
    }
    final role = (profile['role'] ?? '').toString();
    if (!isMemberRole(role)) {
      return {'success': false, 'error': 'Ce compte n\'a pas le rôle membre. Accès refusé.'};
    }

    _currentUser = MembreUser.fromJson({
      ...profile,
      'email': profile['email'] ?? cleanId.toLowerCase(),
      'role': role,
      'token': signed['token'],
    });
    _pendingEmail = _currentUser!.email;
    return {'success': true, 'user': _currentUser, 'email': _pendingEmail};
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

  Future<Map<String, dynamic>?> _loadProfile(String userId, String token) async {
    try {
      final res = await _http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.$userId&select=*'),
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
