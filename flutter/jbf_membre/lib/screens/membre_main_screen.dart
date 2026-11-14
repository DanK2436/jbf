import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'missions_screen.dart';
import 'timesheet_screen.dart';
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
    'Feuilles de Temps & Pointages GPS',
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
        return const TimesheetScreen();
      case 3:
        return LeavesScreen(user: user);
      case 4:
        return ChatScreen(user: user);
      case 5:
        return const ResourcesScreen();
      case 6:
        return DevisMembreScreen(user: user);
      case 7:
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
                  _buildNavItem(6, Icons.request_quote_outlined, Icons.request_quote, 'Devis & BDD Matériaux'),
                  _buildNavItem(7, Icons.task_alt_outlined, Icons.task_alt, 'Progression des Missions'),
                  const Divider(indent: 16, endIndent: 16),
                  _buildNavItem(2, Icons.access_time_outlined, Icons.access_time, 'Pointages & Horaires'),
                  _buildNavItem(3, Icons.beach_access_outlined, Icons.beach_access, 'Mes Congés RH'),
                  _buildNavItem(4, Icons.chat_outlined, Icons.chat, 'Messagerie Équipe'),
                  _buildNavItem(5, Icons.folder_outlined, Icons.folder, 'Bibliothèque HSE'),
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
                  _buildDrawerItem(6, Icons.request_quote, 'Devis & BDD Matériaux'),
                  _buildDrawerItem(7, Icons.task_alt, 'Progression des Missions'),
                  _buildDrawerItem(2, Icons.access_time, 'Pointages & Horaires'),
                  _buildDrawerItem(3, Icons.beach_access, 'Mes Congés RH'),
                  _buildDrawerItem(4, Icons.chat, 'Messagerie Équipe'),
                  _buildDrawerItem(5, Icons.folder, 'Bibliothèque HSE'),
                ],
              ),
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
