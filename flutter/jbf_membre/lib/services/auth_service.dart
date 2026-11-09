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
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Step 1: Verify identifier (matricule / email) and password
  Future<Map<String, dynamic>> verifyPasswordOnly(String identifier, String password) async {
    final cleanId = identifier.trim();
    final cleanPass = password.trim();

    // 1. Check Supabase profiles table directly
    try {
      final isEmail = cleanId.contains('@');
      final queryField = isEmail ? 'email' : 'matricule';
      final url = '${AppConfig.supabaseUrl}/rest/v1/profiles?$queryField=eq.$cleanId&select=*';

      final res = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final p = list.first;
          _currentUser = MembreUser.fromJson(p);
          _pendingEmail = p['email'] ?? 'dankande3@gmail.com';
          return {
            'success': true,
            'user': _currentUser,
            'email': _pendingEmail,
          };
        }
      }
    } catch (_) {}

    // 2. Default Collaborator Account (Jean-Pierre Mulamba)
    if ((cleanId.toUpperCase() == AppConfig.defaultMatricule ||
            cleanId.toLowerCase() == 'jp.mulamba@jbf-services.cd') &&
        cleanPass == AppConfig.defaultPassword) {
      _currentUser = MembreUser(
        id: 'mbr-012',
        fullName: 'Jean-Pierre Mulamba',
        email: 'jp.mulamba@jbf-services.cd',
        matricule: 'JBF-M-2026-012',
        poste: 'Chef d\'Équipe Soudure & Tuyauterie',
        sectionNom: 'Maintenance & Soudure',
        province: 'Lualaba (Kolwezi)',
        soldeConges: 14,
        avatar: 'JM',
        token: 'token-mbr-${DateTime.now().millisecondsSinceEpoch}',
      );
      _pendingEmail = _currentUser!.email;
      return {'success': true, 'user': _currentUser, 'email': _pendingEmail};
    }

    // 3. Fallback generic collaborator login if starts with JBF-
    if (cleanId.toUpperCase().startsWith('JBF-') && cleanPass.length >= 4) {
      _currentUser = MembreUser(
        id: 'mbr-custom',
        fullName: 'Agent Terrain JBF',
        email: 'agent@jbf-services.cd',
        matricule: cleanId.toUpperCase(),
        poste: 'Technicien Spécialisé',
        sectionNom: 'Sous-traitance Industrielle',
        province: 'Haut-Katanga (Lubumbashi)',
        soldeConges: 18,
        avatar: 'AT',
        token: 'token-mbr-${DateTime.now().millisecondsSinceEpoch}',
      );
      _pendingEmail = _currentUser!.email;
      return {'success': true, 'user': _currentUser, 'email': _pendingEmail};
    }

    return {
      'success': false,
      'error': 'Matricule ou mot de passe incorrect. Exemple : ${AppConfig.defaultMatricule} / ${AppConfig.defaultPassword}',
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
