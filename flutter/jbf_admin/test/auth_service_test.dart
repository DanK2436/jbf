import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jbf_admin/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le mot de passe maître local ne suffit plus', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService(httpClient: MockClient((request) async {
      return http.Response(jsonEncode({'error_code': 'invalid_credentials', 'msg': 'Invalid login credentials'}), 400);
    }));
    final res = await auth.verifyPasswordOnly('services@admin.jbf', 'Services+243JBF');
    expect(res['success'], false);
    expect(res['error'].toString(), contains('ancien mot de passe'));
    expect(auth.isLoggedIn, false);
  });

  test('un compte authentifié sans rôle admin est refusé', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService(httpClient: MockClient((request) async {
      if (request.url.path.contains('/token')) {
        return http.Response(jsonEncode({
          'access_token': 'aaa.bbb.ccc',
          'user': {'id': 'u1'},
        }), 200);
      }
      if (request.url.path.contains('admin_accounts')) {
        return http.Response('[]', 200);
      }
      return http.Response(jsonEncode([
        {'id': 'u1', 'email': 'a@exemple.test', 'role': 'client', 'full_name': 'A'}
      ]), 200);
    }));
    final res = await auth.verifyPasswordOnly('a@exemple.test', 'secret');
    expect(res['success'], false);
  });
}
