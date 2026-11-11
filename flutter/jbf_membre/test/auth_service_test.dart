import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jbf_membre/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('un matricule seul ne réussit pas', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService(httpClient: MockClient((request) async {
      return http.Response('{}', 500);
    }));
    final res = await auth.verifyPasswordOnly('JBF-M-2026-012', 'nimporte');
    expect(res['success'], false);
    expect(auth.isLoggedIn, false);
  });

  test('un rôle membre authentifié ouvre la session sans solde inventé', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService(httpClient: MockClient((request) async {
      if (request.url.path.contains('/token')) {
        return http.Response(jsonEncode({
          'access_token': 'aaa.bbb.ccc',
          'user': {'id': 'm1'},
        }), 200);
      }
      return http.Response(jsonEncode([
        {'id': 'm1', 'email': 'agent@exemple.test', 'full_name': 'Agent', 'role': 'membre'}
      ]), 200);
    }));
    final res = await auth.verifyPasswordOnly('agent@exemple.test', 'secret');
    expect(res['success'], true);
    expect(auth.currentUser?.soldeConges, -1);
    expect(auth.currentUser?.fullName, 'Agent');
  });
}
