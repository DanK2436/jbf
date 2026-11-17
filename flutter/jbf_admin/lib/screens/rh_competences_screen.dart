import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class RhCompetencesScreen extends StatefulWidget {
  const RhCompetencesScreen({super.key});

  @override
  State<RhCompetencesScreen> createState() => _RhCompetencesScreenState();
}

class _RhCompetencesScreenState extends State<RhCompetencesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _collaborateurs = [];
  String _selectedSkillFilter = 'Toutes';

  final List<String> _skillsList = [
    'Toutes',
    'Soudure TIG/MIG',
    'Tuyauterie Industrielle',
    'Génie Civil & BTP',
    'Topographie & Arpentage',
    'Conduite d\'Engins Lourds',
    'Cuisine Industrielle & HACCP',
    'Électricité Haute Tension',
    'Mécanique d\'Engins Miniers',
    'Sécurité QHSE & ISO 45001',
    'Forage Hydraulique',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRhData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRhData() async {
    setState(() => _isLoading = true);
    try {
      final url = '${AppConfig.supabaseUrl}/rest/v1/profiles?role=neq.client&select=*&order=created_at.desc';
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (mounted) {
          setState(() {
            _collaborateurs = list.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement RH: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddEditCollaborateurDialog([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?['full_name'] ?? item?['nom_complet'] ?? '');
    final emailCtrl = TextEditingController(text: item?['email'] ?? '');
    final matCtrl = TextEditingController(text: item?['matricule'] ?? 'JBF-M-2026-00${_collaborateurs.length + 1}');
    final posteCtrl = TextEditingController(text: item?['poste'] ?? 'Technicien');
    final departCtrl = TextEditingController(text: item?['section_nom'] ?? 'Mines & Industrie');
    final provinceCtrl = TextEditingController(text: item?['province'] ?? 'Haut-Katanga');
    final contratCtrl = TextEditingController(text: item?['type_contrat'] ?? 'CDI');
    final salaireCtrl = TextEditingController(text: item?['salaire_base']?.toString() ?? '850');
    final competencesCtrl = TextEditingController(
      text: (item?['competences'] as List?)?.join(', ') ?? 'Sécurité QHSE, Soudure',
    );
    String dispo = item?['statut_disponibilite'] ?? 'disponible';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text(isEdit ? 'Modifier Fiche Salarié' : 'Nouveau Dossier Collaborateur RH'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom & Post-nom du Collaborateur *')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Adresse Email Professionnelle *'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: matCtrl, decoration: const InputDecoration(labelText: 'Matricule RH *'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: posteCtrl, decoration: const InputDecoration(labelText: 'Poste / Qualification'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: departCtrl, decoration: const InputDecoration(labelText: 'Département / Pôle'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: contratCtrl, decoration: const InputDecoration(labelText: 'Type de Contrat (CDI, CDD...)'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: salaireCtrl, decoration: const InputDecoration(labelText: 'Salaire Base (USD)'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: provinceCtrl, decoration: const InputDecoration(labelText: 'Province d\'affectation')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: competencesCtrl,
                    decoration: const InputDecoration(labelText: 'Compétences Spécifiques (séparées par virgule)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: dispo,
                    decoration: const InputDecoration(labelText: 'Statut Disponibilité'),
                    items: const [
                      DropdownMenuItem(value: 'disponible', child: Text('DISPONIBLE (Affectable)')),
                      DropdownMenuItem(value: 'en_mission', child: Text('EN MISSION')),
                      DropdownMenuItem(value: 'en_conge', child: Text('EN CONGÉ')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDlgState(() => dispo = v);
                    },
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
                final skillsArray = competencesCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                final body = {
                  'full_name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'matricule': matCtrl.text.trim(),
                  'poste': posteCtrl.text.trim(),
                  'section_nom': departCtrl.text.trim(),
                  'province': provinceCtrl.text.trim(),
                  'type_contrat': contratCtrl.text.trim(),
                  'salaire_base': num.tryParse(salaireCtrl.text.trim()) ?? 0,
                  'competences': skillsArray,
                  'statut_disponibilite': dispo,
                  'role': 'membre',
                };

                try {
                  if (isEdit && item['id'] != null) {
                    await http.patch(
                      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?id=eq.${item['id']}'),
                      headers: {
                        'apikey': AppConfig.supabaseAnonKey,
                        'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode(body),
                    );
                  } else {
                    await http.post(
                      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles'),
                      headers: {
                        'apikey': AppConfig.supabaseAnonKey,
                        'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode(body),
                    );
                  }
                } catch (_) {}

                if (!mounted) return;
                Navigator.of(ctx).pop();
                _loadRhData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Fiche collaborateur mise à jour.' : 'Collaborateur RH enregistré.'),
                    backgroundColor: AppConfig.successGreen,
                  ),
                );
              },
              child: Text(isEdit ? 'Sauvegarder' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredBySkill() {
    if (_selectedSkillFilter == 'Toutes') return _collaborateurs;
    return _collaborateurs.where((c) {
      final skills = (c['competences'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
      final poste = (c['poste'] ?? '').toString().toLowerCase();
      final target = _selectedSkillFilter.toLowerCase();
      return skills.any((s) => s.contains(target)) || poste.contains(target);
    }).toList();
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
                        'Ressources Humaines & Cartographie des Compétences',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText),
                      ),
                      Text(
                        'Données réelles : Gestion des contrats, salaires, qualifications et matching sur missions',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditCollaborateurDialog(),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Nouveau Collaborateur'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
                ),
                const SizedBox(width: 12),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppConfig.brandPink,
                  labelColor: AppConfig.brandPink,
                  unselectedLabelColor: Colors.grey.shade600,
                  tabs: const [
                    Tab(icon: Icon(Icons.people), text: 'Dossiers Salariés & Contrats'),
                    Tab(icon: Icon(Icons.radar), text: 'Cartographie des Compétences & Matching'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Dossiers Collaborateurs
                _buildCollaborateursTab(),

                // TAB 2: Cartographie & Matching
                _buildCompetencesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborateursTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    if (_collaborateurs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            const Text('Aucun collaborateur enregistré dans la base de données.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Ajoutez un premier profil collaborateur ou synchronisez avec Supabase.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _showAddEditCollaborateurDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un Collaborateur'),
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _collaborateurs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = _collaborateurs[index];
        final name = c['full_name'] ?? c['nom_complet'] ?? c['email'] ?? 'Collaborateur JBF';
        final matricule = c['matricule'] ?? 'JBF-M-${index + 1}';
        final poste = c['poste'] ?? 'Technicien';
        final contrat = c['type_contrat'] ?? 'CDI';
        final dispo = c['statut_disponibilite'] ?? 'disponible';
        final province = c['province'] ?? 'Haut-Katanga';
        final salaire = c['salaire_base'] != null ? '${c['salaire_base']} ${c['devise_salaire'] ?? 'USD'}' : 'Non renseigné';

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppConfig.brandPinkTint,
                child: const Icon(Icons.person, color: AppConfig.brandPink),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                          child: Text(matricule, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: dispo == 'disponible' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            dispo.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: dispo == 'disponible' ? AppConfig.successGreen : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Poste : $poste • Contrat : $contrat • Salaire : $salaire • Affectation : $province', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditCollaborateurDialog(c),
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Fiche Salarié'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.brandPink,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompetencesTab() {
    final filtered = _getFilteredBySkill();

    return Column(
      children: [
        // Skill Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          color: Colors.white,
          child: Row(
            children: [
              const Text('Sélectionner une Compétence Requise : ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _skillsList.map((skill) {
                      final isSelected = _selectedSkillFilter == skill;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(skill),
                          selected: isSelected,
                          selectedColor: AppConfig.brandPink,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _selectedSkillFilter = skill),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Matching Results
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'Aucun collaborateur ne correspond à la compétence "$_selectedSkillFilter".',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = filtered[i];
                    final name = c['full_name'] ?? c['nom_complet'] ?? 'Agent';
                    final poste = c['poste'] ?? 'Technicien';
                    final skills = (c['competences'] as List?)?.map((e) => e.toString()).toList() ?? ['Polyvalent terrain'];

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text('Corps de métier : $poste', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: skills.map((s) => Chip(
                                    label: Text(s, style: const TextStyle(fontSize: 11)),
                                    backgroundColor: Colors.blue.shade50,
                                    padding: EdgeInsets.zero,
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Affectation de $name préparée.')),
                              );
                            },
                            icon: const Icon(Icons.assignment_ind, size: 16),
                            label: const Text('Affecter à une Mission'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.successGreen),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
