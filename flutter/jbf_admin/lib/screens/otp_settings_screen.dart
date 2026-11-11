import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/otp_service.dart';

class OtpSettingsScreen extends StatefulWidget {
  const OtpSettingsScreen({super.key});

  @override
  State<OtpSettingsScreen> createState() => _OtpSettingsScreenState();
}

class _OtpSettingsScreenState extends State<OtpSettingsScreen> {
  final _otpService = OtpService();
  final _emailController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSendingTest = false;
  String? _configuredEmail;
  String? _statusMessage;
  bool _statusIsSuccess = true;

  @override
  void initState() {
    super.initState();
    _loadConfiguredEmail();
  }

  Future<void> _loadConfiguredEmail() async {
    setState(() => _isLoading = true);
    final email = await _otpService.getConfiguredOtpEmail();
    if (!mounted) return;
    setState(() {
      _configuredEmail = email;
      if (email != null && email.isNotEmpty) {
        _emailController.text = email;
      }
      _isLoading = false;
    });
  }

  Future<void> _handleSaveEmail() async {
    final clean = _emailController.text.trim().toLowerCase();
    if (clean.isNotEmpty && (!clean.contains('@') || !clean.contains('.'))) {
      setState(() {
        _statusMessage = 'Veuillez saisir une adresse email valide.';
        _statusIsSuccess = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    await _otpService.setConfiguredOtpEmail(clean.isEmpty ? null : clean);
    final updated = await _otpService.getConfiguredOtpEmail();

    if (!mounted) return;
    setState(() {
      _configuredEmail = updated;
      _isSaving = false;
      if (updated != null && updated.isNotEmpty) {
        _statusMessage = 'Email OTP enregistré avec succès : $updated. Les prochaines connexions exigeront un code à 6 chiffres envoyé à cette adresse.';
        _statusIsSuccess = true;
      } else {
        _statusMessage = 'Email OTP retiré. La connexion s\'effectuera désormais en accès direct sans code.';
        _statusIsSuccess = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_statusMessage ?? 'Configuration mise à jour'),
        backgroundColor: _statusIsSuccess ? Colors.green.shade700 : AppConfig.dangerRed,
      ),
    );
  }

  Future<void> _handleSendTestOtp() async {
    final target = _emailController.text.trim();
    if (target.isEmpty || !target.contains('@')) {
      setState(() {
        _statusMessage = 'Veuillez renseigner un email valide avant d\'effectuer un test.';
        _statusIsSuccess = false;
      });
      return;
    }

    setState(() {
      _isSendingTest = true;
      _statusMessage = null;
    });

    final res = await _otpService.sendOtpEmail(target);

    if (!mounted) return;
    setState(() {
      _isSendingTest = false;
      if (res['success'] == true) {
        _statusMessage = 'Code OTP de test envoyé à $target. Le code n\'est pas affiché ici.';
        _statusIsSuccess = true;
      } else {
        _statusMessage = res['error'] ?? 'Échec de l\'envoi du code test.';
        _statusIsSuccess = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_statusMessage ?? 'Test OTP terminé'),
        backgroundColor: _statusIsSuccess ? Colors.green.shade700 : AppConfig.dangerRed,
      ),
    );
  }

  Future<void> _handleDisableOtp() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Désactiver la protection OTP'),
        content: const Text(
          'Voulez-vous retirer l\'email OTP ? L\'administrateur principal pourra alors se connecter sans code de sécurité (accès direct avec mot de passe seul).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _otpService.removeConfiguredOtpEmail();
      _emailController.clear();
      await _loadConfiguredEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Protection OTP désactivée. Connexion directe réactivée.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    final hasOtp = _configuredEmail != null && _configuredEmail!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: hasOtp ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        hasOtp ? Icons.verified_user : Icons.gpp_maybe,
                        color: hasOtp ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasOtp ? 'Protection OTP Active' : 'OTP Non Configuré (Accès Direct)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: hasOtp ? const Color(0xFF15803D) : const Color(0xFFB45309),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasOtp
                                ? 'Les codes de connexion de l\'administrateur principal sont envoyés à $_configuredEmail'
                                : 'Première connexion : aucun code n\'est exigé. Dès que vous enregistrez un email, l\'OTP s\'active.',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Configuration Form Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email de Réception des Codes OTP (Admin Principal)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Renseignez ici l\'adresse email où l\'administrateur principal recevra son code de vérification à 6 chiffres lors de chaque connexion au logiciel.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Adresse Email OTP de la Direction',
                        hintText: 'ex: direction@jbf-services.cd ou votre.email@gmail.com',
                        prefixIcon: const Icon(Icons.mark_email_read_outlined, color: AppConfig.brandPink),
                        suffixIcon: _emailController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _emailController.clear()),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_statusMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _statusIsSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _statusIsSuccess ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _statusIsSuccess ? Icons.check_circle_outline : Icons.error_outline,
                              color: _statusIsSuccess ? const Color(0xFF16A34A) : AppConfig.dangerRed,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: TextStyle(
                                  color: _statusIsSuccess ? const Color(0xFF15803D) : AppConfig.dangerRed,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Action Buttons
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _handleSaveEmail,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(hasOtp ? 'Mettre à jour l\'email OTP' : 'Activer l\'OTP avec cet email'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isSendingTest ? null : _handleSendTestOtp,
                          icon: _isSendingTest
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_outlined),
                          label: const Text('Tester l\'envoi d\'un code'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          ),
                        ),
                        if (hasOtp)
                          TextButton.icon(
                            onPressed: _handleDisableOtp,
                            icon: const Icon(Icons.remove_circle_outline, color: AppConfig.dangerRed),
                            label: const Text('Désactiver l\'OTP', style: TextStyle(color: AppConfig.dangerRed)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Educational Security Rules Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: AppConfig.brandPinkDark, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Règles de fonctionnement de l\'authentification JBF',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRuleItem(
                      '1. Membres & Collaborateurs de terrain :',
                      'L\'OTP est totalement retiré. Ils se connectent directement avec leur matricule et mot de passe.',
                    ),
                    const SizedBox(height: 8),
                    _buildRuleItem(
                      '2. Administrateur Principal (Première Connexion) :',
                      'Si aucun email n\'a été ajouté dans ce panneau, le logiciel ne demande aucun OTP et permet un accès immédiat.',
                    ),
                    const SizedBox(height: 8),
                    _buildRuleItem(
                      '3. Activation de l\'OTP :',
                      'Dès qu\'un email est enregistré dans ce panneau (pas sur l\'écran de connexion), chaque connexion future exigera la saisie d\'un code à 6 chiffres envoyé à cette adresse.',
                    ),
                    const SizedBox(height: 8),
                    _buildRuleItem(
                      '4. Modification en direct :',
                      'Vous pouvez changer cette adresse email ici à tout moment pour rediriger la réception des codes.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check, size: 16, color: AppConfig.brandPink),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: AppConfig.blackText, height: 1.4),
              children: [
                TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
