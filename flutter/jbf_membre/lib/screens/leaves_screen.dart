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
            title: const Text('Soumettre une Demande de Congé (Supabase BDD)'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Agent : ${widget.user.fullName} (${widget.user.matricule})',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.user.soldeConges < 0
                        ? 'Solde non renseigné'
                        : 'Solde légal : ${widget.user.soldeConges} jours restants',
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    return RefreshIndicator(
      onRefresh: _loadLeaves,
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
                    const Text('Gestion des Congés & Absences (BDD)',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Données réelles de la table demandes_conges Supabase',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                      tooltip: 'Actualiser',
                      onPressed: _loadLeaves,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Demander un Congé'),
                      onPressed: _showNewLeaveDialog,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SOLDE DE CONGÉS DISPONIBLE',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text(widget.user.soldeConges < 0 ? 'Non renseigné' : '${widget.user.soldeConges} Jours',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConfig.brandPink)),
                          const Text('Droits légaux enregistrés en BDD', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DEMANDES ENREGISTRÉES',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text('${_leaves.length} Dossier(s)',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
                          const Text('Dans la table demandes_conges', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final l = _leaves[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppConfig.brandPinkTint,
                                    child: const Icon(Icons.beach_access, color: AppConfig.brandPink),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Congé ${l.typeConge} — ${l.nombreJours} jours ouvrés',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text(
                                            'Du ${l.dateDebut.day}/${l.dateDebut.month}/${l.dateDebut.year} au ${l.dateFin.day}/${l.dateFin.month}/${l.dateFin.year}',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Motif : ${l.motif}', style: const TextStyle(fontSize: 13)),
                                        if (l.commentaireAdmin.isNotEmpty)
                                          Text('Retour DRH : ${l.commentaireAdmin}',
                                              style: const TextStyle(
                                                  fontStyle: FontStyle.italic, color: AppConfig.brandPinkDark, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  StatBadge(label: l.statut.toUpperCase(), status: l.statut),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
