import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';
  String _selectedStatutFilter = 'tous'; // 'tous', 'actif', 'desactive'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final url = '${AppConfig.apiBaseUrl}/admin/users';
      final fallbackUrl = '${AppConfig.supabaseUrl}/rest/v1/profiles?select=*&order=created_at.desc';

      http.Response res;
      try {
        res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      } catch (_) {
        res = await http.get(
          Uri.parse(fallbackUrl),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
        ).timeout(const Duration(seconds: 6));
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data is Map && data['users'] != null)
            ? (data['users'] as List)
            : (data is List ? data : []);

        if (mounted) {
          setState(() {
            _users = list.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Erreur chargement utilisateurs: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredUsers() {
    final currentTabRole = switch (_tabController.index) {
      1 => 'client',
      2 => 'membre',
      3 => 'sous_admin',
      _ => 'tous',
    };

    return _users.where((u) {
      final role = (u['role'] ?? 'client').toString().toLowerCase();
      final name = (u['full_name'] ?? u['nom_complet'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final company = (u['company'] ?? u['entreprise'] ?? '').toString().toLowerCase();
      final phone = (u['phone'] ?? u['telephone'] ?? '').toString();
      final isDisabled = u['is_disabled'] == true || u['statut_compte'] == 'desactive';

      // Filtre rôle onglet
      if (currentTabRole != 'tous' && !role.contains(currentTabRole)) return false;

      // Filtre statut
      if (_selectedStatutFilter == 'actif' && isDisabled) return false;
      if (_selectedStatutFilter == 'desactive' && !isDisabled) return false;

      // Filtre recherche
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return name.contains(q) || email.contains(q) || company.contains(q) || phone.contains(q);
      }

      return true;
    }).toList();
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final bool currentDisabled = user['is_disabled'] == true || user['statut_compte'] == 'desactive';
    final bool targetDisable = !currentDisabled;
    final userId = user['id'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(targetDisable ? 'Désactiver le compte' : 'Réactiver le compte'),
        content: Text(
          targetDisable
              ? 'Voulez-vous suspendre l\'accès de cet utilisateur ? Toutes ses sessions actives seront instantanément révoquées.'
              : 'Voulez-vous autoriser à nouveau cet utilisateur à se connecter ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: targetDisable ? AppConfig.dangerRed : AppConfig.successGreen,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(targetDisable ? 'Confirmer la désactivation' : 'Réactiver'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Appel API V2 ou PATCH Supabase direct
      final url = '${AppConfig.apiBaseUrl}/admin/users/$userId/desactiver';
      await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'desactiver': targetDisable}),
      ).timeout(const Duration(seconds: 4));

      // Mise à jour locale immédiate
      setState(() {
        user['is_disabled'] = targetDisable;
        user['statut_compte'] = targetDisable ? 'desactive' : 'actif';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(targetDisable ? 'Compte désactivé et sessions fermées.' : 'Compte réactivé avec succès.'),
          backgroundColor: targetDisable ? AppConfig.dangerRed : AppConfig.successGreen,
        ),
      );
    } catch (_) {
      // Fallback Supabase PATCH direct
      try {
        final sbUrl = '${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.$userId';
        await http.patch(
          Uri.parse(sbUrl),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'is_disabled': targetDisable,
            'statut_compte': targetDisable ? 'desactive' : 'actif',
            'token_invalidation_ts': DateTime.now().toIso8601String(),
          }),
        );
        setState(() {
          user['is_disabled'] = targetDisable;
          user['statut_compte'] = targetDisable ? 'desactive' : 'actif';
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppConfig.dangerRed),
        );
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final userId = user['id'];
    final userName = user['full_name'] ?? user['email'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer définitivement l\'utilisateur'),
        content: Text('Êtes-vous sûr de vouloir supprimer définitivement $userName ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final url = '${AppConfig.apiBaseUrl}/admin/users/$userId';
      await http.delete(Uri.parse(url)).timeout(const Duration(seconds: 4));
    } catch (_) {
      final sbUrl = '${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.$userId';
      await http.delete(
        Uri.parse(sbUrl),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      );
    }

    setState(() {
      _users.removeWhere((u) => u['id'] == userId);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Utilisateur supprimé avec succès.')),
    );
  }

  void _showAddUserDialog() {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'JbfPass2026!');
    final phoneCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    final posteCtrl = TextEditingController();
    String selectedRole = 'client';
    String selectedProvince = 'Haut-Katanga';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: AppConfig.brandPink),
              SizedBox(width: 10),
              Text('Ajouter un Utilisateur'),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: const InputDecoration(labelText: 'Rôle'),
                          items: const [
                            DropdownMenuItem(value: 'client', child: Text('Client B2B')),
                            DropdownMenuItem(value: 'membre', child: Text('Membre Collaborateur')),
                            DropdownMenuItem(value: 'sous_admin', child: Text('Sous-Administrateur')),
                          ],
                          onChanged: (v) => setDlgState(() => selectedRole = v!),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedProvince,
                          decoration: const InputDecoration(labelText: 'Province'),
                          items: const [
                            DropdownMenuItem(value: 'Haut-Katanga', child: Text('Haut-Katanga')),
                            DropdownMenuItem(value: 'Lualaba', child: Text('Lualaba (Kolwezi)')),
                            DropdownMenuItem(value: 'Kinshasa', child: Text('Kinshasa')),
                            DropdownMenuItem(value: 'Kongo Central', child: Text('Kongo Central')),
                            DropdownMenuItem(value: 'Nord-Kivu', child: Text('Nord-Kivu')),
                            DropdownMenuItem(value: 'Autre', child: Text('Autre Province')),
                          ],
                          onChanged: (v) => setDlgState(() => selectedProvince = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom Complet *', hintText: 'ex: Serge Tshisekedi'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email Professionnel *', hintText: 'ex: serge@entreprise.cd'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          decoration: const InputDecoration(labelText: 'Téléphone WhatsApp', hintText: '+243 ...'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: passCtrl,
                          decoration: const InputDecoration(labelText: 'Mot de passe initial *'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: companyCtrl,
                          decoration: const InputDecoration(labelText: 'Entreprise / Société'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: posteCtrl,
                          decoration: const InputDecoration(labelText: 'Poste / Spécialité'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
              onPressed: () async {
                if (emailCtrl.text.isEmpty || nameCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez remplir les champs obligatoires (*).')),
                  );
                  return;
                }

                Navigator.of(ctx).pop();
                setState(() => _isLoading = true);

                try {
                  final url = '${AppConfig.apiBaseUrl}/admin/users/creer';
                  final res = await http.post(
                    Uri.parse(url),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'email': emailCtrl.text.trim(),
                      'password': passCtrl.text.trim(),
                      'full_name': nameCtrl.text.trim(),
                      'role': selectedRole,
                      'phone': phoneCtrl.text.trim(),
                      'company': companyCtrl.text.trim(),
                      'poste': posteCtrl.text.trim(),
                      'province': selectedProvince,
                    }),
                  );

                  if (res.statusCode == 201 || res.statusCode == 200) {
                    _loadUsers();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Utilisateur créé avec succès.'), backgroundColor: AppConfig.successGreen),
                    );
                  } else {
                    final err = jsonDecode(res.body)['error'] ?? 'Échec création';
                    throw Exception(err);
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppConfig.dangerRed),
                  );
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('Enregistrer le compte'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredUsers();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gestion Unifiée des Utilisateurs',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText),
                      ),
                      Text(
                        'Supervision des accès : Clients B2B, Membres Collaborateurs et Sous-Administrateurs',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter un Utilisateur'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.brandPink,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          // Tabs & Filters Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppConfig.brandPink,
                  labelColor: AppConfig.brandPink,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  tabs: [
                    Tab(text: 'Tous les Comptes (${_users.length})'),
                    Tab(text: 'Clients (${_users.where((u) => (u['role'] ?? '') == 'client').length})'),
                    Tab(text: 'Membres (${_users.where((u) => (u['role'] ?? '') == 'membre').length})'),
                    Tab(text: 'Sous-Admins (${_users.where((u) => (u['role'] ?? '').toString().contains('admin')).length})'),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Rechercher par nom, email, société, téléphone...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF9FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedStatutFilter,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'tous', child: Text('Tous les Statuts')),
                          DropdownMenuItem(value: 'actif', child: Text('Uniquement Actifs')),
                          DropdownMenuItem(value: 'desactive', child: Text('Uniquement Désactivés')),
                        ],
                        onChanged: (v) => setState(() => _selectedStatutFilter = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Rafraîchir la liste',
                      onPressed: _loadUsers,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // User Table List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('Aucun utilisateur correspondant trouvé.', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final u = filtered[index];
                          final role = (u['role'] ?? 'client').toString().toUpperCase();
                          final isDisabled = u['is_disabled'] == true || u['statut_compte'] == 'desactive';
                          final name = u['full_name'] ?? u['nom_complet'] ?? 'Utilisateur Sans Nom';
                          final email = u['email'] ?? 'Sans email';
                          final company = u['company'] ?? u['entreprise'] ?? 'Partenaire JBF';
                          final province = u['province'] ?? 'Haut-Katanga';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDisabled ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
                                width: isDisabled ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: isDisabled
                                      ? Colors.grey.shade300
                                      : (role.contains('ADMIN')
                                          ? AppConfig.brandPink
                                          : (role.contains('MEMBRE') ? Colors.blue.shade700 : Colors.teal.shade700)),
                                  child: Text(
                                    name.toString().substring(0, name.toString().length >= 2 ? 2 : 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isDisabled ? Colors.grey.shade600 : AppConfig.blackText,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: role.contains('ADMIN')
                                                  ? AppConfig.brandPinkTint
                                                  : (role.contains('MEMBRE') ? Colors.blue.shade50 : Colors.teal.shade50),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              role,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: role.contains('ADMIN')
                                                    ? AppConfig.brandPink
                                                    : (role.contains('MEMBRE') ? Colors.blue.shade800 : Colors.teal.shade800),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isDisabled ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isDisabled ? 'DÉSACTIVÉ' : 'ACTIF',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isDisabled ? AppConfig.dangerRed : AppConfig.successGreen,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(email, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
                                          const SizedBox(width: 16),
                                          Icon(Icons.business_outlined, size: 14, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(company, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
                                          const SizedBox(width: 16),
                                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(province, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _toggleUserStatus(u),
                                      icon: Icon(
                                        isDisabled ? Icons.check_circle_outline : Icons.block,
                                        size: 15,
                                      ),
                                      label: Text(isDisabled ? 'Réactiver' : 'Désactiver'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDisabled ? AppConfig.successGreen : Colors.orange.shade800,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppConfig.dangerRed),
                                      tooltip: 'Supprimer',
                                      onPressed: () => _deleteUser(u),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
