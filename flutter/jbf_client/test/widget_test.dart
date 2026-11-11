import 'package:flutter_test/flutter_test.dart';
import 'package:jbf_client/config/app_config.dart';
import 'package:jbf_client/services/client_data_service.dart';

void main() {
  test('les factures ne sont pas inventées', () async {
    expect(AppConfig.appName, 'JBF Service Client');
    final factures = await ClientDataService().fetchFactures();
    expect(factures, isEmpty);
    expect(ClientDataService().lastError, isNotNull);
  });
}
