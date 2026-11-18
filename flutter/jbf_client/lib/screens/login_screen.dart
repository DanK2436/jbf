import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'client_main_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // OTP Login controllers
  final _otpEmailController = TextEditingController();
  final _otpCodeController = TextEditingController();
  bool _otpSent = false;

  // Password Login controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  // Register controllers
  final _regCompanyController = TextEditingController();
  final _regContactController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPhoneController = TextEditingController(text: '+243 ');
  final _regPasswordController = TextEditingController();
  final String _selectedSector = 'Catering Minier & Base-Vie';

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _otpEmailController.dispose();
    _otpCodeController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regCompanyController.dispose();
    _regContactController.dispose();
    _regEmailController.dispose();
    _regPhoneController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final email = _otpEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Veuillez saisir une adresse email valide.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await widget.authService.sendLoginOtp(email);

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _isLoading = false;
        _otpSent = true;
        _successMessage = res['message'] ?? 'Code de vérification envoyé à $email.';
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res['error'] ?? 'Échec de l\'envoi du code OTP.';
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final email = _otpEmailController.text.trim();
    final code = _otpCodeController.text.trim();

    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Veuillez renseigner les 6 chiffres du code OTP.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await widget.authService.verifyOtpAndLogin(email, code);

    if (!mounted) return;

    if (res['success'] == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClientMainScreen(authService: widget.authService),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res['error'] ?? 'Code de vérification incorrect ou expiré.';
      });
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await widget.authService.login(
      _loginEmailController.text,
      _loginPasswordController.text,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClientMainScreen(authService: widget.authService),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res['error'] ?? 'Échec de connexion';
      });
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await widget.authService.register(
      companyName: _regCompanyController.text,
      contactName: _regContactController.text,
      email: _regEmailController.text,
      phone: _regPhoneController.text,
      password: _regPasswordController.text,
      sector: _selectedSector,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClientMainScreen(authService: widget.authService),
        ),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res['error'] ?? 'Échec de l\'inscription';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 450;

    return Scaffold(
      backgroundColor: const Color(0xFFEBEBF0),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? 12.0 : 24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: EdgeInsets.all(isSmall ? 18.0 : 28.0),
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
                // Logo Officiel JBF Service
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppConfig.brandPink.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.business_center,
                          color: AppConfig.brandPink,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'JBF SERVICE CLIENT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: AppConfig.blackText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Portail Partenaires, Devis & Suivi de Chantiers RDC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 18),

                // Tab Switcher (OTP / Mot de Passe / Inscription)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppConfig.brandPink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade700,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 11 : 12),
                    tabs: const [
                      Tab(text: 'OTP Email'),
                      Tab(text: 'Mot de passe'),
                      Tab(text: 'Inscription'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
                  const SizedBox(height: 16),
                ],

                if (_successMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(color: Color(0xFF166534), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tab Content
                SizedBox(
                  height: 380,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: EMAIL OTP
                      _buildEmailOtpForm(),
                      // TAB 2: PASSWORD LOGIN
                      _buildLoginForm(),
                      // TAB 3: REGISTER
                      _buildRegisterForm(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quality & ARSP footer note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConfig.brandPinkTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: AppConfig.brandPink, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Prestataire certifié et agréé ARSP en RDC. Accès direct sécurisé 24/7 sans attente.',
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

  Widget _buildEmailOtpForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Email Professionnel / Entreprise', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _otpEmailController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.mark_email_read_outlined),
              hintText: 'partenaire@entreprise.cd',
              suffixIcon: _otpSent
                  ? IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => setState(() {
                        _otpSent = false;
                        _errorMessage = null;
                        _successMessage = null;
                      }),
                    )
                  : null,
            ),
            enabled: !_otpSent || !_isLoading,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          if (!_otpSent) ...[
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleSendOtp,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send, size: 18),
              label: Text(_isLoading ? 'Envoi du code...' : 'Recevoir mon Code OTP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.brandPink,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Un code temporaire à 6 chiffres vous sera envoyé par email pour une connexion directe et sécurisée sans mot de passe.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Code envoyé à ${_otpEmailController.text.trim()}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Code de Vérification (6 chiffres)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _otpCodeController,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 8),
              decoration: const InputDecoration(
                hintText: '000000',
                counterText: '',
                prefixIcon: Icon(Icons.shield_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleVerifyOtp,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.login, size: 18),
              label: Text(_isLoading ? 'Vérification...' : 'Valider et Accéder à mon Espace'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.brandPink,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  child: const Text('Renvoyer le code', style: TextStyle(fontSize: 12, color: AppConfig.brandPink, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _otpSent = false;
                    _otpCodeController.clear();
                    _errorMessage = null;
                    _successMessage = null;
                  }),
                  child: Text('Modifier l\'email', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Email Professionnel / Entreprise', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _loginEmailController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'partenaire@mining.cd',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          const Text('Mot de Passe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _loginPasswordController,
            obscureText: _obscureLoginPassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureLoginPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                );
              },
              child: const Text('Mot de passe oublié ?', style: TextStyle(fontSize: 12, color: AppConfig.brandPink, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.brandPink,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Accéder à mon Espace Client', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _regCompanyController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.apartment),
              hintText: 'Nom de votre Entreprise / Société',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regContactController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
              hintText: 'Nom & Prénom du Responsable',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.alternate_email),
              hintText: 'Email de contact entreprise',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone),
              hintText: 'Téléphone / WhatsApp (+243...)',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_outline),
              hintText: 'Mot de passe (min. 6 caractères)',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.brandPink,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Créer mon Compte Partenaire', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
