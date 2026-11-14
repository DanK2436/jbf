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
      final url = '${AppConfig.apiBaseUrl}/admin/rh/collaborateurs';
      final fallbackUrl = '${AppConfig.supabaseUrl}/rest/v1/profiles?role=eq.membre&select=*';

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
        final list = (data is Map && data['collaborateurs'] != null)
            ? (data['collaborateurs'] as List)
            : (data is List ? data : []);

        if (mounted) {
          setState(() {
            _collaborateurs = list.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Erreur chargement RH: $e');
    }

    if (mounted) setState(() => _isLoading = false);
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
                        'Gestion des contrats, salaires, formations et matching intelligent pour affectation sur missions',
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
                    Tab(icon: Icon(Icons.people), text: 'Dossiers Collaborateurs & Salaires'),
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

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _collaborateurs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = _collaborateurs[index];
        final name = c['full_name'] ?? c['nom_complet'] ?? 'Collaborateur JBF';
        final matricule = c['matricule'] ?? 'JBF-M-2026-000';
        final poste = c['poste'] ?? 'Technicien Spécialisé';
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
                    Text('Poste : $poste • Contrat : $contrat • Salaire : $salaire • Affectation : $province'),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
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
          child: ListView.separated(
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
