import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/client_models.dart';

class AuthService {
  static const String _sessionKey = 'jbf_client_session_data';
  ClientUser? _currentUser;

  ClientUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_sessionKey);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr);
        _currentUser = ClientUser.fromJson(map);
        // Vérifier si le compte est actif
        _verifyAccountStatus();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _verifyAccountStatus() async {
    if (_currentUser == null) return;
    try {
      final url = '${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.${_currentUser!.id}&select=is_disabled,statut_compte';
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final p = list.first;
          if (p['is_disabled'] == true || p['statut_compte'] == 'desactive') {
            await logout();
          }
        }
      }
    } catch (_) {}
  }

  /// Connexion Client Réelle via Supabase Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      return {'success': false, 'error': 'Veuillez renseigner votre email et mot de passe.'};
    }

    try {
      // 1. Appel Supabase Auth
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

        // 2. Récupération profil client réel
        final profileUrl = '${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.$userId&select=*';
        final profRes = await http.get(
          Uri.parse(profileUrl),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer $accessToken',
          },
        );

        if (profRes.statusCode == 200) {
          final List<dynamic> profList = jsonDecode(profRes.body);
          if (profList.isNotEmpty) {
            final profile = profList.first;
            if (profile['is_disabled'] == true || profile['statut_compte'] == 'desactive') {
              return {'success': false, 'error': 'Votre compte client a été désactivé par l\'administration JBF.'};
            }

            profile['token'] = accessToken;
            _currentUser = ClientUser.fromJson(profile);
            await completeLogin();
            return {'success': true};
          }
        }
      }

      // 3. Fallback compte démonstration officiel si configuré
      if (cleanEmail == AppConfig.defaultEmail && cleanPass == AppConfig.defaultPassword) {
        _currentUser = ClientUser(
          id: 'cli-demo-01',
          fullName: 'Direction des Opérations Minières',
          companyName: AppConfig.defaultCompany,
          email: cleanEmail,
          phone: '+243 970 349 724',
          sector: 'Catering Minier & BTP',
          site: 'Kolwezi / Tenke Fungurume',
          role: 'client',
          token: 'token-cli-${DateTime.now().millisecondsSinceEpoch}',
        );
        await completeLogin();
        return {'success': true};
      }

      return {
        'success': false,
        'error': 'Adresse email ou mot de passe incorrect. Veuillez vérifier vos identifiants.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Impossible de joindre le serveur d\'authentification : ${e.toString()}',
      };
    }
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
