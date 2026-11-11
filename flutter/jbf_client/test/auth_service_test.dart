import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jbf_client/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('un profil relié par user_id ouvre la session client', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService(httpClient: MockClient((request) async {
      if (request.url.path.contains('/token')) {
        return http.Response(jsonEncode({
          'access_token': 'aaa.bbb.ccc',
          'user': {'id': 'user-9', 'email': 'a@exemple.test'},
        }), 200);
      }
      if (request.url.query.startsWith('id=eq.')) {
        return http.Response('[]', 200);
      }
      return http.Response(jsonEncode([
        {'id': 'profil-9', 'user_id': 'user-9', 'email': 'a@exemple.test', 'full_name': 'A', 'role': 'client', 'company': 'A SARL'}
      ]), 200);
    }));
    final res = await auth.login('a@exemple.test', 'motdepasse-reel');
    expect(res['success'], true);
    expect(auth.currentUser?.id, 'profil-9');
  });

  test('un mot de passe refusé n\'ouvre pas de session', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService(httpClient: MockClient((request) async {
      return http.Response(jsonEncode({'error_code': 'invalid_credentials', 'msg': 'Invalid login credentials'}), 400);
    }));
    final res = await auth.login('partenaire@mining-katanga.cd', 'Client2026!');
    expect(res['success'], false);
    expect(res['error'].toString(), contains('ancien mot de passe'));
    expect(auth.isLoggedIn, false);
  });

  test('un jeton valide avec un rôle client ouvre la session', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService(httpClient: MockClient((request) async {
      if (request.url.path.contains('/token')) {
        return http.Response(jsonEncode({
          'access_token': 'aaa.bbb.ccc',
          'user': {'id': 'user-1', 'email': 'a@exemple.test'},
        }), 200);
      }
      return http.Response(jsonEncode([
        {'id': 'user-1', 'email': 'a@exemple.test', 'full_name': 'A', 'role': 'client', 'company': 'A SARL'}
      ]), 200);
    }));
    final res = await auth.login('a@exemple.test', 'motdepasse-reel');
    expect(res['success'], true);
    expect(auth.currentUser?.role, 'client');
    expect(auth.currentUser?.companyName, 'A SARL');
  });

  test('un rôle non client est refusé', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = AuthService(httpClient: MockClient((request) async {
      if (request.url.path.contains('/token')) {
        return http.Response(jsonEncode({
          'access_token': 'aaa.bbb.ccc',
          'user': {'id': 'user-2'},
        }), 200);
      }
      return http.Response(jsonEncode([
        {'id': 'user-2', 'email': 'admin@exemple.test', 'role': 'admin'}
      ]), 200);
    }));
    final res = await auth.login('admin@exemple.test', 'secret');
    expect(res['success'], false);
    expect(auth.isLoggedIn, false);
  });
}
