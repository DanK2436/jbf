import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/membre_models.dart';

class AuthService {
  static const String _sessionKey = 'jbf_membre_session_data';
  MembreUser? _currentUser;
  String? _pendingEmail;

  MembreUser? get currentUser => _currentUser;
  String? get pendingEmail => _pendingEmail;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_sessionKey);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr);
        _currentUser = MembreUser.fromJson(map);
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

  /// Authentification Réelle Collaborateur JBF via Supabase
  Future<Map<String, dynamic>> verifyPasswordOnly(String identifier, String password) async {
    final cleanId = identifier.trim();
    final cleanPass = password.trim();

    if (cleanId.isEmpty || cleanPass.isEmpty) {
      return {'success': false, 'error': 'Veuillez saisir votre matricule ou email et votre mot de passe.'};
    }

    try {
      String emailToAuth = cleanId;
      final isEmail = cleanId.contains('@');

      // 1. Si matricule fourni, retrouver l'email associé
      if (!isEmail) {
        final lookupUrl = '${AppConfig.supabaseUrl}/rest/v1/profiles?matricule=eq.$cleanId&select=email,is_disabled,statut_compte';
        final lookupRes = await http.get(
          Uri.parse(lookupUrl),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
        ).timeout(const Duration(seconds: 5));

        if (lookupRes.statusCode == 200) {
          final List<dynamic> list = jsonDecode(lookupRes.body);
          if (list.isNotEmpty) {
            final p = list.first;
            if (p['is_disabled'] == true || p['statut_compte'] == 'desactive') {
              return {'success': false, 'error': 'Votre compte a été désactivé par l\'administrateur JBF.'};
            }
            if (p['email'] != null && (p['email'] as String).isNotEmpty) {
              emailToAuth = p['email'];
            }
          } else {
            return {'success': false, 'error': 'Matricule non répertorié dans la base des agents JBF.'};
          }
        }
      }

      // 2. Authentification auprès de Supabase Auth
      final authUrl = '${AppConfig.supabaseUrl}/auth/v1/token?grant_type=password';
      final authRes = await http.post(
        Uri.parse(authUrl),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': emailToAuth,
          'password': cleanPass,
        }),
      ).timeout(const Duration(seconds: 6));

      if (authRes.statusCode == 200) {
        final authData = jsonDecode(authRes.body);
        final accessToken = authData['access_token'];
        final userId = authData['user']?['id'];

        // 3. Charger le profil réel
        List<dynamic> profList = [];
        final profileUrl = '${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.$userId&select=*';
        final profRes = await http.get(
          Uri.parse(profileUrl),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer $accessToken',
          },
        );

        if (profRes.statusCode == 200) {
          profList = jsonDecode(profRes.body);
        }

        // Si non trouvé par ID, chercher par email
        if (profList.isEmpty) {
          final profByEmailRes = await http.get(
            Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?email=eq.$emailToAuth&select=*'),
            headers: {
              'apikey': AppConfig.supabaseAnonKey,
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
            },
          );
          if (profByEmailRes.statusCode == 200) {
            final List<dynamic> emailList = jsonDecode(profByEmailRes.body);
            if (emailList.isNotEmpty) {
              profList = emailList;
            }
          }
        }

        if (profList.isNotEmpty) {
          final profile = profList.first;
          if (profile['is_disabled'] == true || profile['statut_compte'] == 'desactive') {
            return {'success': false, 'error': 'Votre compte a été désactivé par la Direction JBF.'};
          }

          profile['token'] = accessToken;
          _currentUser = MembreUser.fromJson(profile);
          _pendingEmail = profile['email'];
          await completeLogin();
          return {'success': true, 'user': _currentUser, 'email': _pendingEmail};
        } else {
          // Création automatique de la fiche profil membre
          final autoProfile = {
            'id': userId,
            'email': emailToAuth,
            'full_name': emailToAuth.split('@')[0],
            'matricule': !isEmail ? cleanId : 'JBF-M-2026',
            'poste': 'Collaborateur Terrain',
            'section_nom': 'Général',
            'province': 'Haut-Katanga',
            'role': 'membre',
            'token': accessToken,
          };

          try {
            await http.post(
              Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles'),
              headers: {
                'apikey': AppConfig.supabaseAnonKey,
                'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(autoProfile),
            );
          } catch (_) {}

          _currentUser = MembreUser.fromJson(autoProfile);
          _pendingEmail = emailToAuth;
          await completeLogin();
          return {'success': true, 'user': _currentUser, 'email': _pendingEmail};
        }
      }

      return {
        'success': false,
        'error': 'Matricule/Email ou mot de passe incorrect. Vérifiez vos accès auprès du service RH.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion au serveur : ${e.toString()}',
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
