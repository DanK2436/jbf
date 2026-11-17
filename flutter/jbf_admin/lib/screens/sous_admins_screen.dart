import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/admin_models.dart';
import '../services/supabase_service.dart';

class SousAdminsScreen extends StatefulWidget {
  const SousAdminsScreen({super.key});

  @override
  State<SousAdminsScreen> createState() => _SousAdminsScreenState();
}

class _SousAdminsScreenState extends State<SousAdminsScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<SousAdminItem> _list = [];

  @override
  void initState() {
    super.initState();
    _loadSousAdmins();
  }

  Future<void> _loadSousAdmins() async {
    setState(() => _isLoading = true);
    final accounts = await _supabase.fetchSousAdmins();
    if (!mounted) return;
    setState(() {
      _list = accounts;
      _isLoading = false;
    });
  }

  void _showAddSousAdminDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final Set<String> perms = {'dashboard', 'missions'};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Créer un Compte Gestionnaire dans Supabase (BDD)'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nom et Prénom', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'ex: Patrick Mwamba')),
                  const SizedBox(height: 12),
                  const Text('Email Manuel pour Réception Code OTP', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(hintText: 'ex: p.mwamba@jbf.cd')),
                  const SizedBox(height: 16),
                  const Text('Permissions d\'accès granulaires', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      'dashboard',
                      'devis',
                      'missions',
                      'pointages',
                      'conges',
                      'avis',
                      'membres',
                    ].map((p) {
                      final isSelected = perms.contains(p);
                      return FilterChip(
                        label: Text(p.toUpperCase(), style: const TextStyle(fontSize: 11)),
                        selected: isSelected,
                        selectedColor: AppConfig.brandPinkTint,
                        checkmarkColor: AppConfig.brandPink,
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              perms.add(p);
                            } else {
                              perms.remove(p);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
                Navigator.of(ctx).pop();

                final sa = SousAdminItem(
                  id: '',
                  fullName: nameCtrl.text,
                  email: emailCtrl.text.trim().toLowerCase(),
                  permissions: perms.toList(),
                );

                await _supabase.createSousAdmin(sa);
                _loadSousAdmins();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sous-administrateur créé dans la table admin_accounts de Supabase')),
                );
              },
              child: const Text('Enregistrer dans Supabase'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPermissionsDialog(SousAdminItem sa) {
    final Map<String, String> availablePages = {
      'dashboard': 'Tableau de bord exécutif',
      'utilisateurs': 'Gestion des utilisateurs & rôles',
      'projets': 'Commandes & Projets Complexes WBS',
      'missions': 'Missions & Chantiers opérationnels',
      'devis': 'Devis clients & chiffrages membres',
      'services': 'Catalogue des services (15)',
      'rh': 'Ressources Humaines & Compétences',
      'recrutement': 'Candidatures & Recrutement public',
      'finances': 'Finances, Écritures & Reçus',
      'communication': 'Communication & CMS diffusion',
      'galerie': 'Galerie Médias (Photos & Vidéos)',
      'chat_clients': 'Messagerie dédiée aux clients',
      'cms_dynamic': 'Configuration & Toggles de contenus',
      'evaluations': 'Contrôle & Validation des Évaluations',
      'audit': 'Traçabilité & Journal d\'audit',
    };

    final Set<String> currentPerms = Set.from(sa.permissions);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.security, color: AppConfig.brandPink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Accès aux Pages — ${sa.fullName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cochez les pages et modules auxquels ce sous-administrateur a le droit d\'accéder :',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: availablePages.entries.map((entry) {
                      final isGranted = currentPerms.contains(entry.key) || currentPerms.contains('*');
                      return CheckboxListTile(
                        dense: true,
                        activeColor: AppConfig.brandPink,
                        title: Text(entry.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('Code permission : ${entry.key}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        value: isGranted,
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              currentPerms.add(entry.key);
                            } else {
                              currentPerms.remove(entry.key);
                              currentPerms.remove('*');
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
              onPressed: () async {
                Navigator.of(ctx).pop();
                setState(() => _isLoading = true);

                try {
                  // Mise à jour permissions dans Supabase
                  await _supabase.client
                      .from('admin_accounts')
                      .update({'permissions': currentPerms.toList()})
                      .eq('id', sa.id);
                } catch (e) {
                  debugPrint('Erreur mise à jour permissions: $e');
                }

                _loadSousAdmins();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permissions des pages mises à jour avec succès.'),
                    backgroundColor: AppConfig.successGreen,
                  ),
                );
              },
              child: const Text('Enregistrer les Accès'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    return RefreshIndicator(
      onRefresh: _loadSousAdmins,
      color: AppConfig.brandPink,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gouvernance & Comptes Sous-Administrateurs (BDD)',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Données réelles de la table admin_accounts Supabase',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                      tooltip: 'Actualiser',
                      onPressed: _loadSousAdmins,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.security, size: 18),
                      label: const Text('Nouveau Sous-Admin'),
                      onPressed: _showAddSousAdminDialog,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _list.isEmpty
                      ? const Center(child: Text('Aucun sous-administrateur dans la base de données.'))
                      : ListView.separated(
                          itemCount: _list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final sa = _list[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              leading: CircleAvatar(
                                backgroundColor: sa.isActive ? AppConfig.brandPink : Colors.grey,
                                foregroundColor: Colors.white,
                                child: const Icon(Icons.manage_accounts),
                              ),
                              title: Text(sa.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Email OTP : ${sa.email}'),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: sa.permissions
                                        .map((p) => Chip(
                                              label: Text(p, style: const TextStyle(fontSize: 10)),
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.security_update_good, color: AppConfig.brandPink, size: 20),
                                    tooltip: 'Définir les pages et permissions autorisées',
                                    onPressed: () => _showEditPermissionsDialog(sa),
                                  ),
                                  Switch(
                                    value: sa.isActive,
                                    activeColor: AppConfig.brandPink,
                                    onChanged: (val) async {
                                      await _supabase.toggleSousAdmin(sa.id, val);
                                      _loadSousAdmins();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
