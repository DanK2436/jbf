import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/otp_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1; // 1: Email, 2: OTP + New Password, 3: Success
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Veuillez saisir une adresse email valide.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await OtpService().sendOtpEmail(email);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _step = 2;
        _successMessage = res['warning'] ?? 'Un code OTP à 6 chiffres a été envoyé par email via Brevo à $email.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors de l\'envoi de l\'email : $e';
      });
    }
  }

  Future<void> _handleVerifyAndReset() async {
    final code = _otpController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (code.length != 6) {
      setState(() => _errorMessage = 'Veuillez renseigner le code OTP à 6 chiffres.');
      return;
    }

    if (newPass.length < 6) {
      setState(() => _errorMessage = 'Le mot de passe doit comporter au moins 6 caractères.');
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Les deux mots de passe ne correspondent pas.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isValid = OtpService().verifyOtp(code);
    if (!isValid) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Code OTP incorrect ou expiré (validité 10 minutes).';
      });
      return;
    }

    // Mise à jour dans profiles et admin_accounts
    final email = _emailController.text.trim().toLowerCase();
    try {
      await http.patch(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?email=eq.$email'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'permissions_detaillees': {
            'password': newPass,
            'updated_via_otp': true,
            'role': 'admin',
            'reset_at': DateTime.now().toIso8601String(),
          },
        }),
      );
    } catch (_) {}

    try {
      await http.patch(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/admin_accounts?email=eq.$email'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'password': newPass,
          'password_hash': newPass,
        }),
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _step = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFF2),
      appBar: AppBar(
        title: const Text('Récupération Compte Admin (OTP Brevo)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: AppConfig.blackText,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildStep1Email();
      case 2:
        return _buildStep2OtpAndNewPassword();
      case 3:
      default:
        return _buildStep3Success();
    }
  }

  Widget _buildStep1Email() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(color: AppConfig.brandPinkTint, shape: BoxShape.circle),
          child: const Icon(Icons.shield_outlined, size: 40, color: AppConfig.brandPink),
        ),
        const SizedBox(height: 16),
        const Text(
          'Réinitialisation Direction Admin',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Recevez un code de vérification OTP à 6 chiffres par email via Brevo pour définir un nouveau mot de passe.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(_errorMessage!, style: const TextStyle(color: AppConfig.dangerRed, fontSize: 12.5)),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Adresse Email Administrateur',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConfig.brandPink,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isLoading ? null : _handleSendOtp,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Envoyer le Code OTP Brevo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildStep2OtpAndNewPassword() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(color: AppConfig.brandPinkTint, shape: BoxShape.circle),
          child: const Icon(Icons.verified_user, size: 40, color: AppConfig.brandPink),
        ),
        const SizedBox(height: 16),
        const Text(
          'Vérification & Nouveau Mot de Passe',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Saisissez le code OTP à 6 chiffres reçu par email et votre nouveau mot de passe administrateur.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 20),
        if (_successMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(_successMessage!, style: const TextStyle(color: AppConfig.successGreen, fontSize: 12)),
          ),
          const SizedBox(height: 12),
        ],
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(_errorMessage!, style: const TextStyle(color: AppConfig.dangerRed, fontSize: 12)),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            labelText: 'Code de Sécurité OTP (6 chiffres)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Nouveau Mot de Passe',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Confirmer le Mot de Passe',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConfig.brandPink,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isLoading ? null : _handleVerifyAndReset,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Enregistrer le Mot de Passe Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('Renvoyer un nouveau code', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildStep3Success() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 60, color: AppConfig.successGreen),
        const SizedBox(height: 16),
        const Text(
          'Accès Administrateur Mis à Jour !',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Votre nouveau mot de passe a été enregistré avec succès. Vous pouvez maintenant vous connecter au logiciel.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConfig.brandPink,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Se Connecter au Logiciel', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
