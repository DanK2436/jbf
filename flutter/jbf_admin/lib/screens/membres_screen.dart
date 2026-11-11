import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/admin_models.dart';
import '../services/supabase_service.dart';

class MembresScreen extends StatefulWidget {
  const MembresScreen({super.key});

  @override
  State<MembresScreen> createState() => _MembresScreenState();
}

class _MembresScreenState extends State<MembresScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<MembreItem> _membres = [];

  @override
  void initState() {
    super.initState();
    _loadMembres();
  }

  Future<void> _loadMembres() async {
    setState(() => _isLoading = true);
    final list = await _supabase.fetchMembres();
    if (!mounted) return;
    setState(() {
      _membres = list;
      _isLoading = false;
    });
  }

  void _showAddMembreDialog() {
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+243');
    final matCtrl = TextEditingController(text: 'JBF-M-2026-0${_membres.length + 10}');
    final posteCtrl = TextEditingController();
    final secCtrl = TextEditingController(text: 'Sous-traitance Minière');
    final provCtrl = TextEditingController(text: 'Lualaba (Kolwezi)');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enregistrer un Collaborateur dans Supabase (BDD)'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nom Complet', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: nomCtrl, decoration: const InputDecoration(hintText: 'ex: Kasongo Mutombo')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Matricule JBF', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(controller: matCtrl),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Téléphone Mobile', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(controller: phoneCtrl),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Adresse Email (Manuelle pour OTP)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: emailCtrl, decoration: const InputDecoration(hintText: 'ex: k.mutombo@jbf.cd')),
                const SizedBox(height: 12),
                const Text('Poste & Qualification', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(controller: posteCtrl, decoration: const InputDecoration(hintText: 'ex: Technicien Chaudronnerie')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Département / Pôle', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(controller: secCtrl),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Province / Ville', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(controller: provCtrl),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (nomCtrl.text.isEmpty || emailCtrl.text.isEmpty) return;
              Navigator.of(ctx).pop();

              final m = MembreItem(
                id: '',
                nom: nomCtrl.text,
                email: emailCtrl.text.trim().toLowerCase(),
                phone: phoneCtrl.text,
                matricule: matCtrl.text,
                poste: posteCtrl.text.isNotEmpty ? posteCtrl.text : 'Agent de Terrain',
                sectionNom: secCtrl.text,
                province: provCtrl.text,
                soldeConges: -1,
              );

              final saved = await _supabase.createMembre(m);
              _loadMembres();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(saved
                    ? 'Collaborateur enregistré.'
                    : 'Enregistrement refusé. Le collaborateur n\'a pas été créé.')),
              );
            },
            child: const Text('Enregistrer dans Supabase'),
          ),
        ],
      ),
    );
  }

  void _showEditMembreDialog(MembreItem item) {
    final emailCtrl = TextEditingController(text: item.email);
    final nomCtrl = TextEditingController(text: item.nom);
    final phoneCtrl = TextEditingController(text: item.phone);
    final soldeCtrl = TextEditingController(text: item.soldeConges.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier Membre & Email OTP — ${item.nom}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Adresse Email (réception OTP)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(controller: emailCtrl),
            const SizedBox(height: 12),
            const Text('Téléphone Mobile', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(controller: phoneCtrl),
            const SizedBox(height: 12),
            const Text('Solde Congés (Jours)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(controller: soldeCtrl, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              item.email = emailCtrl.text.trim().toLowerCase();
              item.nom = nomCtrl.text.trim();
              item.phone = phoneCtrl.text.trim();
              item.soldeConges = int.tryParse(soldeCtrl.text) ?? item.soldeConges;

              await _supabase.updateMembre(item);
              _loadMembres();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fiche collaborateur mise à jour dans Supabase')),
              );
            },
            child: const Text('Enregistrer'),
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
      onRefresh: _loadMembres,
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
                    const Text('Annuaire des Membres & Collaborateurs (BDD)',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Données réelles de la table profiles Supabase avec email OTP modifiable',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                      tooltip: 'Actualiser',
                      onPressed: _loadMembres,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Ajouter Collaborateur'),
                      onPressed: _showAddMembreDialog,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _membres.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('Aucun collaborateur trouvé dans la table profiles.'),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.person_add),
                                label: const Text('Ajouter le premier collaborateur'),
                                onPressed: _showAddMembreDialog,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _membres.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final m = _membres[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              leading: CircleAvatar(
                                backgroundColor: AppConfig.brandPink,
                                foregroundColor: Colors.white,
                                child: Text(m.nom.substring(0, m.nom.length >= 2 ? 2 : 1).toUpperCase()),
                              ),
                              title: Row(
                                children: [
                                  Text(m.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppConfig.brandPinkTint,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(m.matricule,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConfig.brandPinkDark)),
                                  ),
                                ],
                              ),
                              subtitle: Text('${m.poste} • ${m.province}\nEmail OTP : ${m.email} • Tél : ${m.phone}'),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      m.soldeConges < 0 ? 'Solde non renseigné' : 'Solde : ${m.soldeConges}j',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppConfig.brandPink),
                                    tooltip: 'Modifier Email OTP & Fiche',
                                    onPressed: () => _showEditMembreDialog(m),
                                  ),
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
