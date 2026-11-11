import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'devis_screen.dart';
import 'missions_screen.dart';
import 'factures_screen.dart';
import 'avis_screen.dart';
import 'support_screen.dart';
import 'profil_screen.dart';
import 'login_screen.dart';
import '../navigation/destinations.dart';

class ClientMainScreen extends StatefulWidget {
  final AuthService authService;

  const ClientMainScreen({super.key, required this.authService});

  @override
  State<ClientMainScreen> createState() => _ClientMainScreenState();
}

class _ClientMainScreenState extends State<ClientMainScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Tableau de Bord Entreprise',
    'Mes Devis & Commandes',
    'Suivi des Chantiers & Projets',
    'Factures & Devis Validés',
    'Avis & Satisfaction',
    'Service Client & Support 24/7',
    'Profil Entreprise & Agrément',
  ];

  Widget _buildBody() {
    final client = widget.authService.currentUser;
    if (client == null) {
      return const Center(child: Text('Session expirée'));
    }

    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          client: client,
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
      case 1:
        return DevisScreen(client: client);
      case 2:
        return MissionsScreen(client: client);
      case 3:
        return FacturesScreen(client: client);
      case 4:
        return AvisScreen(client: client);
      case 5:
        return const SupportScreen();
      case 6:
        return ProfilScreen(client: client, authService: widget.authService);
      default:
        return DashboardScreen(
          client: client,
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/243970349724');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous fermer votre session client ?'),
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
    final client = widget.authService.currentUser;
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
                  errorBuilder: (_, __, ___) => const Icon(Icons.business_center, color: AppConfig.brandPink, size: 20),
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
                Text(
                  '${client?.companyName ?? "Espace Partenaire"} • JBF Services RDC',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // WhatsApp direct assistance button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.whatsappGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: _openWhatsApp,
              icon: const Icon(Icons.chat, size: 16),
              label: Text(isDesktop ? 'WhatsApp 24/7' : 'Support', style: const TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),

          // User chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 6),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    child: Text(
                      client?.companyName.isNotEmpty == true ? client!.companyName.substring(0, 2).toUpperCase() : 'CL',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isDesktop)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client?.companyName ?? 'Partenaire',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        client?.fullName ?? 'Client',
                        style: const TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
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
                  _buildNavItem(0, Icons.grid_view, Icons.grid_view, 'Tableau de Bord'),
                  _buildNavItem(1, Icons.description_outlined, Icons.description, 'Devis & Commandes'),
                  _buildNavItem(2, Icons.precision_manufacturing_outlined, Icons.precision_manufacturing, 'Suivi des Chantiers'),
                  _buildNavItem(3, Icons.receipt_long_outlined, Icons.receipt_long, 'Factures & Règlements'),
                  const Divider(indent: 16, endIndent: 16),
                  _buildNavItem(4, Icons.star_outline, Icons.star, 'Avis & Évaluations'),
                  _buildNavItem(5, Icons.support_agent_outlined, Icons.support_agent, 'Service Client 24/7'),
                  _buildNavItem(6, Icons.apartment_outlined, Icons.apartment, 'Profil Entreprise'),
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
                    accountName: Text(client?.companyName ?? 'Société Partenaire'),
                    accountEmail: Text(client?.email ?? 'contact@client.cd'),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        client?.companyName.isNotEmpty == true ? client!.companyName.substring(0, 2).toUpperCase() : 'CL',
                        style: const TextStyle(color: AppConfig.brandPink, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  _buildDrawerItem(0, Icons.grid_view, 'Tableau de Bord'),
                  _buildDrawerItem(1, Icons.description, 'Devis & Commandes'),
                  _buildDrawerItem(2, Icons.precision_manufacturing, 'Suivi des Chantiers'),
                  _buildDrawerItem(3, Icons.receipt_long, 'Factures & Règlements'),
                  _buildDrawerItem(4, Icons.star, 'Avis & Évaluations'),
                  _buildDrawerItem(5, Icons.support_agent, 'Service Client 24/7'),
                  _buildDrawerItem(6, Icons.apartment, 'Profil Entreprise'),
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
              currentIndex: clientMobilePrimary.contains(_selectedIndex)
                  ? clientMobilePrimary.indexOf(_selectedIndex)
                  : clientMobilePrimary.length,
              onTap: (idx) {
                if (idx == clientMobilePrimary.length) {
                  _openAllPages();
                  return;
                }
                setState(() => _selectedIndex = clientMobilePrimary[idx]);
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppConfig.brandPink,
              unselectedItemColor: Colors.grey.shade600,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.description), label: 'Devis'),
                BottomNavigationBarItem(icon: Icon(Icons.precision_manufacturing), label: 'Chantiers'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Factures'),
                BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'Pages'),
              ],
            ),
    );
  }

  void _openAllPages() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          children: [
            const ListTile(title: Text('Toutes les pages', style: TextStyle(fontWeight: FontWeight.bold))),
            for (final destination in clientDestinations)
              ListTile(
                title: Text(destination.label),
                selected: _selectedIndex == destination.index,
                onTap: () {
                  setState(() => _selectedIndex = destination.index);
                  Navigator.of(ctx).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? AppConfig.brandPinkTint : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? selectedIcon : unselectedIcon,
          color: isSelected ? AppConfig.brandPink : Colors.grey.shade700,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppConfig.brandPink : AppConfig.blackText,
            fontSize: 13,
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
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppConfig.brandPink : AppConfig.blackText,
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
