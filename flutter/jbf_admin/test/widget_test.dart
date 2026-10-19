import 'package:flutter_test/flutter_test.dart';
import 'package:jbf_portal_shell/jbf_portal_shell.dart';

void main() {
  test('JBF Admin config', () {
    expect(PortalConfig.admin().appName, 'JBF Admin');
  });
}
