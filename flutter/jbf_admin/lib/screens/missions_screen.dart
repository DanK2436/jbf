import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/admin_models.dart';
import '../services/supabase_service.dart';
import '../widgets/stat_badge.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<MissionItem> _missions = [];
  String _selectedStatut = 'toutes';

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);
    final list = await _supabase.fetchMissions();
    if (!mounted) return;
    setState(() {
      _missions = list;
      _isLoading = false;
    });
  }

  List<MissionItem> get _filteredMissions {
    if (_selectedStatut == 'toutes') return _missions;
    return _missions.where((m) => m.statut == _selectedStatut).toList();
  }

  void _showAddMissionDialog() {
    final titreCtrl = TextEditingController();
    final clientCtrl = TextEditingController();
    final siteCtrl = TextEditingController(text: 'Kolwezi / Haut-Katanga');
    final serviceCtrl = TextEditingController(text: 'Sous-traitance Minière');
    final respCtrl = TextEditingController();
    final budgetCtrl = TextEditingController(text: '45000');
    final effectifCtrl = TextEditingController(text: '10');
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Créer un Nouvel Ordre de Mission (Supabase BDD)'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Intitulé de la Mission', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: titreCtrl,
                  decoration: const InputDecoration(hintText: 'ex: Maintenance Arrêt Usine Lixiviation'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Entreprise Cliente', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(controller: clientCtrl, decoration: const InputDecoration(hintText: 'ex: TFM Mining')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Site d\'Intervention', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(controller: siteCtrl),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pôle Métier JBF', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(controller: serviceCtrl),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Responsable / Chef d\'Équipe', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(controller: respCtrl, decoration: const InputDecoration(hintText: 'ex: Ir. Jean-Pierre Mulamba')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Budget Alloué (USD)', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(controller: budgetCtrl, keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Effectif Mobilisé', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(controller: effectifCtrl, keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Cahier des charges & Consignes de sécurité HSE', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Spécifications techniques, EPI obligatoires...'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (titreCtrl.text.isEmpty || clientCtrl.text.isEmpty) return;
              Navigator.of(ctx).pop();

              final newMission = MissionItem(
                id: '',
                titre: titreCtrl.text,
                client: clientCtrl.text,
                siteIntervention: siteCtrl.text,
                serviceNom: serviceCtrl.text,
                dateDebut: DateTime.now(),
                dateFin: DateTime.now().add(const Duration(days: 30)),
                assignedTo: respCtrl.text,
                budgetUsd: double.tryParse(budgetCtrl.text) ?? 0.0,
                effectif: int.tryParse(effectifCtrl.text) ?? 1,
                description: descCtrl.text,
                statut: 'en_cours',
              );

              await _supabase.createMission(newMission);
              _loadMissions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nouvel ordre de mission enregistré dans la base de données Supabase')),
              );
            },
            child: const Text('Enregistrer dans Supabase'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    final missions = _filteredMissions;

    return RefreshIndicator(
      onRefresh: _loadMissions,
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
                    const Text('Planification & Missions de Terrain (BDD)',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Données réelles extraites de la table missions Supabase',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                      tooltip: 'Actualiser',
                      onPressed: _loadMissions,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nouvelle Mission'),
                      onPressed: _showAddMissionDialog,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'toutes', label: Text('Toutes')),
                ButtonSegment(value: 'en_cours', label: Text('En cours')),
                ButtonSegment(value: 'planifiee', label: Text('Planifiées')),
                ButtonSegment(value: 'terminee', label: Text('Terminées')),
              ],
              selected: {_selectedStatut},
              onSelectionChanged: (val) => setState(() => _selectedStatut = val.first),
            ),
            const SizedBox(height: 18),

            Expanded(
              child: missions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('Aucune mission dans la base de données.', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Créer la première mission'),
                            onPressed: _showAddMissionDialog,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: missions.length,
                      itemBuilder: (context, index) {
                        final m = missions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppConfig.brandPinkTint,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.engineering, color: AppConfig.brandPink, size: 28),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(m.titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(width: 10),
                                              StatBadge(label: m.statut.toUpperCase(), status: m.statut),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Client : ${m.client} • Site : ${m.siteIntervention} • Domaine : ${m.serviceNom}',
                                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                          const SizedBox(height: 4),
                                          Text('Superviseur : ${m.assignedTo} • Effectif : ${m.effectif} agents',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('\$${m.budgetUsd.toStringAsFixed(0)} USD',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.successGreen)),
                                        const SizedBox(height: 6),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert),
                                          onSelected: (val) async {
                                            await _supabase.updateMissionStatut(m.id, val);
                                            _loadMissions();
                                          },
                                          itemBuilder: (ctx) => const [
                                            PopupMenuItem(value: 'en_cours', child: Text('Passer En cours')),
                                            PopupMenuItem(value: 'terminee', child: Text('Marquer Terminée')),
                                            PopupMenuItem(value: 'suspendue', child: Text('Suspendre')),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (m.description.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text('Objectifs : ${m.description}', style: TextStyle(color: Colors.grey.shade800, fontSize: 12)),
                                ],
                                if (m.rapport.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFBBF7D0)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.assignment_turned_in, color: AppConfig.successGreen, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Dernier Rapport Terrain : ${m.rapport}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
