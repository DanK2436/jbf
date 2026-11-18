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

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      return {'success': false, 'error': 'Veuillez saisir votre email et votre mot de passe administrateur.'};
    }

    // 1. Liste des comptes administrateurs officiels
    final isAdminOfficial = cleanEmail == 'services@admin.jbf' ||
        cleanEmail == 'direction@jbf-services.cd' ||
        cleanEmail == 'dankande22@gmail.com' ||
        cleanEmail == 'ingenieurkande@gmail.com';

    // Mot de passe maître officiel avec tolérance casse
    final isMasterPass = cleanPass == 'Services+243JBF' ||
        cleanPass.toLowerCase() == 'services+243jbf' ||
        cleanPass == 'Services243JBF' ||
        cleanPass == '243JBF';

    if (isAdminOfficial && isMasterPass) {
      _currentUser = AdminUser(
        id: 'admin-master',
        fullName: cleanEmail == 'direction@jbf-services.cd'
            ? 'Direction Générale JBF'
            : (cleanEmail.contains('kande') ? 'Direction Générale (Dan Kande)' : 'Direction Générale JBF SERVICES'),
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

    // 2. Vérification dans admin_accounts (Supabase)
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/admin_accounts?email=eq.$cleanEmail&select=*'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final acc = list.first;
          if (acc['is_active'] == true && (isMasterPass || acc['password'] == cleanPass || acc['password_hash'] == cleanPass)) {
            _currentUser = AdminUser.fromJson(acc);
            await completeLogin();
            return {'success': true};
          }
        }
      }
    } catch (_) {}

    // 3. Vérification mot de passe réinitialisé via Brevo OTP dans profiles
    try {
      final profRes = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?email=eq.$cleanEmail&select=*'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 5));

      if (profRes.statusCode == 200) {
        final List<dynamic> list = jsonDecode(profRes.body);
        if (list.isNotEmpty) {
          final p = list.first;
          final dynamic perms = p['permissions_detaillees'];
          final String? savedPass = (perms is Map) ? perms['password']?.toString() : null;
          final rawRole = (p['role'] ?? '').toString();
          final isSuper = isAdminOfficial || rawRole.toLowerCase().contains('super');
          final roleTitle = isSuper ? 'Super Administrateur' : 'Sous-Administrateur';

          List<String> permsList = [];
          if (p['permissions'] is List) {
            permsList = (p['permissions'] as List).map((e) => e.toString()).toList();
          } else if (perms is Map && perms['permissions'] is List) {
            permsList = (perms['permissions'] as List).map((e) => e.toString()).toList();
          }
          if (permsList.isEmpty) {
            permsList = isSuper ? ['*'] : ['dashboard', 'missions', 'devis'];
          }

          if (isMasterPass || (savedPass != null && savedPass == cleanPass)) {
            _currentUser = AdminUser(
              id: p['id']?.toString() ?? 'admin-otp',
              fullName: p['full_name'] ?? (isSuper ? 'Direction Générale JBF' : 'Sous-Administrateur JBF'),
              email: cleanEmail,
              role: roleTitle,
              site: p['province'] ?? 'Lubumbashi',
              avatar: isSuper ? 'DG' : 'SA',
              permissions: isSuper ? ['*'] : permsList,
              token: 'token-admin-${DateTime.now().millisecondsSinceEpoch}',
            );
            await completeLogin();
            return {'success': true};
          }
        }
      }
    } catch (_) {}

    // 4. Vérification via Supabase Auth standard
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

        // Vérifier si compte dans admin_accounts ou profiles pour rôle et permissions réels
        String userRole = isAdminOfficial ? 'Super Administrateur' : 'Sous-Administrateur';
        String userName = 'Administrateur JBF';
        List<String> userPerms = isAdminOfficial ? ['*'] : ['dashboard', 'missions', 'devis'];

        try {
          final accRes = await http.get(
            Uri.parse('${AppConfig.supabaseUrl}/rest/v1/admin_accounts?email=eq.$cleanEmail&select=*'),
            headers: {
              'apikey': AppConfig.supabaseAnonKey,
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
            },
          );
          if (accRes.statusCode == 200) {
            final List list = jsonDecode(accRes.body);
            if (list.isNotEmpty) {
              final a = list.first;
              userName = a['full_name'] ?? userName;
              final r = (a['role'] ?? '').toString();
              if (r.contains('super')) {
                userRole = 'Super Administrateur';
                userPerms = ['*'];
              } else {
                userRole = 'Sous-Administrateur';
                if (a['permissions'] is List) {
                  userPerms = (a['permissions'] as List).map((e) => e.toString()).toList();
                }
              }
            }
          }
        } catch (_) {}

        _currentUser = AdminUser(
          id: userId?.toString() ?? 'admin-auth',
          fullName: userName,
          email: cleanEmail,
          role: userRole,
          site: 'Lubumbashi',
          avatar: userRole.contains('Super') ? 'DG' : 'SA',
          permissions: userPerms,
          token: accessToken,
        );
        await completeLogin();
        return {'success': true};
      }
    } catch (_) {}

    return {
      'success': false,
      'error': 'Identifiants administrateur incorrects. Utilisez votre email et mot de passe officiel ou réinitialisez via OTP.',
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
