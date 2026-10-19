import 'package:flutter/material.dart';
import 'package:jbf_portal_shell/jbf_portal_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final runtime = PortalRuntime.fromEnvironment(adminApp: false);
  final config = PortalConfig.membre(
    baseUrl: runtime.portalBase.isEmpty ? null : runtime.portalBase,
  );
  runApp(PortalApp(config: config, runtime: runtime));
}
