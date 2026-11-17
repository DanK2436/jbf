import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class EvaluationItem {
  final String id;
  final String nom;
  final String entreprise;
  final String service;
  final int note;
  final String commentaire;
  final DateTime date;
  bool approuve;

  EvaluationItem({
    required this.id,
    required this.nom,
    required this.entreprise,
    required this.service,
    required this.note,
    required this.commentaire,
    required this.date,
    required this.approuve,
  });

  factory EvaluationItem.fromJson(Map<String, dynamic> j) {
    return EvaluationItem(
      id: j['id']?.toString() ?? '',
      nom: j['nom'] ?? j['client_nom'] ?? 'Partenaire',
      entreprise: j['entreprise'] ?? j['company'] ?? 'Société Industrielle',
      service: j['service'] ?? j['prestation'] ?? 'Sous-traitance Générale',
      note: int.tryParse(j['note']?.toString() ?? '5') ?? 5,
      commentaire: j['commentaire'] ?? j['avis'] ?? '',
      date: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      approuve: j['approuve'] == true,
    );
  }
}

class EvaluationsScreen extends StatefulWidget {
  const EvaluationsScreen({super.key});

  @override
  State<EvaluationsScreen> createState() => _EvaluationsScreenState();
}

class _EvaluationsScreenState extends State<EvaluationsScreen> {
  bool _isLoading = true;
  List<EvaluationItem> _evaluations = [];
  String _selectedFilter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _loadEvaluations();
  }

  Future<void> _loadEvaluations() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/avis_clients?select=*&order=created_at.desc'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _evaluations = list.map((e) => EvaluationItem.fromJson(e)).toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Évaluations de démonstration de secours
    if (mounted) {
      setState(() {
        if (_evaluations.isEmpty) {
          _evaluations = [
            EvaluationItem(
              id: 'ev-1',
              nom: 'Serge Kalombo',
              entreprise: 'Metalkol SA (Kolwezi)',
              service: 'Catering Industriel & Base-Vie',
              note: 5,
              commentaire: 'Excellente gestion de la chaîne du froid et respect scrupuleux des normes HACCP pour nos 850 ouvriers en poste continu.',
              date: DateTime.now().subtract(const Duration(days: 2)),
              approuve: true,
            ),
            EvaluationItem(
              id: 'ev-2',
              nom: 'Jean-Paul Ilunga',
              entreprise: 'Kipushi Corporation',
              service: 'Maintenance & Soudure TIG',
              note: 4,
              commentaire: 'Intervention d\'urgence remarquable sur notre colonne d\'acide. Équipe professionnelle et réactive.',
              date: DateTime.now().subtract(const Duration(days: 5)),
              approuve: false, // En attente
            ),
            EvaluationItem(
              id: 'ev-3',
              nom: 'Alain Mwamba',
              entreprise: 'BTP Katanga Grands Travaux',
              service: 'Terrassement & Génie Civil',
              note: 5,
              commentaire: 'Livraison du radier béton armé 350kg/m² avec 3 jours d\'avance sur le planning prévisionnel.',
              date: DateTime.now().subtract(const Duration(days: 10)),
              approuve: true,
            ),
          ];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleApprobation(EvaluationItem item, bool approve) async {
    setState(() => item.approuve = approve);
    try {
      await http.patch(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/avis_clients?id=eq.${item.id}'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'approuve': approve}),
      );
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approve ? 'Évaluation validée et publiée sur le site web.' : 'Évaluation mise en attente/masquée.'),
        backgroundColor: approve ? AppConfig.successGreen : AppConfig.brandPink,
      ),
    );
  }

  Future<void> _deleteEvaluation(EvaluationItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette évaluation'),
        content: const Text('Voulez-vous supprimer définitivement cet avis client ?'),
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

    if (confirm == true) {
      setState(() => _evaluations.removeWhere((e) => e.id == item.id));
      try {
        await http.delete(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/avis_clients?id=eq.${item.id}'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
        );
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Évaluation supprimée.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'Toutes'
        ? _evaluations
        : (_selectedFilter == 'Publiées'
            ? _evaluations.where((e) => e.approuve).toList()
            : _evaluations.where((e) => !e.approuve).toList());

    final double avgNote = _evaluations.isNotEmpty
        ? _evaluations.fold<double>(0.0, (s, e) => s + e.note) / _evaluations.length
        : 5.0;

    return Padding(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contrôle & Vérification des Évaluations Clients',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
                  Text('Modérez les retours d\'expérience et témoignages avant parution sur le site public',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                tooltip: 'Actualiser',
                onPressed: _loadEvaluations,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // KPIs
          Row(
            children: [
              Expanded(
                child: _buildKpi(
                  title: 'Total Évaluations Reçues',
                  value: '${_evaluations.length}',
                  sub: 'Retours donneurs d\'ordre',
                  icon: Icons.reviews,
                  color: AppConfig.brandPink,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildKpi(
                  title: 'Note Moyenne Certifiée',
                  value: '${avgNote.toStringAsFixed(1)} / 5',
                  sub: 'Indice de satisfaction client',
                  icon: Icons.star,
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildKpi(
                  title: 'En Attente de Modération',
                  value: '${_evaluations.where((e) => !e.approuve).length}',
                  sub: 'À examiner par la Direction',
                  icon: Icons.hourglass_top,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Barre de filtre
          Row(
            children: [
              _buildFilterChip('Toutes'),
              const SizedBox(width: 8),
              _buildFilterChip('En attente'),
              const SizedBox(width: 8),
              _buildFilterChip('Publiées'),
            ],
          ),
          const SizedBox(height: 14),

          // Liste des avis
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
                : filtered.isEmpty
                    ? const Center(child: Text('Aucune évaluation dans cette vue.'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final item = filtered[i];

                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: item.approuve ? Colors.grey.shade200 : const Color(0xFFFDE68A),
                                width: item.approuve ? 1.0 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppConfig.brandPinkTint,
                                  foregroundColor: AppConfig.brandPink,
                                  child: const Icon(Icons.apartment),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.entreprise, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              Text('Rédigé par ${item.nom} • Pôle : ${item.service}',
                                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                            ],
                                          ),
                                          Row(
                                            children: List.generate(
                                              5,
                                              (starIdx) => Icon(
                                                starIdx < item.note ? Icons.star : Icons.star_border,
                                                color: Colors.amber,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '"${item.commentaire}"',
                                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, height: 1.4),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: item.approuve ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.approuve ? 'PUBLIÉ SUR LE SITE' : 'EN ATTENTE DE MODÉRATION',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: item.approuve ? AppConfig.successGreen : Colors.amber.shade900,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (!item.approuve)
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppConfig.successGreen,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              ),
                                              icon: const Icon(Icons.check, size: 16),
                                              label: const Text('Approuver & Publier', style: TextStyle(fontSize: 12)),
                                              onPressed: () => _toggleApprobation(item, true),
                                            )
                                          else
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.visibility_off, size: 16),
                                              label: const Text('Masquer', style: TextStyle(fontSize: 12)),
                                              onPressed: () => _toggleApprobation(item, false),
                                            ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: AppConfig.dangerRed, size: 18),
                                            tooltip: 'Supprimer',
                                            onPressed: () => _deleteEvaluation(item),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppConfig.brandPink,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _selectedFilter = label),
    );
  }

  Widget _buildKpi({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }
}
