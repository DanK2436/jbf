import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/membre_models.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'missions_screen.dart';
import 'leaves_screen.dart';
import 'chat_screen.dart';
import 'resources_screen.dart';
import 'devis_membre_screen.dart';
import 'progression_mission_screen.dart';
import 'login_screen.dart';

class MembreMainScreen extends StatefulWidget {
  final AuthService authService;

  const MembreMainScreen({super.key, required this.authService});

  @override
  State<MembreMainScreen> createState() => _MembreMainScreenState();
}

class _MembreMainScreenState extends State<MembreMainScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Tableau de Bord Collaborateur',
    'Mes Ordres de Mission & Chantiers',
    'Mes Congés & Absences RH',
    'Messagerie & Canaux d\'Équipe',
    'Bibliothèque Documentaire HSE',
    'Devis & Base Locale Matériaux (Hors-Ligne)',
    'Feuille de Route & Progression des Missions',
  ];

  Widget _buildBody() {
    final user = widget.authService.currentUser!;
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          user: user,
          onNavigate: (idx) => setState(() => _selectedIndex = idx),
        );
      case 1:
        return const MissionsScreen();
      case 2:
        return LeavesScreen(user: user);
      case 3:
        return ChatScreen(user: user);
      case 4:
        return const ResourcesScreen();
      case 5:
        return DevisMembreScreen(user: user);
      case 6:
        return ProgressionMissionScreen(user: user);
      default:
        return DashboardScreen(
          user: user,
          onNavigate: (idx) => setState(() => _selectedIndex = idx),
        );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous fermer votre session collaborateur ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen(authService: widget.authService)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.badge, color: AppConfig.brandPink, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titles[_selectedIndex], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const Text('JBF Service Collaborateurs — RDC', style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _showProfileAndSettingsDialog(context, user),
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white24,
                        child: Text(
                          user?.avatar ?? 'MB',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isDesktop)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.fullName ?? 'Collaborateur', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(user?.matricule ?? 'JBF-M', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  tooltip: 'Profil & Paramètres',
                  onPressed: () => _showProfileAndSettingsDialog(context, user),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Déconnexion',
                  onPressed: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey.shade200)),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Tableau de Bord'),
                  _buildNavItem(1, Icons.engineering_outlined, Icons.engineering, 'Mes Missions'),
                  _buildNavItem(2, Icons.beach_access_outlined, Icons.beach_access, 'Mes Congés RH'),
                  _buildNavItem(3, Icons.chat_outlined, Icons.chat, 'Messagerie & Équipe'),
                  _buildNavItem(4, Icons.folder_outlined, Icons.folder, 'Bibliothèque HSE'),
                  _buildNavItem(5, Icons.request_quote_outlined, Icons.request_quote, 'Devis & BDD Matériaux'),
                  _buildNavItem(6, Icons.task_alt_outlined, Icons.task_alt, 'Progression Missions'),
                ],
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(color: AppConfig.brandPink),
                    accountName: Text(user?.fullName ?? 'Collaborateur'),
                    accountEmail: Text('${user?.matricule} • ${user?.email}'),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        user?.avatar ?? 'MB',
                        style: const TextStyle(color: AppConfig.brandPink, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  _buildDrawerItem(0, Icons.dashboard, 'Tableau de Bord'),
                  _buildDrawerItem(1, Icons.engineering, 'Mes Missions'),
                  _buildDrawerItem(2, Icons.beach_access, 'Mes Congés RH'),
                  _buildDrawerItem(3, Icons.chat, 'Messagerie & Équipe'),
                  _buildDrawerItem(4, Icons.folder, 'Bibliothèque HSE'),
                  _buildDrawerItem(5, Icons.request_quote, 'Devis & BDD Matériaux'),
                  _buildDrawerItem(6, Icons.task_alt, 'Progression Missions'),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings, color: AppConfig.brandPink),
                    title: const Text('Profil & Paramètres'),
                    onTap: () {
                      Navigator.pop(context);
                      _showProfileAndSettingsDialog(context, user);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  void _showProfileAndSettingsDialog(BuildContext context, MembreUser? user) {
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.badge, color: AppConfig.brandPink),
            SizedBox(width: 10),
            Text('Profil & Paramètres du Compte'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppConfig.brandPink,
                    child: Text(
                      user?.avatar ?? 'MB',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user?.fullName ?? 'Collaborateur JBF',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    '${user?.poste ?? "Technicien"} • ${user?.sectionNom ?? "Pôle Opérationnel"}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 10),
                const Text('Informations Collaborateur', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Matricule Officiel : ${user?.matricule ?? "JBF-M-2026"}'),
                const SizedBox(height: 4),
                Text('Email Professionnel : ${user?.email ?? ""}'),
                const SizedBox(height: 4),
                Text('Province d\'Affectation : ${user?.province ?? "Haut-Katanga"}'),
                const SizedBox(height: 4),
                Text('Solde Congés Payés : ${user?.soldeConges ?? 18} jours'),
                const SizedBox(height: 14),
                const Text('Paramètres & Coordonnées', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Numéro WhatsApp / Téléphone de contact'),
                ),
                const SizedBox(height: 14),
                const Text('Sécurité du Mot de Passe', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nouveau mot de passe (laisser vide si inchangé)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paramètres et profil mis à jour avec succès.'),
                  backgroundColor: AppConfig.successGreen,
                ),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? AppConfig.brandPinkTint : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _selectedIndex = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? filledIcon : outlineIcon,
                  color: isSelected ? AppConfig.brandPink : Colors.grey.shade700,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppConfig.brandPink : Colors.grey.shade800,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return ListTile(
      leading: Icon(icon, color: isSelected ? AppConfig.brandPink : Colors.grey.shade700),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppConfig.brandPink : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.of(context).pop();
        setState(() => _selectedIndex = index);
      },
    );
  }
}
