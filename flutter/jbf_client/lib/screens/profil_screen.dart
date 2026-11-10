import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/client_models.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfilScreen extends StatelessWidget {
  final ClientUser client;
  final AuthService authService;

  const ProfilScreen({
    super.key,
    required this.client,
    required this.authService,
  });

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion Espace Client'),
        content: const Text('Voulez-vous quitter votre session partenaire ?'),
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
      await authService.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen(authService: authService)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Header Card
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
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppConfig.brandPink,
                        child: Text(
                          client.companyName.isNotEmpty ? client.companyName.substring(0, 2).toUpperCase() : 'CL',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  client.companyName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.verified, color: AppConfig.brandPink, size: 18),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Représentant : ${client.fullName}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Compte Donneur d\'Ordre Vérifié ARSP',
                                style: TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations de l\'Entreprise',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.apartment, 'Raison Sociale', client.companyName),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.person, 'Responsable Mandataire', client.fullName),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.email_outlined, 'Courriel Professionnel', client.email),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.phone_outlined, 'Téléphone / WhatsApp', client.phone),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.category_outlined, 'Secteur d\'Activité', client.sector),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.pin_drop_outlined, 'Site Minier / Localité', client.site),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ARSP & Compliance Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Conformité Légale & Sous-Traitance RDC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(height: 4),
                      Text(
                        'JBF SERVICES SARL détient l\'agrément officiel de l\'ARSP (Autorité de Régulation de la Sous-traitance dans le secteur Privé). Vos commandes et factures sont 100% déductibles et conformes aux obligations de la loi minière en RDC.',
                        style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Logout Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.dangerRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Fermer la Session Partenaire'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppConfig.brandPink),
        const SizedBox(width: 14),
        Text('$label : ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConfig.blackText),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
