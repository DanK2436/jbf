import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/admin_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  final hasSession = await authService.tryAutoLogin();

  runApp(JbfAdminApp(
    authService: authService,
    initialScreen: hasSession
        ? AdminMainScreen(authService: authService)
        : LoginScreen(authService: authService),
  ));
}

class JbfAdminApp extends StatelessWidget {
  final AuthService authService;
  final Widget initialScreen;

  const JbfAdminApp({
    super.key,
    required this.authService,
    required this.initialScreen,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialScreen,
    );
  }
}
