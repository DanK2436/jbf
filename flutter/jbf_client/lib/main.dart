import 'package:flutter/material.dart';
import 'package:jbf_portal_shell/jbf_portal_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const base = String.fromEnvironment('JBF_PORTAL_BASE');
  final config = PortalConfig.client(
    baseUrl: base.isEmpty ? null : base,
  );
  runApp(PortalApp(config: config));
}
