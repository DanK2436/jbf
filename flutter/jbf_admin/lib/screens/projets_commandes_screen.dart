import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ProjetsCommandesScreen extends StatefulWidget {
  const ProjetsCommandesScreen({super.key});

  @override
  State<ProjetsCommandesScreen> createState() => _ProjetsCommandesScreenState();
}

class _ProjetsCommandesScreenState extends State<ProjetsCommandesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _missions = [];
  Map<String, dynamic>? _selectedProjectForWBS;
  List<Map<String, dynamic>> _projectSteps = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);
    try {
      final url = '${AppConfig.supabaseUrl}/rest/v1/missions?select=*&order=created_at.desc';
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (mounted) {
          setState(() {
            _missions = list.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Erreur chargement missions: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadProjectSteps(String missionId) async {
    try {
      final url = '${AppConfig.apiBaseUrl}/missions/$missionId/etapes';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _projectSteps = (data['etapes'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (_) {
      // Fallback Supabase
      final sbUrl = '${AppConfig.supabaseUrl}/rest/v1/mission_etapes?mission_id=eq.$missionId&order=ordre_etape.asc';
      final res = await http.get(
        Uri.parse(sbUrl),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (mounted) {
          setState(() {
            _projectSteps = list.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    }
  }

  void _showAddStepDialog(String missionId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: (_projectSteps.length + 1).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_task, color: AppConfig.brandPink),
            SizedBox(width: 8),
            Text('Ajouter une Tâche / Jalon (WBS)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre de la tâche / Jalon *', hintText: 'ex: Coulage fondations BTP'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description des livrables et critères de validation'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: orderCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ordre chronologique'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              Navigator.of(ctx).pop();

              try {
                final url = '${AppConfig.apiBaseUrl}/admin/missions/$missionId/etapes';
                await http.post(
                  Uri.parse(url),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'titre_etape': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'ordre_etape': int.tryParse(orderCtrl.text) ?? 1,
                  }),
                );
                _loadProjectSteps(missionId);
              } catch (_) {}
            },
            child: const Text('Ajouter au WBS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        'Commandes & Projets Complexes',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText),
                      ),
                      Text(
                        'Vue chronologique des commandes & Décomposition WBS pour chantiers BTP, Mines et Maintenance',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppConfig.brandPink,
                  labelColor: AppConfig.brandPink,
                  unselectedLabelColor: Colors.grey.shade600,
                  tabs: const [
                    Tab(icon: Icon(Icons.timeline), text: 'Vue Chronologique des Commandes'),
                    Tab(icon: Icon(Icons.account_tree_outlined), text: 'Module Projets Complexes (WBS)'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Vue Chronologique
                _buildTimelineTab(),

                // TAB 2: Projets Complexes WBS & Budget
                _buildWbsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    if (_missions.isEmpty) {
      return const Center(child: Text('Aucune commande ou mission enregistrée.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _missions.length,
      itemBuilder: (context, index) {
        final m = _missions[index];
        final titre = m['titre'] ?? 'Commande sans titre';
        final client = m['client_nom'] ?? m['client'] ?? m['societe'] ?? 'Client Partenaire';
        final date = m['created_at'] != null ? DateTime.parse(m['created_at']) : DateTime.now();
        final statut = (m['statut'] ?? 'en_cours').toString();
        final pct = m['progression_pct'] ?? 0;
        final paiement = m['statut_paiement_client'] ?? 'en_attente';
        final site = m['site_intervention'] ?? m['site_lieu'] ?? 'RDC';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chronological Pin & Date
              Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: statut == 'terminee'
                          ? AppConfig.successGreen
                          : (statut == 'en_cours' ? AppConfig.brandPink : Colors.orange),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppConfig.brandPink.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                  if (index < _missions.length - 1)
                    Container(
                      width: 2,
                      height: 80,
                      color: Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Card details
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              titre,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: paiement == 'paye_integralement'
                                  ? const Color(0xFFDCFCE7)
                                  : (paiement == 'acompte_regle' ? Colors.blue.shade50 : const Color(0xFFFEF3C7)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              paiement == 'paye_integralement'
                                  ? 'Paiement Soldé'
                                  : (paiement == 'acompte_regle' ? 'Acompte Réglé' : 'Paiement En Attente'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: paiement == 'paye_integralement'
                                    ? AppConfig.successGreen
                                    : (paiement == 'acompte_regle' ? Colors.blue.shade800 : Colors.amber.shade900),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Client : $client • Site : $site • Initiée le : ${date.day}/${date.month}/${date.year}'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (pct as int) / 100.0,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                color: AppConfig.brandPink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('$pct% réalisé', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWbsTab() {
    return Row(
      children: [
        // Sidebar projects list
        SizedBox(
          width: 340,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Sélectionnez un Projet BTP / Maintenance',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _missions.length,
                    itemBuilder: (context, i) {
                      final m = _missions[i];
                      final isSelected = _selectedProjectForWBS?['id'] == m['id'];

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: AppConfig.brandPinkTint,
                        title: Text(
                          m['titre'] ?? 'Projet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                        ),
                        subtitle: Text(m['site_intervention'] ?? 'RDC'),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () {
                          setState(() => _selectedProjectForWBS = m);
                          _loadProjectSteps(m['id']);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Main WBS & Budget View
        Expanded(
          child: _selectedProjectForWBS == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_tree_outlined, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Sélectionnez un projet à gauche pour gérer sa décomposition WBS et son budget.'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Budget & Metrics Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedProjectForWBS!['titre'] ?? 'Projet',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddStepDialog(_selectedProjectForWBS!['id']),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Ajouter une Tâche WBS'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                _buildBudgetMetric('Budget Alloué', '45 000 USD', Colors.blue.shade800),
                                const SizedBox(width: 20),
                                _buildBudgetMetric('Dépenses Engagées', '18 200 USD', Colors.orange.shade800),
                                const SizedBox(width: 20),
                                _buildBudgetMetric('Marge Prévisionnelle', '26 800 USD (+59%)', AppConfig.successGreen),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // WBS Tasks List
                      const Text(
                        'Décomposition des Tâches & Validation Tripartite',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      if (_projectSteps.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text('Aucune tâche WBS définie pour ce projet. Cliquez sur "Ajouter une Tâche WBS".'),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _projectSteps.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final step = _projectSteps[i];
                            final doneMembre = step['est_acheve_par_membre'] == true;
                            final approvedAdmin = step['est_approuve_par_admin'] == true;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: approvedAdmin
                                        ? AppConfig.successGreen
                                        : (doneMembre ? Colors.orange : Colors.grey.shade300),
                                    child: Icon(
                                      approvedAdmin ? Icons.check : (doneMembre ? Icons.hourglass_top : Icons.circle),
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          step['titre_etape'] ?? 'Tâche ${i + 1}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        if (step['description'] != null)
                                          Text(
                                            step['description'],
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (!approvedAdmin && doneMembre)
                                    ElevatedButton(
                                      onPressed: () async {
                                        final url = '${AppConfig.apiBaseUrl}/admin/missions/${_selectedProjectForWBS!['id']}/etapes/${step['id']}/approuver';
                                        await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: jsonEncode({}));
                                        _loadProjectSteps(_selectedProjectForWBS!['id']);
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: AppConfig.successGreen),
                                      child: const Text('Approuver Livrable'),
                                    )
                                  else if (approvedAdmin)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '✓ Validé & Transmis Client',
                                        style: TextStyle(color: AppConfig.successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBudgetMetric(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
