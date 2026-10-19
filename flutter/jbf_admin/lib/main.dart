import 'package:flutter/material.dart';
import 'package:jbf_portal_shell/jbf_portal_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final runtime = PortalRuntime.fromEnvironment(adminApp: true);
  final config = PortalConfig.admin(
    baseUrl: runtime.portalBase.isEmpty ? null : runtime.portalBase,
  );

  AdminMessageNotifier? notifier;
  if (runtime.messageNotifications) {
    notifier = AdminMessageNotifier(runtime);
    await notifier.initialize();
  }

  runApp(
    PortalApp(
      config: config,
      runtime: runtime,
      messageNotifier: notifier,
    ),
  );
}
