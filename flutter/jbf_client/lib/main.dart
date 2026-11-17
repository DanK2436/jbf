import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();

  runApp(JbfClientApp(
    authService: authService,
    initialScreen: SplashScreen(authService: authService),
  ));
}

class JbfClientApp extends StatelessWidget {
  final AuthService authService;
  final Widget initialScreen;

  const JbfClientApp({
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
