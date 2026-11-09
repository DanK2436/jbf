import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/membre_models.dart';
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
  List<MembreMission> _missions = [];

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

  void _showReportDialog(MembreMission m) {
    final reportCtrl = TextEditingController(text: m.rapport);
    String statut = m.statut;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Rapport d\'Intervention Terrain (BDD) — ${m.titre}'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Client : ${m.client} • Site : ${m.siteIntervention}'),
                  const SizedBox(height: 12),
                  const Text('Statut de la mission', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: statut,
                    items: const [
                      DropdownMenuItem(value: 'en_cours', child: Text('En cours d\'exécution')),
                      DropdownMenuItem(value: 'terminee', child: Text('Terminée avec succès')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => statut = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Observations, Avancement & Compte-Rendu', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reportCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Détaillez les travaux exécutés, épreuves d\'étanchéité, pièces installées...',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _supabase.updateMissionRapport(m.id, reportCtrl.text, statut);
                _loadMissions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rapport transmis et enregistré dans la base de données Supabase')),
                );
              },
              child: const Text('Transmettre dans Supabase'),
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
                    const Text('Mes Ordres de Mission & Chantiers (BDD)',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Données réelles de la table missions Supabase',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                  tooltip: 'Actualiser',
                  onPressed: _loadMissions,
                ),
              ],
            ),
            const SizedBox(height: 18),

            Expanded(
              child: _missions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('Aucune mission trouvée dans la base de données.', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualiser'),
                            onPressed: _loadMissions,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _missions.length,
                      itemBuilder: (context, index) {
                        final m = _missions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppConfig.brandPinkTint,
                                      child: const Icon(Icons.assignment, color: AppConfig.brandPink),
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
                                          Text('Date début : ${m.dateDebut.day}/${m.dateDebut.month}/${m.dateDebut.year} • Équipe : ${m.effectif} agent(s)',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.edit_note, size: 16),
                                      label: const Text('Rapport Terrain'),
                                      onPressed: () => _showReportDialog(m),
                                    ),
                                  ],
                                ),
                                if (m.description.isNotEmpty) ...[
                                  const Divider(height: 20),
                                  Text(
                                    'Cahier des charges :',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(m.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade900)),
                                ],
                                if (m.rapport.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFBBF7D0)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.check_circle, color: AppConfig.successGreen, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Dernier Rapport Transmis : ${m.rapport}',
                                            style: const TextStyle(color: Color(0xFF166534), fontSize: 12),
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
