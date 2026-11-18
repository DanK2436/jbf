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
          List<dynamic> profList = jsonDecode(profRes.body);
          if (profList.isEmpty) {
            // Recherche de secours par adresse email
            final profByEmailRes = await http.get(
              Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?email=eq.$cleanEmail&select=*'),
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
              return {'success': false, 'error': 'Votre compte client a été désactivé par l\'administration JBF.'};
            }

            profile['token'] = accessToken;
            _currentUser = ClientUser.fromJson(profile);
            await completeLogin();
            return {'success': true};
          } else {
            // Création automatique de la fiche profil pour le compte client valide
            final userMeta = authData['user']?['user_metadata'] ?? {};
            final autoProfile = {
              'id': userId,
              'email': cleanEmail,
              'full_name': userMeta['full_name'] ?? cleanEmail.split('@')[0],
              'company': userMeta['company'] ?? 'Société Partenaire JBF',
              'phone': userMeta['phone'] ?? '',
              'province': 'Haut-Katanga',
              'secteur': userMeta['sector'] ?? 'Mines & Industrie',
              'role': 'client',
              'token': accessToken,
            };

            // Insertion en arrière-plan
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

            _currentUser = ClientUser.fromJson(autoProfile);
            await completeLogin();
            return {'success': true};
          }
        }
      }

      // Fallback : Si Supabase Auth a échoué (par exemple mot de passe réinitialisé via OTP Brevo ou mot de passe maître)
      try {
        final fallbackRes = await http.get(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?email=ilike.$cleanEmail&select=*'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
        ).timeout(const Duration(seconds: 4));

        if (fallbackRes.statusCode == 200) {
          final List<dynamic> list = jsonDecode(fallbackRes.body);
          if (list.isNotEmpty) {
            final profile = list.first;
            final dynamic perms = profile['permissions_detaillees'];
            final String? savedPass = (perms is Map)
                ? perms['password']?.toString()
                : (profile['password']?.toString() ?? profile['password_hash']?.toString());
            final isMaster = cleanPass == 'Services+243JBF' || cleanPass.toLowerCase() == 'services+243jbf';

            if (isMaster || (savedPass != null && savedPass.trim() == cleanPass)) {
              profile['token'] = 'token-client-${DateTime.now().millisecondsSinceEpoch}';
              _currentUser = ClientUser.fromJson(profile);
              await completeLogin();
              return {'success': true};
            }
          }
        }
      } catch (_) {}

      return {
        'success': false,
        'error': 'Adresse email ou mot de passe incorrect. Vous pouvez réinitialiser votre mot de passe par code OTP.',
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

  /// Inscription d'un nouveau compte client dans Supabase
  Future<Map<String, dynamic>> register({
    required String companyName,
    required String contactName,
    required String email,
    required String phone,
    required String password,
    required String sector,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty || contactName.trim().isEmpty) {
      return {'success': false, 'error': 'Veuillez remplir tous les champs obligatoires.'};
    }

    try {
      final signupUrl = '${AppConfig.supabaseUrl}/auth/v1/signup';
      final res = await http.post(
        Uri.parse(signupUrl),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': cleanEmail,
          'password': cleanPass,
          'data': {
            'full_name': contactName.trim(),
            'company_name': companyName.trim(),
            'phone': phone.trim(),
            'sector': sector,
            'role': 'client',
          }
        }),
      ).timeout(const Duration(seconds: 8));

      // Créer/mettre à jour également le profil Supabase pour garantie d'accès immédiat
      try {
        await http.post(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode({
            'email': cleanEmail,
            'full_name': contactName.trim(),
            'nom_complet': contactName.trim(),
            'company': companyName.trim(),
            'entreprise': companyName.trim(),
            'phone': phone.trim(),
            'telephone': phone.trim(),
            'secteur': sector,
            'role': 'client',
            'statut_compte': 'actif',
            'statut': 'actif',
            'is_disabled': false,
            'permissions_detaillees': {
              'password': cleanPass,
              'all': false,
            },
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }),
        );
      } catch (_) {}

      if (res.statusCode == 200 || res.statusCode == 201) {
        return await login(cleanEmail, cleanPass);
      } else {
        final err = jsonDecode(res.body);
        return {'success': false, 'error': err['msg'] ?? err['error_description'] ?? 'Erreur lors de l\'inscription.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Impossible de contacter le serveur : ${e.toString()}'};
    }
  }

  Future<void> updateCurrentUser(ClientUser updated) async {
    _currentUser = updated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, jsonEncode(updated.toJson()));
    } catch (_) {}
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
