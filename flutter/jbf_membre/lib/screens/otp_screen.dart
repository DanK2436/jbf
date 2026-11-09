import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/otp_service.dart';
import 'membre_main_screen.dart';

class OtpScreen extends StatefulWidget {
  final AuthService authService;
  final String initialEmail;
  final String agentNom;

  const OtpScreen({
    super.key,
    required this.authService,
    required this.initialEmail,
    required this.agentNom,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final _otpService = OtpService();
  late String _currentEmail;
  bool _isSending = false;
  bool _isVerifying = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _currentEmail = widget.initialEmail;
    _sendInitialOtp();
  }

  Future<void> _sendInitialOtp() async {
    setState(() => _isSending = true);
    final res = await _otpService.sendOtpEmail(_currentEmail, agentNom: widget.agentNom);
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _successMessage = 'Code envoyé à $_currentEmail';
    });
  }

  void _showEditEmailDialog() {
    final emailCtrl = TextEditingController(text: _currentEmail);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier l\'Email de Réception OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indiquez l\'adresse email où vous souhaitez recevoir votre code de connexion collaborateur :',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                hintText: 'mon.email@domaine.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newMail = emailCtrl.text.trim();
              if (newMail.isEmpty || !newMail.contains('@')) return;
              Navigator.of(ctx).pop();
              setState(() {
                _currentEmail = newMail;
                _isSending = true;
                _errorMessage = null;
              });
              await _otpService.sendOtpEmail(newMail, agentNom: widget.agentNom);
              if (!mounted) return;
              setState(() {
                _isSending = false;
                _successMessage = 'Nouveau code envoyé à $newMail';
              });
            },
            child: const Text('Enregistrer & Renvoyer'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVerifyOtp() async {
    final input = _otpController.text.trim();
    if (input.length != 6) {
      setState(() => _errorMessage = 'Veuillez saisir les 6 chiffres du code OTP.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final isValid = _otpService.verifyOtp(input);

    if (isValid) {
      await widget.authService.completeLogin();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MembreMainScreen(authService: widget.authService),
        ),
      );
    } else {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Code OTP incorrect ou expiré. Veuillez vérifier votre boîte email ou renvoyer un code.';
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
            constraints: const BoxConstraints(maxWidth: 460),
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
                      color: AppConfig.brandPinkTint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: AppConfig.brandPink,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'VÉRIFICATION COLLABORATEUR (2FA)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: AppConfig.blackText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Un code OTP à 6 chiffres a été envoyé pour valider votre connexion agent.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),

                // Current Target Email Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email, color: AppConfig.brandPink, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Email de réception OTP :',
                                style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              _currentEmail,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                        onPressed: _showEditEmailDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (_successMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppConfig.successGreen, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_successMessage!,
                              style: const TextStyle(color: AppConfig.successGreen, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppConfig.dangerRed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: const TextStyle(color: AppConfig.dangerRed, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 6-digit OTP Input
                const Text(
                  'Code de Sécurité (6 chiffres)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                    color: AppConfig.brandPinkDark,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    fillColor: AppConfig.brandPinkTint.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 22),

                ElevatedButton(
                  onPressed: _isVerifying ? null : _handleVerifyOtp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Valider le Code & Accéder à l\'Espace Membre',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 14),

                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(_isSending ? 'Envoi en cours...' : 'Renvoyer un nouveau code par email'),
                  onPressed: _isSending ? null : _sendInitialOtp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
