import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/admin_models.dart';
import '../services/supabase_service.dart';
import '../widgets/stat_badge.dart';

class DevisScreen extends StatefulWidget {
  const DevisScreen({super.key});

  @override
  State<DevisScreen> createState() => _DevisScreenState();
}

class _DevisScreenState extends State<DevisScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<DevisItem> _devis = [];
  String _selectedFilter = 'tous';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDevis();
  }

  Future<void> _loadDevis() async {
    setState(() => _isLoading = true);
    final list = await _supabase.fetchDevis();
    if (!mounted) return;
    setState(() {
      _devis = list;
      _isLoading = false;
    });
  }

  List<DevisItem> get _filteredDevis {
    return _devis.where((d) {
      final matchesFilter = _selectedFilter == 'tous' || d.statut == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          d.societe.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.services.any((s) => s.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesFilter && matchesSearch;
    }).toList();
  }

  void _showChiffrageDialog(DevisItem item) {
    final montantCtrl = TextEditingController(text: item.montantUsd > 0 ? item.montantUsd.toStringAsFixed(0) : '');
    final chefCtrl = TextEditingController(text: item.chefEquipe);
    final effectifCtrl = TextEditingController(text: item.effectif > 0 ? item.effectif.toString() : '');
    String statut = item.statut;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Traitement & Chiffrage BDD — ${item.societe.isNotEmpty ? item.societe : item.nom}'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Prestations: ${item.services.join(", ")}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Localité: ${item.localite} • Contact: ${item.telephone}'),
                  const SizedBox(height: 12),
                  const Text('Statut du dossier', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: statut,
                    items: const [
                      DropdownMenuItem(value: 'nouveau', child: Text('Nouveau / En attente')),
                      DropdownMenuItem(value: 'en_cours', child: Text('En cours d\'étude')),
                      DropdownMenuItem(value: 'traite', child: Text('Traité & Validé')),
                      DropdownMenuItem(value: 'rejete', child: Text('Rejeté / Sans suite')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => statut = val);
                    },
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Montant Estimé (USD)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: montantCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: '\$ ',
                      hintText: 'ex: 45000',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Chef d\'Équipe Désigné', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: chefCtrl,
                    decoration: const InputDecoration(hintText: 'ex: Ir. Jean-Pierre Mulamba'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Effectif Prévisionnel (Agents)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: effectifCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'ex: 12'),
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
              onPressed: () async {
                final double m = double.tryParse(montantCtrl.text) ?? 0.0;
                final int eff = int.tryParse(effectifCtrl.text) ?? 0;
                Navigator.of(ctx).pop();

                await _supabase.updateDevisStatut(
                  item.id,
                  statut,
                  montant: m,
                  chef: chefCtrl.text,
                  effectif: eff,
                );
                _loadDevis();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Devis mis à jour dans la base de données Supabase')),
                );
              },
              child: const Text('Enregistrer dans Supabase'),
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

    final devis = _filteredDevis;

    return RefreshIndicator(
      onRefresh: _loadDevis,
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
                    const Text(
                      'Gestion des Demandes de Devis (Base de Données)',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text('Données réelles extraites de la table demandes_devis Supabase',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                  tooltip: 'Actualiser la base de données',
                  onPressed: _loadDevis,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Filters and Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Rechercher par entreprise, client ou prestation...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 14),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'tous', label: Text('Tous')),
                    ButtonSegment(value: 'nouveau', label: Text('Nouveaux')),
                    ButtonSegment(value: 'en_cours', label: Text('En cours')),
                    ButtonSegment(value: 'traite', label: Text('Traités')),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (val) => setState(() => _selectedFilter = val.first),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Devis List
            Expanded(
              child: devis.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Aucune demande de devis trouvée dans la base de données.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualiser'),
                            onPressed: _loadDevis,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: devis.length,
                      itemBuilder: (context, index) {
                        final item = devis[index];
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
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppConfig.brandPinkTint,
                                      child: const Icon(Icons.business_center, color: AppConfig.brandPink),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                item.societe.isNotEmpty ? item.societe : item.nom,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              const SizedBox(width: 10),
                                              StatBadge(label: item.statut.toUpperCase(), status: item.statut),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Contact : ${item.nom} • ${item.telephone} • ${item.email}',
                                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text('Localité : ${item.localite} • Reçu le ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (item.montantUsd > 0)
                                          Text(
                                            '\$${item.montantUsd.toStringAsFixed(0)} USD',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: AppConfig.successGreen,
                                            ),
                                          )
                                        else
                                          const Text('À chiffrer',
                                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                                        const SizedBox(height: 6),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.edit_note, size: 16),
                                          label: const Text('Chiffrer / Traiter'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          ),
                                          onPressed: () => _showChiffrageDialog(item),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: item.services
                                      .map((s) => Chip(
                                            label: Text(s, style: const TextStyle(fontSize: 11)),
                                            backgroundColor: Colors.grey.shade100,
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ))
                                      .toList(),
                                ),
                                if (item.message.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Détail du besoin : ${item.message}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
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
