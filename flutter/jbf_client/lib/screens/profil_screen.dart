import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/client_models.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfilScreen extends StatefulWidget {
  final ClientUser client;
  final AuthService authService;

  const ProfilScreen({
    super.key,
    required this.client,
    required this.authService,
  });

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _sectorCtrl;
  late TextEditingController _siteCtrl;
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  bool _isSaving = false;
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.client.fullName);
    _companyCtrl = TextEditingController(text: widget.client.companyName);
    _phoneCtrl = TextEditingController(text: widget.client.phone);
    _sectorCtrl = TextEditingController(text: widget.client.sector);
    _siteCtrl = TextEditingController(text: widget.client.site);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _sectorCtrl.dispose();
    _siteCtrl.dispose();
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfileChanges() async {
    setState(() => _isSaving = true);

    try {
      final isUuid = widget.client.id.length > 20 &&
          !widget.client.id.startsWith('cli-') &&
          !widget.client.id.startsWith('usr-');

      final url = isUuid
          ? '${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.${widget.client.id}'
          : '${AppConfig.supabaseUrl}/rest/v1/profiles?email=eq.${widget.client.email}';

      final authToken = widget.client.token ?? AppConfig.supabaseAnonKey;
      final headers = {
        'apikey': AppConfig.supabaseAnonKey,
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

      final payload = {
        'full_name': _nameCtrl.text.trim(),
        'nom_complet': _nameCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'entreprise': _companyCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'telephone': _phoneCtrl.text.trim(),
        'secteur': _sectorCtrl.text.trim(),
        'province': _siteCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final res = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(payload),
      );

      // Si le PATCH par id n'a pas trouvé ou a échoué, essayer par email
      if (res.statusCode < 200 || res.statusCode >= 300) {
        await http.patch(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?email=eq.${widget.client.email}'),
          headers: headers,
          body: jsonEncode(payload),
        );
      }

      // Mettre à jour la session locale immédiatement
      final updatedUser = ClientUser(
        id: widget.client.id,
        fullName: _nameCtrl.text.trim(),
        companyName: _companyCtrl.text.trim(),
        email: widget.client.email,
        phone: _phoneCtrl.text.trim(),
        sector: _sectorCtrl.text.trim(),
        site: _siteCtrl.text.trim(),
        role: widget.client.role,
        token: widget.client.token,
      );
      await widget.authService.updateCurrentUser(updatedUser);

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil entreprise mis à jour et enregistré avec succès !'),
          backgroundColor: AppConfig.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: AppConfig.dangerRed),
      );
    }
  }

  Future<void> _updatePassword() async {
    final newPass = _newPassCtrl.text.trim();
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nouveau mot de passe doit comporter au moins 6 caractères.')),
      );
      return;
    }

    try {
      // Mise à jour mot de passe dans Supabase Auth et profil
      final authToken = widget.client.token;
      if (authToken != null && authToken.isNotEmpty) {
        await http.put(
          Uri.parse('${AppConfig.supabaseUrl}/auth/v1/user'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'password': newPass}),
        );
      }

      // Sauvegarde de secours dans permissions_detaillees['password']
      await http.patch(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?email=eq.${widget.client.email}'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'permissions_detaillees': {'password': newPass},
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );

      if (!mounted) return;
      _oldPassCtrl.clear();
      _newPassCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe mis à jour avec succès.'),
          backgroundColor: AppConfig.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppConfig.dangerRed),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion Espace Client'),
        content: const Text('Voulez-vous quitter votre session partenaire sécurisée ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authService.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen(authService: widget.authService)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 14.0 : 24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Banner Header
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppConfig.blackText, Color(0xFF1E1E24)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: isMobile ? 26 : 34,
                        backgroundColor: AppConfig.brandPink,
                        child: Text(
                          _companyCtrl.text.isNotEmpty
                              ? _companyCtrl.text.substring(0, _companyCtrl.text.length >= 2 ? 2 : 1).toUpperCase()
                              : 'CL',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  _companyCtrl.text.isNotEmpty ? _companyCtrl.text : 'Entreprise Partenaire',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'AGRÉÉ ARSP',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppConfig.successGreen),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.client.email,
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Compte Client B2B Officiel • jbf-service.com',
                              style: TextStyle(color: AppConfig.brandPink, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Formulaire d'Édition du Profil Entreprise
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Informations Entreprise & Contact',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                            ),
                          ),
                          Icon(Icons.edit_note, color: AppConfig.brandPink, size: 24),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (isMobile) ...[
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: 'Nom du Responsable / Représentant *'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _companyCtrl,
                          decoration: const InputDecoration(labelText: 'Raison Sociale / Entreprise *'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(labelText: 'Téléphone WhatsApp Direct *'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _siteCtrl,
                          decoration: const InputDecoration(labelText: 'Site Minier / Ville d\'Implantation'),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(labelText: 'Nom du Responsable / Représentant *'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _companyCtrl,
                                decoration: const InputDecoration(labelText: 'Raison Sociale / Entreprise *'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _phoneCtrl,
                                decoration: const InputDecoration(labelText: 'Téléphone WhatsApp Direct *'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _siteCtrl,
                                decoration: const InputDecoration(labelText: 'Site Minier / Ville d\'Implantation'),
                              ),
                            ),
                          ],
                        ),
                      ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _sectorCtrl,
                        decoration: const InputDecoration(labelText: 'Secteur d\'Activité (ex: Mines de Cuivre, BTP, Logistique)'),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProfileChanges,
                        icon: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check, size: 18),
                        label: Text(_isSaving ? 'Enregistrement en cours...' : 'Enregistrer les Modifications'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.brandPink,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sécurité & Changement de Mot de Passe
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sécurité du Compte & Mot de Passe',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _newPassCtrl,
                        obscureText: _obscurePass,
                        decoration: InputDecoration(
                          labelText: 'Nouveau Mot de Passe',
                          hintText: 'Au moins 6 caractères',
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _updatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        child: const Text('Mettre à Jour le Mot de Passe'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton Déconnexion
                OutlinedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout, color: AppConfig.dangerRed, size: 18),
                  label: const Text('Fermer la Session Client', style: TextStyle(color: AppConfig.dangerRed, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppConfig.dangerRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
