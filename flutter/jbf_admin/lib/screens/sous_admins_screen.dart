import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final passCtrl = TextEditingController(text: 'Services+243JBF');
    final Set<String> perms = {'dashboard', 'missions'};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Color(0xFF1E293B)),
              SizedBox(width: 10),
              Text('Créer un Sous-Admin (Supabase BDD)'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nom et Prénom *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'ex: Patrick Mwamba')),
                  const SizedBox(height: 12),
                  const Text('Email Administratif de Connexion *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(hintText: 'ex: p.mwamba@jbf-admin.cd')),
                  const SizedBox(height: 12),
                  const Text('Mot de Passe Sécurisé d\'Accès *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                      hintText: 'ex: Services+243JBF',
                      helperText: 'Ce mot de passe servira au sous-administrateur pour se connecter au portail Admin.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Permissions d\'accès granulaires (Pages autorisées) :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      'dashboard',
                      'users',
                      'commandes',
                      'missions',
                      'devis',
                      'services',
                      'resources',
                      'recrutement',
                      'finance',
                      'chat_membres',
                      'chat_clients',
                      'gallery',
                      'cms',
                      'evaluations',
                      'audit',
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez remplir le nom, l\'email et le mot de passe.')),
                  );
                  return;
                }
                Navigator.of(ctx).pop();

                final sa = SousAdminItem(
                  id: '',
                  fullName: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim().toLowerCase(),
                  permissions: perms.toList(),
                  password: passCtrl.text.trim(),
                );

                final ok = await _supabase.createSousAdmin(sa, password: passCtrl.text.trim());
                _loadSousAdmins();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Sous-administrateur créé et synchronisé (Auth + Admin Accounts + Profiles) !' : 'Enregistrement terminé.'),
                      backgroundColor: ok ? AppConfig.successGreen : Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Créer le Sous-Admin'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSousAdminDetailsDialog(SousAdminItem sa) {
    bool showPassword = false;
    final passToDisplay = (sa.password != null && sa.password!.isNotEmpty) ? sa.password! : 'Services+243JBF';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: sa.isActive ? AppConfig.brandPink : Colors.grey,
                foregroundColor: Colors.white,
                child: const Icon(Icons.manage_accounts),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sa.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConfig.brandPinkTint,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SOUS-ADMINISTRATEUR',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppConfig.brandPink),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: sa.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sa.isActive ? 'ACTIF' : 'DÉSACTIVÉ',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: sa.isActive ? AppConfig.successGreen : AppConfig.dangerRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildSousAdminDetailItem('Nom et Prénom', sa.fullName, Icons.person_outline),
                  const SizedBox(height: 10),
                  _buildSousAdminDetailItem('Email Administratif OTP', sa.email, Icons.email_outlined, canCopy: true),
                  const SizedBox(height: 12),

                  // MOT DE PASSE (AVEC AFFICHAGE & COPIE)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, color: AppConfig.brandPink, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mot de Passe Sécurisé :',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                showPassword ? passToDisplay : '••••••••••••',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, letterSpacing: 0.8),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, size: 18),
                          tooltip: showPassword ? 'Masquer' : 'Afficher',
                          onPressed: () => setDlgState(() => showPassword = !showPassword),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copier le mot de passe',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: passToDisplay));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mot de passe copié !')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Text('Pages & Modules Autorisés :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: sa.permissions
                        .map((p) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p.toUpperCase(),
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fermer')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Modifier cette fiche'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _showEditSousAdminDialog(sa);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSousAdminDetailItem(String label, String value, IconData icon, {bool canCopy = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canCopy)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label copié !')),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.copy, size: 14, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditSousAdminDialog(SousAdminItem sa) {
    final nameCtrl = TextEditingController(text: sa.fullName);
    final emailCtrl = TextEditingController(text: sa.email);
    final passCtrl = TextEditingController(text: sa.password ?? 'Services+243JBF');
    bool isActive = sa.isActive;

    final Map<String, String> availablePages = {
      'dashboard': 'Tableau de bord exécutif',
      'users': 'Gestion Utilisateurs (Clients & Membres)',
      'commandes': 'Commandes & Projets WBS',
      'missions': 'Missions, Chantiers & Livrables',
      'devis': 'Devis & Chiffrage Client',
      'services': 'Catalogue Dynamique des Services (15)',
      'resources': 'Ressources & Directives Membres (HSE)',
      'recrutement': 'Recrutement & CV Déposés',
      'finance': 'Gestion Financière & Reçus',
      'chat_membres': 'Communication & Chat Membres',
      'chat_clients': 'Chat Dédié Clients B2B & Support',
      'gallery': 'Galerie Photos & Vidéos (CMS)',
      'cms': 'Gestionnaire Contenus CMS & Textes',
      'evaluations': 'Modération des Évaluations & Avis',
      'audit': 'Journal d\'Audit & Sécurité',
    };

    final Set<String> currentPerms = Set.from(sa.permissions);
    if (currentPerms.isEmpty) {
      currentPerms.addAll(['dashboard', 'missions', 'users']);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: Color(0xFF1E293B)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Éditer Sous-Administrateur — ${sa.fullName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Nom et Prénom *'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(labelText: 'Email Administratif *'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // MOT DE PASSE (MODIFIABLE)
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mot de Passe d\'Accès Sécurisé (Modifiable) *',
                      prefixIcon: Icon(Icons.key, color: Color(0xFF1E293B), size: 18),
                      helperText: 'Définissez le nouveau mot de passe d\'accès pour ce gestionnaire.',
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pages & Modules Autorisés :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => setDialogState(() => currentPerms.addAll(availablePages.keys)),
                            child: const Text('Tout Cocher', style: TextStyle(fontSize: 11)),
                          ),
                          TextButton(
                            onPressed: () => setDialogState(() {
                              currentPerms.clear();
                              currentPerms.add('dashboard');
                            }),
                            child: const Text('Tout Décocher', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: availablePages.entries.map((entry) {
                      final isSelected = currentPerms.contains(entry.key);
                      return FilterChip(
                        label: Text(entry.value, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1E293B),
                        checkmarkColor: Colors.white,
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              currentPerms.add(entry.key);
                            } else if (entry.key != 'dashboard') {
                              currentPerms.remove(entry.key);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Statut du Compte (Actif / Autorisé à se connecter)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: isActive,
                    activeColor: AppConfig.successGreen,
                    onChanged: (v) => setDialogState(() => isActive = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez remplir le nom, l\'email et le mot de passe.')),
                  );
                  return;
                }

                Navigator.of(ctx).pop();
                setState(() => _isLoading = true);

                sa.fullName = nameCtrl.text.trim();
                sa.email = emailCtrl.text.trim().toLowerCase();
                sa.permissions = currentPerms.toList();
                sa.isActive = isActive;
                sa.password = passCtrl.text.trim();

                await _supabase.updateSousAdmin(sa, password: passCtrl.text.trim());
                _loadSousAdmins();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Informations, mot de passe et permissions du sous-administrateur mis à jour !'),
                    backgroundColor: AppConfig.successGreen,
                  ),
                );
              },
              child: const Text('Enregistrer les Modifications'),
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
                                    icon: const Icon(Icons.badge_outlined, color: Color(0xFF1E293B)),
                                    tooltip: 'Aperçu Identité & Fiche Complète',
                                    onPressed: () => _showSousAdminDetailsDialog(sa),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppConfig.brandPink, size: 20),
                                    tooltip: 'Modifier Informations & Mot de passe',
                                    onPressed: () => _showEditSousAdminDialog(sa),
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
