import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController(text: AppConfig.defaultMatricule);
  final _passwordController = TextEditingController(text: AppConfig.defaultPassword);
  final _otpEmailController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showCustomOtpEmail = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await widget.authService.verifyPasswordOnly(
      _idController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final defaultEmail = res['email'] ?? 'dankande3@gmail.com';
      final targetEmail = _showCustomOtpEmail && _otpEmailController.text.trim().isNotEmpty
          ? _otpEmailController.text.trim()
          : defaultEmail;

      final agentNom = widget.authService.currentUser?.fullName ?? 'Collaborateur';

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            authService: widget.authService,
            initialEmail: targetEmail,
            agentNom: agentNom,
          ),
        ),
      );
      setState(() => _isLoading = false);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res['error'] ?? 'Identifiants invalides';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBEBF0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppConfig.brandPink,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppConfig.brandPink.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'JBF SERVICE MEMBRE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: AppConfig.blackText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Portail Métier Collaborateurs & Agents de Terrain (RDC)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 28),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF87171)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppConfig.dangerRed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppConfig.dangerRed, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Matricule field
                const Text(
                  'Matricule Agent ou Email Professionnel',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge),
                    hintText: 'ex: JBF-M-2026-012',
                  ),
                ),
                const SizedBox(height: 18),

                // Password field
                const Text(
                  'Mot de Passe Collaborateur',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Manual OTP Email Setting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Email de réception OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () => setState(() => _showCustomOtpEmail = !_showCustomOtpEmail),
                      child: Text(
                        _showCustomOtpEmail ? 'Utiliser email par défaut' : 'Indiquer email manuellement',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (_showCustomOtpEmail) ...[
                  TextField(
                    controller: _otpEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.alternate_email),
                      hintText: 'ex: mon.adresse@gmail.com',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Connexion & Envoi Code OTP',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConfig.brandPinkTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppConfig.brandPink, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sécurité 2FA : le code de confirmation est expédié directement par email après contrôle du mot de passe.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
