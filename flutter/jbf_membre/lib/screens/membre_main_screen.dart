import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'missions_screen.dart';
import 'timesheet_screen.dart';
import 'leaves_screen.dart';
import 'chat_screen.dart';
import 'resources_screen.dart';
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
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.engineering, color: AppConfig.brandPink, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titles[_selectedIndex],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${user?.fullName ?? "Collaborateur"} (${user?.matricule ?? ""}) • JBF Service RDC',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
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
                    user?.avatar ?? 'JM',
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
                        user?.fullName ?? 'Jean-Pierre Mulamba',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        user?.poste ?? 'Chef d\'Équipe',
                        style: const TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ],
                  ),
                const SizedBox(width: 10),
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
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey.shade200)),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Tableau de Bord'),
                  _buildNavItem(1, Icons.assignment_outlined, Icons.assignment, 'Mes Missions'),
                  _buildNavItem(2, Icons.access_time_outlined, Icons.access_time_filled, 'Feuilles de Temps'),
                  _buildNavItem(3, Icons.beach_access_outlined, Icons.beach_access, 'Mes Congés & Absences'),
                  const Divider(indent: 16, endIndent: 16),
                  _buildNavItem(4, Icons.chat_bubble_outline, Icons.chat_bubble, 'Messagerie Équipe'),
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
                    accountName: Text(user?.fullName ?? 'Jean-Pierre Mulamba'),
                    accountEmail: Text('${user?.matricule} • ${user?.poste}'),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        user?.avatar ?? 'JM',
                        style: const TextStyle(color: AppConfig.brandPink, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  _buildDrawerItem(0, Icons.dashboard, 'Tableau de Bord'),
                  _buildDrawerItem(1, Icons.assignment, 'Mes Missions'),
                  _buildDrawerItem(2, Icons.access_time_filled, 'Feuilles de Temps'),
                  _buildDrawerItem(3, Icons.beach_access, 'Mes Congés'),
                  _buildDrawerItem(4, Icons.chat_bubble, 'Messagerie Équipe'),
                  _buildDrawerItem(5, Icons.folder, 'Bibliothèque HSE'),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppConfig.dangerRed),
                    title: const Text('Déconnexion', style: TextStyle(color: AppConfig.dangerRed)),
                    onTap: _handleLogout,
                  ),
                ],
              ),
            ),
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
                BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Missions'),
                BottomNavigationBarItem(icon: Icon(Icons.access_time_filled), label: 'Temps'),
                BottomNavigationBarItem(icon: Icon(Icons.beach_access), label: 'Congés'),
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
