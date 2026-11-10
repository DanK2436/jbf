import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'devis_screen.dart';
import 'missions_screen.dart';
import 'pointages_screen.dart';
import 'conges_screen.dart';
import 'avis_screen.dart';
import 'membres_screen.dart';
import 'sous_admins_screen.dart';
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
    'Demandes de Devis & Chiffrage',
    'Gestion des Chantiers & Missions',
    'Contrôle des Pointages & Anti-VPN',
    'Validation des Congés RH',
    'Modération des Avis Clients',
    'Annuaire des Collaborateurs',
    'Gestion des Sous-Administrateurs',
    'Sécurité OTP Admin Principal',
  ];

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(onNavigate: (index) => setState(() => _selectedIndex = index));
      case 1:
        return const DevisScreen();
      case 2:
        return const MissionsScreen();
      case 3:
        return const PointagesScreen();
      case 4:
        return const CongesScreen();
      case 5:
        return const AvisScreen();
      case 6:
        return const MembresScreen();
      case 7:
        return const SousAdminsScreen();
      case 8:
        return const OtpSettingsScreen();
      default:
        return const DashboardScreen(onNavigate: _dummyNavigate);
    }
  }

  static void _dummyNavigate(int _) {}

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
    final isDesktop = MediaQuery.of(context).size.width >= 900;

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titles[_selectedIndex],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'JBF Service SARL — Espace Administration Native',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // User chip
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
                  onPressed: () => setState(() => _selectedIndex = 8),
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
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey.shade200)),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Tableau de Bord'),
                  _buildNavItem(1, Icons.request_quote_outlined, Icons.request_quote, 'Devis & Commandes'),
                  _buildNavItem(2, Icons.engineering_outlined, Icons.engineering, 'Missions & Chantiers'),
                  _buildNavItem(3, Icons.fingerprint, Icons.fingerprint, 'Pointages & Anti-VPN'),
                  const Divider(indent: 16, endIndent: 16),
                  _buildNavItem(4, Icons.beach_access_outlined, Icons.beach_access, 'Validation Congés'),
                  _buildNavItem(5, Icons.star_outline, Icons.star, 'Modération Avis'),
                  _buildNavItem(6, Icons.people_outline, Icons.people, 'Membres RH'),
                  _buildNavItem(7, Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, 'Sous-Administrateurs'),
                  const Divider(indent: 16, endIndent: 16),
                  _buildNavItem(8, Icons.shield_outlined, Icons.shield, 'Sécurité OTP Direction'),
                ],
              ),
            ),

          // Main Screen Body
          Expanded(child: _buildBody()),
        ],
      ),
      // Mobile Drawer if width < 900
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
                  _buildDrawerItem(1, Icons.request_quote, 'Devis & Commandes'),
                  _buildDrawerItem(2, Icons.engineering, 'Missions & Chantiers'),
                  _buildDrawerItem(3, Icons.fingerprint, 'Pointages & Anti-VPN'),
                  _buildDrawerItem(4, Icons.beach_access, 'Validation Congés'),
                  _buildDrawerItem(5, Icons.star, 'Modération Avis'),
                  _buildDrawerItem(6, Icons.people, 'Membres RH'),
                  _buildDrawerItem(7, Icons.admin_panel_settings, 'Sous-Administrateurs'),
                  _buildDrawerItem(8, Icons.shield, 'Sécurité OTP Direction'),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppConfig.dangerRed),
                    title: const Text('Déconnexion', style: TextStyle(color: AppConfig.dangerRed)),
                    onTap: _handleLogout,
                  ),
                ],
              ),
            ),
      // Mobile bottom bar for top 4 items if on small screens
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
              onTap: (idx) => setState(() => _selectedIndex = idx),
              selectedItemColor: AppConfig.brandPink,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.request_quote), label: 'Devis'),
                BottomNavigationBarItem(icon: Icon(Icons.engineering), label: 'Missions'),
                BottomNavigationBarItem(icon: Icon(Icons.fingerprint), label: 'Pointage'),
              ],
            ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isSelected ? AppConfig.brandPinkTint : Colors.transparent,
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppConfig.brandPink : Colors.grey.shade700,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppConfig.brandPinkDark : AppConfig.blackText,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () => setState(() => _selectedIndex = index),
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
          color: isSelected ? AppConfig.brandPink : AppConfig.blackText,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.of(context).pop();
      },
    );
  }
}
