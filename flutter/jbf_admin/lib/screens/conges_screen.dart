import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/admin_models.dart';
import '../services/supabase_service.dart';
import '../widgets/stat_badge.dart';

class CongesScreen extends StatefulWidget {
  const CongesScreen({super.key});

  @override
  State<CongesScreen> createState() => _CongesScreenState();
}

class _CongesScreenState extends State<CongesScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<CongeItem> _conges = [];

  @override
  void initState() {
    super.initState();
    _loadConges();
  }

  Future<void> _loadConges() async {
    setState(() => _isLoading = true);
    final list = await _supabase.fetchConges();
    if (!mounted) return;
    setState(() {
      _conges = list;
      _isLoading = false;
    });
  }

  void _showDecisionDialog(CongeItem conge, bool approve) {
    final commentCtrl = TextEditingController(
      text: approve ? 'Demande approuvée par la Direction Générale.' : 'Demande refusée pour contraintes opérationnelles.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Approuver le Congé (BDD)' : 'Refuser le Congé (BDD)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Collaborateur : ${conge.agentNom}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Durée : ${conge.nombreJours} jours (${conge.typeConge})'),
            const SizedBox(height: 12),
            const Text('Commentaire / Motif officiel DRH', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(controller: commentCtrl, maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? AppConfig.successGreen : AppConfig.dangerRed,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _supabase.decideConge(conge.id, approve ? 'approuve' : 'refuse', commentCtrl.text);
              _loadConges();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Décision enregistrée dans Supabase pour ${conge.agentNom}')),
              );
            },
            child: Text(approve ? 'Confirmer Approbation' : 'Confirmer Refus'),
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

    return RefreshIndicator(
      onRefresh: _loadConges,
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
                    const Text('Validation des Congés & Absences RH (BDD)',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Données réelles de la table demandes_conges Supabase',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                  tooltip: 'Actualiser',
                  onPressed: _loadConges,
                ),
              ],
            ),
            const SizedBox(height: 18),

            Expanded(
              child: _conges.isEmpty
                  ? const Center(child: Text('Aucune demande de congés dans la base de données.'))
                  : ListView.builder(
                      itemCount: _conges.length,
                      itemBuilder: (context, index) {
                        final c = _conges[index];
                        final isPending = c.statut == 'en_attente';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                                  child: Icon(
                                    Icons.beach_access,
                                    color: isPending ? const Color(0xFFB45309) : const Color(0xFF047857),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(c.agentNom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(width: 10),
                                          StatBadge(label: c.statut.toUpperCase(), status: c.statut),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Type : ${c.typeConge} • ${c.nombreJours} jours ouvrés',
                                        style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      Text('Période : Du ${c.dateDebut.day}/${c.dateDebut.month} au ${c.dateFin.day}/${c.dateFin.month}/${c.dateFin.year}',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      const SizedBox(height: 6),
                                      Text('Motif : ${c.motif}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                      if (c.commentaireAdmin.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text('Réponse DRH : ${c.commentaireAdmin}',
                                            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: AppConfig.brandPinkDark)),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isPending) ...[
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Approuver'),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppConfig.successGreen),
                                    onPressed: () => _showDecisionDialog(c, true),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.close, size: 16, color: AppConfig.dangerRed),
                                    label: const Text('Refuser', style: TextStyle(color: AppConfig.dangerRed)),
                                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppConfig.dangerRed)),
                                    onPressed: () => _showDecisionDialog(c, false),
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
