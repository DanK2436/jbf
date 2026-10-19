import 'package:flutter_test/flutter_test.dart';
import 'package:jbf_portal_shell/jbf_portal_shell.dart';

void main() {
  test('filterIncomingAdminMessages keeps direct non-admin messages', () {
    final rows = [
      {
        'canal_type': 'direct',
        'user_id': 'chef-1',
        'message': 'Bonjour direction',
        'expediteur_nom': 'Chef A',
      },
      {
        'canal_type': 'direct',
        'user_id': 'admin-jbf',
        'message': 'Réponse admin',
      },
      {
        'canal_type': 'signal',
        'user_id': 'x',
        'message': '[CALL_SIGNAL]{}',
      },
      {
        'canal_type': 'general',
        'user_id': 'y',
        'message': 'Salut',
      },
    ];
    final filtered = filterIncomingAdminMessages(rows);
    expect(filtered.length, 1);
    expect(filtered.first['expediteur_nom'], 'Chef A');
  });
}
