import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'users_management_screen.dart';
import 'projets_commandes_screen.dart';
import 'missions_screen.dart';
import 'devis_screen.dart';
import 'services_screen.dart';
import 'resources_admin_screen.dart';
import 'recrutement_admin_screen.dart';
import 'finance_screen.dart';
import 'communication_cms_screen.dart';
import 'client_chat_admin_screen.dart';
import 'gallery_management_screen.dart';
import 'cms_content_manager_screen.dart';
import 'evaluations_screen.dart';
import 'audit_screen.dart';
import 'otp_settings_screen.dart';
import 'login_screen.dart';

class AdminMainScreen extends StatefulWidget {
  final AuthService authService;

  const AdminMainScreen({super.key, required this.authService});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Super Dashboard Exécutif',
    'Gestion des Utilisateurs (Clients, Membres, Sous-Admins)',
    'Commandes & Projets Complexes (WBS & Budget)',
    'Missions, Chantiers & Livrables Sécurisés',
    'Réception Devis Membres & Chiffrage Client',
    'Catalogue Dynamique des Services (15)',
    'Bibliothèque Documentaire & Ressources Membres (HSE)',
    'Recrutement & Candidatures Déposées (Activer/Désactiver)',
    'Gestion Financière, Écritures & Reçus Clients',
    'Communication, CMS & Chat Membres/Responsables',
    'Live Chat Dédié Clients B2B & Support',
    'Galerie Photos & Vidéos (CMS)',
    'Gestion & Activation des Contenus (Site & Apps)',
    'Modération & Vérification des Évaluations Clients',
    'Audit Système & Journal des Opérations Traçables',
    'Sécurité OTP Admin Principal',
  ];

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(onNavigate: (index) => setState(() => _selectedIndex = index));
      case 1:
        return const UsersManagementScreen();
      case 2:
        return const ProjetsCommandesScreen();
      case 3:
        return const MissionsScreen();
      case 4:
        return const DevisScreen();
      case 5:
        return const ServicesScreen();
      case 6:
        return const ResourcesAdminScreen();
      case 7:
        return const RecrutementAdminScreen();
      case 8:
        return const FinanceScreen();
      case 9:
        return const CommunicationCmsScreen();
      case 10:
        return const ClientChatAdminScreen();
      case 11:
        return const GalleryManagementScreen();
      case 12:
        return const CmsContentManagerScreen();
      case 13:
        return const EvaluationsScreen();
      case 14:
        return const AuditScreen();
      case 15:
        return const OtpSettingsScreen();
      default:
        return const DashboardScreen(onNavigate: _noOpNavigate);
    }
  }

  static void _noOpNavigate(int _) {}

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion Direction'),
        content: const Text('Voulez-vous fermer votre session d\'administration sécurisée ?'),
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: AppConfig.brandPink, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titles[_selectedIndex],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'JBF Service SARL — Espace Administration Native RDC',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  child: Text(
                    user?.avatar ?? 'DG',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                if (isDesktop)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Direction Générale',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        user?.role ?? 'Super Administrateur',
                        style: const TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ],
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.shield_outlined, color: Colors.white),
                  tooltip: 'Sécurité OTP Admin',
                  onPressed: () => setState(() => _selectedIndex = 15),
                ),
                const SizedBox(width: 4),
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
          // Desktop sidebar navigation
          if (isDesktop)
            Container(
              width: 275,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey.shade200)),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Tableau de Bord Exécutif'),
                  const Divider(indent: 16, endIndent: 16),
                  _buildNavItem(1, Icons.people_outline, Icons.people, 'Gestion Utilisateurs'),
                  _buildNavItem(2, Icons.account_tree_outlined, Icons.account_tree, 'Commandes & Projets WBS'),
                  _buildNavItem(3, Icons.engineering_outlined, Icons.engineering, 'Missions & Chantiers'),
                  _buildNavItem(4, Icons.request_quote_outlined, Icons.request_quote, 'Devis & Chiffrage Client'),
                  _buildNavItem(5, Icons.handyman_outlined, Icons.handyman, 'Catalogue des Services'),
                  _buildNavItem(6, Icons.folder_shared_outlined, Icons.folder_shared, 'Ressources Membres'),
                  _buildNavItem(7, Icons.assignment_ind_outlined, Icons.assignment_ind, 'Recrutement & CV Déposés'),
                  _buildNavItem(8, Icons.account_balance_outlined, Icons.account_balance, 'Finance & Reçus'),
                  const Divider(indent: 16, endIndent: 16),
                  _buildNavItem(9, Icons.forum_outlined, Icons.forum, 'Chat Membres & Domaines'),
                  _buildNavItem(10, Icons.support_agent_outlined, Icons.support_agent, 'Chat Dédié Clients B2B'),
                  _buildNavItem(11, Icons.photo_library_outlined, Icons.photo_library, 'Galerie Photos & Vidéos'),
                  _buildNavItem(12, Icons.tune_outlined, Icons.tune, 'Contenus & Textes CMS'),
                  _buildNavItem(13, Icons.rate_review_outlined, Icons.rate_review, 'Évaluations & Avis'),
                  _buildNavItem(14, Icons.policy_outlined, Icons.policy, 'Audit & Sécurité Système'),
                  const Divider(indent: 16, endIndent: 16),
                  _buildNavItem(15, Icons.shield_outlined, Icons.shield, 'Sécurité OTP Direction'),
                ],
              ),
            ),

          // Main Screen Body
          Expanded(child: _buildBody()),
        ],
      ),
      // Mobile Drawer if width < 960
      drawer: isDesktop
          ? null
          : Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(color: AppConfig.brandPink),
                    accountName: Text(user?.fullName ?? 'Direction Générale'),
                    accountEmail: Text(user?.email ?? 'services@admin.jbf'),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        user?.avatar ?? 'DG',
                        style: const TextStyle(color: AppConfig.brandPink, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  _buildDrawerItem(0, Icons.dashboard, 'Tableau de Bord'),
                  _buildDrawerItem(1, Icons.people, 'Gestion Utilisateurs'),
                  _buildDrawerItem(2, Icons.account_tree, 'Commandes & Projets WBS'),
                  _buildDrawerItem(3, Icons.engineering, 'Missions & Chantiers'),
                  _buildDrawerItem(4, Icons.request_quote, 'Devis & Chiffrage Client'),
                  _buildDrawerItem(5, Icons.handyman, 'Catalogue des Services'),
                  _buildDrawerItem(6, Icons.folder_shared, 'Ressources Membres'),
                  _buildDrawerItem(7, Icons.assignment_ind, 'Recrutement & CV Déposés'),
                  _buildDrawerItem(8, Icons.account_balance, 'Finance & Reçus'),
                  const Divider(),
                  _buildDrawerItem(9, Icons.forum, 'Chat Membres & Domaines'),
                  _buildDrawerItem(10, Icons.support_agent, 'Chat Dédié Clients B2B'),
                  _buildDrawerItem(11, Icons.photo_library, 'Galerie Photos & Vidéos'),
                  _buildDrawerItem(12, Icons.tune, 'Contenus & Textes CMS'),
                  _buildDrawerItem(13, Icons.rate_review, 'Évaluations & Avis'),
                  _buildDrawerItem(14, Icons.policy, 'Audit & Sécurité'),
                  _buildDrawerItem(15, Icons.shield, 'Sécurité OTP Direction'),
                ],
              ),
            ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: isSelected ? AppConfig.brandPinkTint : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _selectedIndex = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(
                  isSelected ? filledIcon : outlineIcon,
                  color: isSelected ? AppConfig.brandPink : Colors.grey.shade700,
                  size: 19,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppConfig.brandPink : Colors.grey.shade800,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12.5,
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
