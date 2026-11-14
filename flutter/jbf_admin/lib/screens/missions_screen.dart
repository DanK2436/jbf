import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  Future<void> _deleteMission(String id, String titre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la Mission'),
        content: Text('Voulez-vous supprimer définitivement la mission "$titre" ?'),
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
      final url = '${AppConfig.supabaseUrl}/rest/v1/missions?id=eq.$id';
      await http.delete(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      );
      _loadMissions();
    } catch (_) {}
  }

  Future<void> _toggleDisableMission(MissionItem m) async {
    try {
      final newStatus = m.statut == 'suspendue' ? 'en_cours' : 'suspendue';
      await _supabase.updateMissionStatut(m.id, newStatus);
      _loadMissions();
    } catch (_) {}
  }

  void _showEditMissionDialog(MissionItem m) {
    final titreCtrl = TextEditingController(text: m.titre);
    final clientCtrl = TextEditingController(text: m.client);
    final siteCtrl = TextEditingController(text: m.siteIntervention);
    final serviceCtrl = TextEditingController(text: m.serviceNom);
    final respCtrl = TextEditingController(text: m.assignedTo);
    final budgetCtrl = TextEditingController(text: m.budgetUsd.toStringAsFixed(0));
    final descCtrl = TextEditingController(text: m.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier la Mission'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titreCtrl, decoration: const InputDecoration(labelText: 'Titre de la Mission *')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: clientCtrl, decoration: const InputDecoration(labelText: 'Client'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: siteCtrl, decoration: const InputDecoration(labelText: 'Site Intervention'))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: serviceCtrl, decoration: const InputDecoration(labelText: 'Service'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: respCtrl, decoration: const InputDecoration(labelText: 'Superviseur JBF'))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: budgetCtrl, decoration: const InputDecoration(labelText: 'Budget (USD)')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Objectifs & Spécifications')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final url = '${AppConfig.supabaseUrl}/rest/v1/missions?id=eq.${m.id}';
                await http.patch(
                  Uri.parse(url),
                  headers: {
                    'apikey': AppConfig.supabaseAnonKey,
                    'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'titre': titreCtrl.text.trim(),
                    'client': clientCtrl.text.trim(),
                    'site_intervention': siteCtrl.text.trim(),
                    'service_nom': serviceCtrl.text.trim(),
                    'responsable_jbf': respCtrl.text.trim(),
                    'budget_usd': double.tryParse(budgetCtrl.text) ?? 0,
                    'description': descCtrl.text.trim(),
                    'updated_at': DateTime.now().toIso8601String(),
                  }),
                );
                _loadMissions();
              } catch (_) {}
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showAttachmentsDialog(MissionItem m) {
    final fileNameCtrl = TextEditingController();
    final fileContentCtrl = TextEditingController();
    String selectedExt = 'jbf';

    final List<Map<String, String>> missionFiles = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.attach_file, color: AppConfig.brandPink),
              const SizedBox(width: 8),
              Text('Fichiers Attachés — ${m.titre}'),
            ],
          ),
          content: SizedBox(
            width: 580,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Formats supportés : TXT, Word, PDF, MP3, MP4, DXF, DWG, STL, Excel et conteneur sécurisé .JBF',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                if (missionFiles.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Center(
                      child: Text(
                        'Aucun fichier attaché à cette mission pour l\'instant.\nUtilisez le formulaire ci-dessous pour générer ou joindre un document chiffré.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: missionFiles.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final f = missionFiles[i];
                        final isJbf = f['format'] == 'jbf';
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            isJbf ? Icons.security : Icons.insert_drive_file,
                            color: isJbf ? AppConfig.brandPink : Colors.blue.shade700,
                          ),
                          title: Text(f['nom']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(f['taille']!, style: const TextStyle(fontSize: 11)),
                          trailing: IconButton(
                            icon: const Icon(Icons.download, size: 18),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ouverture sécurisée de ${f['nom']}')),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                const Divider(height: 24),
                const Text('Créer et chiffrer un document .JBF pour les membres :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(controller: fileNameCtrl, decoration: const InputDecoration(labelText: 'Titre du fichier', hintText: 'ex: Instructions Sécurité')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedExt,
                        decoration: const InputDecoration(labelText: 'Format'),
                        items: const [
                          DropdownMenuItem(value: 'jbf', child: Text('.JBF (Sécurisé)')),
                          DropdownMenuItem(value: 'pdf', child: Text('.PDF')),
                          DropdownMenuItem(value: 'docx', child: Text('.DOCX')),
                          DropdownMenuItem(value: 'dwg', child: Text('.DWG')),
                        ],
                        onChanged: (v) => setDlgState(() => selectedExt = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: fileContentCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Contenu texte à encapsuler dans le conteneur .jbf'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fermer')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
              onPressed: () async {
                if (fileNameCtrl.text.isEmpty) return;
                try {
                  final url = '${AppConfig.apiBaseUrl}/fichiers/jbf-pack';
                  await http.post(
                    Uri.parse(url),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'titre': fileNameCtrl.text.trim(),
                      'typeOriginal': selectedExt,
                      'contenu': fileContentCtrl.text.trim(),
                      'missionCode': m.id,
                    }),
                  );
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document chiffré au format .jbf et lié à la mission avec succès !'), backgroundColor: AppConfig.successGreen),
                  );
                } catch (_) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Encapsuler & Envoyer aux Membres'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMissionDialog() {
    final titreCtrl = TextEditingController();
    final clientCtrl = TextEditingController();
    final siteCtrl = TextEditingController();
    final serviceCtrl = TextEditingController();
    final respCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    final effectifCtrl = TextEditingController();
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
                TextField(controller: titreCtrl, decoration: const InputDecoration(hintText: 'Intitulé de la mission *')),
                const SizedBox(height: 10),
                TextField(controller: clientCtrl, decoration: const InputDecoration(hintText: 'Nom du Client ou Société *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: siteCtrl, decoration: const InputDecoration(hintText: 'Site d\'intervention'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: serviceCtrl, decoration: const InputDecoration(hintText: 'Prestation'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: respCtrl, decoration: const InputDecoration(hintText: 'Superviseur JBF'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: effectifCtrl, decoration: const InputDecoration(hintText: 'Effectif'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: budgetCtrl, decoration: const InputDecoration(hintText: 'Budget prévisionnel (USD)')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Spécifications techniques, EPI obligatoires...')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
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
                const SnackBar(content: Text('Nouvel ordre de mission enregistré dans la base Supabase')),
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
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
                ButtonSegment(value: 'suspendue', label: Text('Suspendues / Désactivées')),
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
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: missions.length,
                      itemBuilder: (context, index) {
                        final m = missions[index];
                        final isSuspended = m.statut == 'suspendue';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isSuspended ? const Color(0xFFFCA5A5) : Colors.grey.shade200),
                          ),
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
                                        color: isSuspended ? Colors.grey.shade200 : AppConfig.brandPinkTint,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.engineering,
                                        color: isSuspended ? Colors.grey : AppConfig.brandPink,
                                        size: 28,
                                      ),
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
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.attach_file, color: Colors.blue),
                                              tooltip: 'Pièces jointes & format .JBF',
                                              onPressed: () => _showAttachmentsDialog(m),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                                              tooltip: 'Modifier',
                                              onPressed: () => _showEditMissionDialog(m),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                isSuspended ? Icons.play_arrow : Icons.pause,
                                                color: isSuspended ? AppConfig.successGreen : Colors.orange,
                                              ),
                                              tooltip: isSuspended ? 'Réactiver' : 'Désactiver / Suspendre',
                                              onPressed: () => _toggleDisableMission(m),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: AppConfig.dangerRed),
                                              tooltip: 'Supprimer',
                                              onPressed: () => _deleteMission(m.id, m.titre),
                                            ),
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
