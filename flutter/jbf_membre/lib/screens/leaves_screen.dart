import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/membre_models.dart';
import '../services/supabase_service.dart';
import '../widgets/stat_badge.dart';

class LeavesScreen extends StatefulWidget {
  final MembreUser user;

  const LeavesScreen({super.key, required this.user});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<LeaveRequest> _leaves = [];

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    setState(() => _isLoading = true);
    final list = await _supabase.fetchLeaves(agentNom: widget.user.fullName);
    if (!mounted) return;
    setState(() {
      _leaves = list;
      _isLoading = false;
    });
  }

  void _showNewLeaveDialog() {
    String type = 'Annuel';
    DateTime debut = DateTime.now().add(const Duration(days: 7));
    DateTime fin = DateTime.now().add(const Duration(days: 17));
    final motifCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final diff = fin.difference(debut).inDays + 1;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Soumettre une Demande de Congé'),
            content: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Agent : ${widget.user.fullName} (${widget.user.matricule})',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Solde légal : ${widget.user.soldeConges} jours restants',
                        style: const TextStyle(color: AppConfig.brandPinkDark, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    const Text('Nature de l\'Absence', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: type,
                      items: const [
                        DropdownMenuItem(value: 'Annuel', child: Text('Congé Annuel Payé')),
                        DropdownMenuItem(value: 'Maladie', child: Text('Arrêt Maladie / Hospitalisation')),
                        DropdownMenuItem(value: 'Famille', child: Text('Événement Familial / Mariage / Deuil')),
                        DropdownMenuItem(value: 'Maternite', child: Text('Congé Maternité / Paternité')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => type = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date de début', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text('${debut.day}/${debut.month}/${debut.year}'),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: debut,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) setDialogState(() => debut = picked);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date de fin', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text('${fin.day}/${fin.month}/${fin.year}'),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: fin,
                                    firstDate: debut,
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) setDialogState(() => fin = picked);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConfig.brandPinkTint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Durée calculée : $diff jours ouvrés',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppConfig.brandPinkDark)),
                    ),
                    const SizedBox(height: 14),
                    const Text('Motif & Justification', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: motifCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Précisez la raison de votre demande...'),
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
                  await _supabase.createLeaveRequest(
                    agentNom: widget.user.fullName,
                    typeConge: type,
                    debut: debut,
                    fin: fin,
                    jours: diff > 0 ? diff : 1,
                    motif: motifCtrl.text.isNotEmpty ? motifCtrl.text : 'Congé $type sollicité',
                  );
                  _loadLeaves();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demande de congé enregistrée dans la table demandes_conges Supabase')),
                  );
                },
                child: const Text('Soumettre dans Supabase'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditLeaveDialog(LeaveRequest l) {
    String type = l.typeConge;
    DateTime debut = l.dateDebut;
    DateTime fin = l.dateFin;
    final motifCtrl = TextEditingController(text: l.motif);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final diff = fin.difference(debut).inDays + 1;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.edit_note, color: AppConfig.brandPink),
                SizedBox(width: 8),
                Expanded(child: Text('Modifier la Demande de Congé', overflow: TextOverflow.ellipsis)),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Agent : ${widget.user.fullName} (${widget.user.matricule})',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    const Text('Nature de l\'Absence', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: ['Annuel', 'Maladie', 'Famille', 'Maternite'].contains(type) ? type : 'Annuel',
                      items: const [
                        DropdownMenuItem(value: 'Annuel', child: Text('Congé Annuel Payé')),
                        DropdownMenuItem(value: 'Maladie', child: Text('Arrêt Maladie / Hospitalisation')),
                        DropdownMenuItem(value: 'Famille', child: Text('Événement Familial / Mariage / Deuil')),
                        DropdownMenuItem(value: 'Maternite', child: Text('Congé Maternité / Paternité')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => type = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date de début', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text('${debut.day}/${debut.month}/${debut.year}'),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: debut,
                                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) setDialogState(() => debut = picked);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date de fin', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text('${fin.day}/${fin.month}/${fin.year}'),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: fin,
                                    firstDate: debut,
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) setDialogState(() => fin = picked);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConfig.brandPinkTint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Durée recalculée : $diff jours ouvrés',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppConfig.brandPinkDark)),
                    ),
                    const SizedBox(height: 14),
                    const Text('Motif & Justification', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: motifCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Précisez la raison de votre demande...'),
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
                  final ok = await _supabase.updateLeaveRequest(
                    id: l.id,
                    typeConge: type,
                    debut: debut,
                    fin: fin,
                    jours: diff > 0 ? diff : 1,
                    motif: motifCtrl.text.trim(),
                  );
                  _loadLeaves();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Demande de congé mise à jour avec succès.' : 'Erreur lors de la mise à jour.'),
                      backgroundColor: ok ? AppConfig.successGreen : AppConfig.dangerRed,
                    ),
                  );
                },
                child: const Text('Enregistrer les modifications'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteLeave(LeaveRequest l) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette demande de congé ?'),
        content: Text('Êtes-vous certain de vouloir annuler votre demande de congé du ${l.dateDebut.day}/${l.dateDebut.month}/${l.dateDebut.year} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Non, garder')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Oui, supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await _supabase.deleteLeaveRequest(l.id);
      _loadLeaves();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Demande de congé supprimée avec succès.' : 'Erreur lors de la suppression.'),
          backgroundColor: ok ? AppConfig.successGreen : AppConfig.dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    return RefreshIndicator(
      onRefresh: _loadLeaves,
      color: AppConfig.brandPink,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gestion des Congés & Absences',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Suivi des droits RH et des validations de congés',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                      tooltip: 'Actualiser',
                      onPressed: _loadLeaves,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Demander un Congé'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.brandPink,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: _showNewLeaveDialog,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 500;
                final card1 = Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SOLDE DE CONGÉS DISPONIBLE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('${widget.user.soldeConges} Jours',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConfig.brandPink)),
                        const Text('Droits légaux enregistrés en BDD', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
                final card2 = Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DEMANDES ENREGISTRÉES',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('${_leaves.length} Dossier(s)',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
                        const Text('Historique complet des demandes', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                      ],
                    ),
                  ),
                );

                if (isMobile) {
                  return Column(
                    children: [
                      card1,
                      const SizedBox(height: 8),
                      card2,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: card1),
                    const SizedBox(width: 12),
                    Expanded(child: card2),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: _leaves.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.beach_access_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('Aucune demande de congé trouvée dans la base de données.', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Déposer une demande de congé'),
                                onPressed: _showNewLeaveDialog,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _leaves.length,
                          separatorBuilder: (_, __) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final l = _leaves[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppConfig.brandPinkTint,
                                      child: const Icon(Icons.beach_access, color: AppConfig.brandPink, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Congé ${l.typeConge} — ${l.nombreJours} jours ouvrés',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          const SizedBox(height: 2),
                                          Text(
                                              'Du ${l.dateDebut.day}/${l.dateDebut.month}/${l.dateDebut.year} au ${l.dateFin.day}/${l.dateFin.month}/${l.dateFin.year}',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Motif : ${l.motif}', style: const TextStyle(fontSize: 12.5)),
                                if (l.commentaireAdmin.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Retour DRH : ${l.commentaireAdmin}',
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic, color: AppConfig.brandPinkDark, fontSize: 12)),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    StatBadge(label: l.statut.toUpperCase(), status: l.statut),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
                                          tooltip: 'Modifier',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
                                          onPressed: () => _showEditLeaveDialog(l),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppConfig.dangerRed, size: 18),
                                          tooltip: 'Supprimer',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
                                          onPressed: () => _deleteLeave(l),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
          ],
        ),
      ),
    );
  }
}
