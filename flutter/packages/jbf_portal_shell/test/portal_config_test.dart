import 'package:flutter_test/flutter_test.dart';
import 'package:jbf_portal_shell/jbf_portal_shell.dart';

void main() {
  test('admin portal points to GitHub Pages login', () {
    final c = PortalConfig.admin();
    expect(c.appName, 'JBF Admin');
    expect(c.startUrl, contains('JBF%20Admin'));
    expect(c.startUrl, contains('login.html'));
  });

  test('custom base URL is applied', () {
    final c = PortalConfig.client(baseUrl: 'https://example.com/jbf');
    expect(c.startUrl, startsWith('https://example.com/jbf/JBF%20Client'));
  });
}
