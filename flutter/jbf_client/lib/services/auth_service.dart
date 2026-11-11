import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/client_models.dart';

class AuthService {
  static const String _sessionKey = 'jbf_client_session_data';
  final http.Client _http;
  ClientUser? _currentUser;

  AuthService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  ClientUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_sessionKey);
      if (jsonStr == null) return false;
      final map = jsonDecode(jsonStr);
      final token = (map['token'] ?? '').toString();
      if (!token.contains('.')) return false;
      _currentUser = ClientUser.fromJson(map);
      return true;
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password;
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || cleanPass.isEmpty) {
      return {'success': false, 'error': 'Veuillez saisir l\'email du compte et le mot de passe.'};
    }

    final signed = await _passwordGrant(cleanEmail, cleanPass);
    if (signed['success'] != true) return signed;

    final profile = await _loadProfile(signed['userId'] as String, signed['token'] as String);
    if (profile == null) {
      return {
        'success': false,
        'error': 'Compte authentifié, mais le profil client est introuvable ou refusé.',
      };
    }
    final role = (profile['role'] ?? '').toString().toLowerCase();
    if (role != 'client') {
      return {
        'success': false,
        'error': 'Ce compte n\'a pas le rôle client. Connexion refusée.',
      };
    }

    _currentUser = ClientUser.fromJson({
      ...profile,
      'email': profile['email'] ?? cleanEmail,
      'token': signed['token'],
      'role': 'client',
    });
    await completeLogin();
    return {'success': true};
  }

  Future<Map<String, dynamic>> register({
    required String companyName,
    required String contactName,
    required String email,
    required String phone,
    required String password,
    String? sector,
    String? site,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || companyName.trim().isEmpty || password.length < 8) {
      return {
        'success': false,
        'error': 'Email, société et mot de passe (8 caractères minimum) sont requis.',
      };
    }

    try {
      final res = await _http.post(
        Uri.parse('${AppConfig.supabaseUrl}/auth/v1/signup'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': cleanEmail,
          'password': password,
          'data': {
            'full_name': contactName.trim(),
            'company': companyName.trim(),
            'phone': phone.trim(),
            'role': 'client',
            'secteur': sector,
            'site': site,
          },
        }),
      ).timeout(const Duration(seconds: 12));
      final data = _asMap(res.body);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return {
          'success': false,
          'error': _authError(data) ?? 'Création du compte refusée par le service.',
        };
      }
      final token = data['access_token']?.toString();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'error': 'Le compte est enregistré. Confirmez l\'email avant de vous connecter. Aucune session n\'est ouverte.',
        };
      }
      return login(cleanEmail, password);
    } catch (_) {
      return {
        'success': false,
        'error': 'Le service d\'inscription est injoignable. Aucun compte local n\'a été créé.',
      };
    }
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
        return {
          'success': false,
          'error': _authError(data) ?? 'Identifiants refusés.',
        };
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
