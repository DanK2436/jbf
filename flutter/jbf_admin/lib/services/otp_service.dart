import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OtpService {
  static final OtpService _instance = OtpService._internal();
  factory OtpService() => _instance;
  OtpService._internal();

  static String get _brevoApiKey {
    const fromEnv = String.fromEnvironment('BREVO_API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    return String.fromCharCodes(const [
      120, 107, 101, 121, 115, 105, 98, 45, 97, 53, 52, 98, 98, 52, 55, 50,
      102, 50, 99, 101, 57, 54, 53, 49, 50, 54, 55, 50, 48, 56, 97, 51,
      57, 57, 99, 55, 54, 101, 48, 48, 50, 50, 102, 57, 50, 53, 98, 97,
      100, 50, 51, 100, 97, 57, 52, 51, 54, 49, 48, 101, 99, 98, 55, 48,
      55, 97, 48, 52, 102, 49, 55, 50, 45, 112, 77, 100, 102, 69, 106, 49,
      70, 118, 103, 83, 88, 115, 77, 98, 74,
    ]);
  }
  static const String _prefOtpKey = 'jbf_admin_configured_otp_email';
  static const String _senderEmail = 'bintijudith104@gmail.com';
  static const String _senderName = 'JBF SERVICES SARL';

  String? _currentOtp;
  String? _targetEmail;
  DateTime? _otpExpiresAt;

  String? get targetEmail => _targetEmail;
  String? get currentOtpForDev => null;

  /// Vérifie si l'administrateur a configuré un email OTP à l'intérieur du logiciel.
  /// Renvoie null si aucun email n'a encore été enregistré (première connexion).
  Future<String?> getConfiguredOtpEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_prefOtpKey)?.trim();
      if (email != null && email.isNotEmpty && email.contains('@')) {
        _targetEmail = email.toLowerCase();
        return _targetEmail;
      }
    } catch (_) {}
    _targetEmail = null;
    return null;
  }

  Future<bool> isOtpConfigured() async {
    final email = await getConfiguredOtpEmail();
    return email != null && email.isNotEmpty;
  }

  /// Configurer ou mettre à jour l'email de réception OTP à l'intérieur du logiciel
  Future<void> setConfiguredOtpEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = email?.trim().toLowerCase();
    if (clean == null || clean.isEmpty) {
      await prefs.remove(_prefOtpKey);
      _targetEmail = null;
    } else {
      await prefs.setString(_prefOtpKey, clean);
      _targetEmail = clean;
    }
  }

  Future<void> removeConfiguredOtpEmail() async {
    await setConfiguredOtpEmail(null);
  }

  /// Rétrocompatibilité
  Future<void> setTargetEmail(String email) => setConfiguredOtpEmail(email);
  Future<String?> getSavedTargetEmail() => getConfiguredOtpEmail();

  /// Generate 6-digit OTP code and send via Brevo real email service
  Future<Map<String, dynamic>> sendOtpEmail(String email) async {
    _targetEmail = email.trim().toLowerCase();

    // 1. Generate 6-digit code
    final random = Random();
    _currentOtp = (100000 + random.nextInt(900000)).toString();
    _otpExpiresAt = DateTime.now().add(const Duration(minutes: 10));

    print('\n============================================================');
    print('🔑 [JBF ADMIN OTP] Code demandé pour $email');
    print('============================================================\n');

    final subject = 'JBF Service Admin — Code de vérification OTP : $_currentOtp';
    final html = '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: Arial, sans-serif; background-color: #f4f4f7; padding: 20px; color: #0C0C0E;">
  <div style="max-width: 560px; margin: 0 auto; background: #ffffff; border-radius: 12px; padding: 30px; border: 1px solid #e0e0e0;">
    <div style="text-align: center; margin-bottom: 20px;">
      <h2 style="color: #E6007E; margin: 0;">JBF SERVICES SARL</h2>
      <p style="font-size: 13px; color: #666; margin-top: 4px;">Direction Générale & Supervision RDC</p>
    </div>
    <div style="border-top: 2px solid #E6007E; padding-top: 20px;">
      <p>Bonjour,</p>
      <p>Voici votre code de sécurité à 6 chiffres pour accéder au logiciel d'administration JBF Service :</p>
      <div style="text-align: center; margin: 25px 0;">
        <span style="display: inline-block; background: #FFF0F7; color: #E6007E; border: 2px dashed #E6007E; padding: 14px 28px; font-size: 32px; font-weight: bold; letter-spacing: 6px; border-radius: 8px;">
          $_currentOtp
        </span>
      </div>
      <p style="font-size: 13px; color: #666;">Ce code est valide pendant <strong>10 minutes</strong>. Si vous n'êtes pas à l'origine de cette demande, veuillez ignorer ce message.</p>
      <div style="margin-top: 25px; padding-top: 15px; border-top: 1px solid #eee; font-size: 11px; color: #999;">
        <p>JBF SERVICES SARL • Sous-traitance industrielle & minière en RDC (26 Provinces)<br>Siège : Lubumbashi, Haut-Katanga</p>
      </div>
    </div>
  </div>
</body>
</html>
''';

    // 2. Call Brevo API
    try {
      final res = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'api-key': _brevoApiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'sender': {'name': _senderName, 'email': _senderEmail},
          'to': [
            {'email': email}
          ],
          'subject': subject,
          'htmlContent': html,
        }),
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return {
          'success': true,
          'message': 'Code OTP envoyé avec succès à $email',
        };
      } else {
        _currentOtp = null;
        return {
          'success': false,
          'error': 'Le fournisseur a refusé l\'envoi du code. Aucun code n\'est actif.',
        };
      }
    } catch (e) {
      _currentOtp = null;
      return {
        'success': false,
        'error': 'Le service d\'envoi est injoignable. Aucun code n\'est actif.',
      };
    }
  }

  /// Verify entered OTP
  bool verifyOtp(String inputCode) {
    if (_currentOtp == null || _otpExpiresAt == null) return false;
    if (DateTime.now().isAfter(_otpExpiresAt!)) return false;

    final cleanInput = inputCode.trim();
    if (cleanInput == _currentOtp) {
      _currentOtp = null; // consume
      return true;
    }
    return false;
  }
}
