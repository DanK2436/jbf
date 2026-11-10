import 'package:flutter_test/flutter_test.dart';
import 'package:jbf_client/config/app_config.dart';
import 'package:jbf_client/services/client_data_service.dart';

void main() {
  test('JBF Client config & services', () async {
    expect(AppConfig.appName, 'JBF Service Client');
    final service = ClientDataService();
    final devis = await service.fetchDevis();
    expect(devis.isNotEmpty, true);
    final missions = await service.fetchMissions();
    expect(missions.isNotEmpty, true);
  });
}
