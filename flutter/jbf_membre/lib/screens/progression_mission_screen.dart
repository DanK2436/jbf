import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/membre_models.dart';

class ProgressionMissionScreen extends StatefulWidget {
  final MembreUser user;

  const ProgressionMissionScreen({super.key, required this.user});

  @override
  State<ProgressionMissionScreen> createState() => _ProgressionMissionScreenState();
}

class _ProgressionMissionScreenState extends State<ProgressionMissionScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _missions = [];
  Map<String, dynamic>? _selectedMission;
  List<Map<String, dynamic>> _etapes = [];

  @override
  void initState() {
    super.initState();
    _loadMissions();
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
            if (_missions.isNotEmpty) {
              _selectedMission = _missions.first;
              _loadEtapes(_selectedMission!['id']);
            }
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadEtapes(String missionId) async {
    try {
      final url = '${AppConfig.supabaseUrl}/rest/v1/mission_etapes?mission_id=eq.$missionId&order=ordre_etape.asc';
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (mounted) {
          setState(() {
            _etapes = list.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (_) {}
  }

  void _showValiderEtapeDialog(Map<String, dynamic> etape) {
    final notesCtrl = TextEditingController();
    final photoCtrl = TextEditingController(text: 'PV_Reception_Chantier_Kolwezi.jpg');
    final gpsCtrl = TextEditingController(text: '-10.7183, 25.4729 (Kolwezi Katanga)');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppConfig.successGreen),
            const SizedBox(width: 8),
            Text('Valider l\'Étape : ${etape['titre_etape']}'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'La validation de cette étape transmettra immédiatement vos preuves (photos, GPS, PV) à l\'Administration JBF pour contrôle et publication au client.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Observations techniques & Rapport de fin d\'étape *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: photoCtrl,
                decoration: const InputDecoration(labelText: 'Preuve Photo / Document attaché'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gpsCtrl,
                decoration: const InputDecoration(labelText: 'Coordonnées GPS Chantier'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.successGreen),
            onPressed: () async {
              if (notesCtrl.text.isEmpty) return;
              Navigator.of(ctx).pop();

              try {
                final etapeId = etape['id'];
                final url = '${AppConfig.apiBaseUrl}/membre/missions/${_selectedMission!['id']}/etapes/$etapeId/valider';
                await http.put(
                  Uri.parse(url),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'membre_id': widget.user.id,
                    'observations_membre': notesCtrl.text.trim(),
                    'preuves_photos': [photoCtrl.text.trim()],
                    'coordonnees_gps': gpsCtrl.text.trim(),
                  }),
                );

                _loadEtapes(_selectedMission!['id']);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Étape validée et transmise à la Direction JBF pour approbation !'),
                    backgroundColor: AppConfig.successGreen,
                  ),
                );
              } catch (_) {}
            },
            child: const Text('Valider & Transmettre à l\'Admin'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: Row(
        children: [
          // Sidebar missions
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
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Mes Missions de Terrain',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
                        : ListView.builder(
                            itemCount: _missions.length,
                            itemBuilder: (context, i) {
                              final m = _missions[i];
                              final isSelected = _selectedMission?['id'] == m['id'];

                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: AppConfig.brandPinkTint,
                                leading: Icon(
                                  Icons.engineering,
                                  color: isSelected ? AppConfig.brandPink : Colors.grey.shade600,
                                ),
                                title: Text(
                                  m['titre'] ?? 'Mission',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                ),
                                subtitle: Text('${m['site_intervention']} • ${m['progression_pct'] ?? 0}%'),
                                onTap: () {
                                  setState(() => _selectedMission = m);
                                  _loadEtapes(m['id']);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Main Step Validation View
          Expanded(
            child: _selectedMission == null
                ? const Center(child: Text('Sélectionnez une mission à gauche.'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mission Header Card
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
                              Text(
                                _selectedMission!['titre'] ?? 'Mission',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text('Client : ${_selectedMission!['client'] ?? 'Client'} • Site : ${_selectedMission!['site_intervention'] ?? 'RDC'}'),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: ((_selectedMission!['progression_pct'] ?? 0) as int) / 100.0,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey.shade200,
                                        color: AppConfig.brandPink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    '${_selectedMission!['progression_pct'] ?? 0}% global',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text('Étapes de la Mission & Validation Terrain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),

                        if (_etapes.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: const Center(
                              child: Text('Aucun jalon spécifique n\'a été décomposé pour cette mission par l\'Admin.'),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _etapes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final etp = _etapes[i];
                              final doneMembre = etp['est_acheve_par_membre'] == true;
                              final approvedAdmin = etp['est_approuve_par_admin'] == true;

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: approvedAdmin ? const Color(0xFFBBF7D0) : (doneMembre ? const Color(0xFFFED7AA) : Colors.grey.shade200),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: approvedAdmin
                                          ? AppConfig.successGreen
                                          : (doneMembre ? Colors.orange : Colors.grey.shade300),
                                      child: Icon(
                                        approvedAdmin ? Icons.check : (doneMembre ? Icons.hourglass_top : Icons.circle),
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            etp['titre_etape'] ?? 'Étape ${i + 1}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          if (etp['description'] != null)
                                            Text(etp['description'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    ),
                                    if (!doneMembre)
                                      ElevatedButton.icon(
                                        onPressed: () => _showValiderEtapeDialog(etp),
                                        icon: const Icon(Icons.task_alt, size: 16),
                                        label: const Text('Valider l\'Étape'),
                                        style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
                                      )
                                    else if (!approvedAdmin)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                                        child: const Text('En attente revue Admin', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                                        child: const Text('✓ Validée & Visible Client', style: TextStyle(color: AppConfig.successGreen, fontWeight: FontWeight.bold, fontSize: 11)),
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
      ),
    );
  }
}
