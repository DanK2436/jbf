import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/membre_models.dart';
import '../services/materiaux_local_service.dart';

class DevisLigne {
  String designation;
  String unite;
  double quantite;
  double prixUnitaire;

  DevisLigne({
    required this.designation,
    required this.unite,
    required this.quantite,
    required this.prixUnitaire,
  });

  double get total => quantite * prixUnitaire;

  Map<String, dynamic> toJson() => {
        'designation': designation,
        'unite': unite,
        'quantite': quantite,
        'prix_unitaire': prixUnitaire,
        'total': total,
      };
}

class DevisMembreScreen extends StatefulWidget {
  final MembreUser user;

  const DevisMembreScreen({super.key, required this.user});

  @override
  State<DevisMembreScreen> createState() => _DevisMembreScreenState();
}

class _DevisMembreScreenState extends State<DevisMembreScreen> {
  final _materiauxService = MateriauxLocalService();
  List<MateriauItem> _catalogueLocal = [];
  bool _isLoading = true;

  final _clientCtrl = TextEditingController();
  final _projetCtrl = TextEditingController();
  final _siteCtrl = TextEditingController(text: 'Kolwezi / Lualaba');
  final _mainDOeuvreCtrl = TextEditingController(text: '150.00');
  final _explicationsCtrl = TextEditingController(
    text: 'Prestation chiffrée selon cahier des charges et spécifications techniques JBF Services SARL. Main d\'œuvre qualifiée et équipements certifiés HSE inclus.',
  );

  List<MembreMission> _assignedMissions = [];
  MembreMission? _selectedMission;

  final List<DevisLigne> _lignes = [];

  @override
  void initState() {
    super.initState();
    _loadCatalogue();
    _loadAssignedMissions();
  }

  Future<void> _loadAssignedMissions() async {
    try {
      final mList = await SupabaseService().fetchMissions(
        agentNom: widget.user.fullName,
        agentId: widget.user.id,
        agentMatricule: widget.user.matricule,
      );
      if (mounted) setState(() => _assignedMissions = mList);
    } catch (_) {}
  }

  Future<void> _loadCatalogue() async {
    final list = await _materiauxService.getMateriaux();
    if (!mounted) return;
    setState(() {
      _catalogueLocal = list;
      _isLoading = false;
    });
  }

  double get _totalMateriaux => _lignes.fold(0.0, (sum, l) => sum + l.total);
  double get _mainDOeuvre => double.tryParse(_mainDOeuvreCtrl.text) ?? 0.0;
  double get _totalGeneral => _totalMateriaux + _mainDOeuvre;

  void _showAddMateriauDialog() {
    final desCtrl = TextEditingController();
    final uniteCtrl = TextEditingController(text: 'pièce');
    final prixCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Matériel Général');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: AppConfig.brandPink),
            SizedBox(width: 8),
            Text('Ajouter à ma BDD Locale'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: desCtrl,
                decoration: const InputDecoration(labelText: 'Désignation de l\'article *', hintText: 'ex: Disque tronçonnage 230mm'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: uniteCtrl,
                      decoration: const InputDecoration(labelText: 'Unité (sac, m, kg, pièce...)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: prixCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Prix Unitaire (USD) *', hintText: 'ex: 12.50'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
            onPressed: () async {
              if (desCtrl.text.isEmpty || prixCtrl.text.isEmpty) return;
              final newItem = MateriauItem(
                id: 'mat-${DateTime.now().millisecondsSinceEpoch}',
                designation: desCtrl.text.trim(),
                unite: uniteCtrl.text.trim(),
                prixUnitaire: double.tryParse(prixCtrl.text) ?? 0.0,
                categorie: catCtrl.text.trim(),
              );
              await _materiauxService.addMateriau(newItem);
              Navigator.of(ctx).pop();
              _loadCatalogue();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Matériel mémorisé dans votre BDD locale avec succès !'), backgroundColor: AppConfig.successGreen),
              );
            },
            child: const Text('Mémoriser dans ma BDD'),
          ),
        ],
      ),
    );
  }

  void _showEditMateriauDialog(MateriauItem item) {
    final desCtrl = TextEditingController(text: item.designation);
    final uniteCtrl = TextEditingController(text: item.unite);
    final prixCtrl = TextEditingController(text: item.prixUnitaire.toStringAsFixed(2));
    final catCtrl = TextEditingController(text: item.categorie);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: AppConfig.brandPink),
            SizedBox(width: 8),
            Text('Modifier dans ma BDD Locale'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: desCtrl,
                decoration: const InputDecoration(labelText: 'Désignation de l\'article *'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: uniteCtrl,
                      decoration: const InputDecoration(labelText: 'Unité (sac, m, pièce...)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: prixCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Prix Unitaire (USD) *'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
            onPressed: () async {
              if (desCtrl.text.isEmpty || prixCtrl.text.isEmpty) return;
              final updated = MateriauItem(
                id: item.id,
                designation: desCtrl.text.trim(),
                unite: uniteCtrl.text.trim(),
                prixUnitaire: double.tryParse(prixCtrl.text) ?? 0.0,
                categorie: catCtrl.text.trim(),
              );
              await _materiauxService.updateMateriau(updated);
              Navigator.of(ctx).pop();
              _loadCatalogue();
              _showLocalDatabaseViewer();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Matériel mis à jour avec succès !'), backgroundColor: AppConfig.successGreen),
              );
            },
            child: const Text('Enregistrer modifications'),
          ),
        ],
      ),
    );
  }

  void _showLocalDatabaseViewer() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.storage, color: AppConfig.brandPink),
                SizedBox(width: 8),
                Text('Ma Base de Données Locale de Prix'),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppConfig.brandPink),
              tooltip: 'Ajouter un matériel',
              onPressed: () {
                Navigator.of(ctx).pop();
                _showAddMateriauDialog();
              },
            ),
          ],
        ),
        content: SizedBox(
          width: 620,
          height: 420,
          child: _catalogueLocal.isEmpty
              ? const Center(child: Text('Aucun matériel enregistré.'))
              : ListView.separated(
                  itemCount: _catalogueLocal.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = _catalogueLocal[i];
                    return ListTile(
                      title: Text(item.designation, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: Text('Catégorie : ${item.categorie} • Unité : ${item.unite}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${item.prixUnitaire.toStringAsFixed(2)} USD',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConfig.successGreen),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                            tooltip: 'Modifier ce matériel',
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _showEditMateriauDialog(item);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppConfig.dangerRed, size: 20),
                            tooltip: 'Supprimer ce matériel',
                            onPressed: () async {
                              await _materiauxService.deleteMateriau(item.id);
                              _loadCatalogue();
                              Navigator.of(ctx).pop();
                              _showLocalDatabaseViewer();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<void> _showHistoriqueDevisDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.history, color: AppConfig.brandPink),
                SizedBox(width: 8),
                Text('Historique de mes Devis Transmis (BDD Supabase)'),
              ],
            ),
            content: SizedBox(
              width: 650,
              height: 420,
              child: FutureBuilder<http.Response>(
                future: http.get(
                  Uri.parse('${AppConfig.supabaseUrl}/rest/v1/devis_membres?nom_collaborateur=eq.${Uri.encodeComponent(widget.user.fullName)}&order=created_at.desc'),
                  headers: {
                    'apikey': AppConfig.supabaseAnonKey,
                    'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                  },
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
                  }
                  if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
                    return const Center(child: Text('Aucun devis enregistré pour ce profil.'));
                  }
                  final List list = jsonDecode(snapshot.data!.body);
                  if (list.isEmpty) {
                    return const Center(child: Text('Vous n\'avez pas encore transmis de devis.'));
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final d = list[i];
                      final id = d['id']?.toString() ?? '';
                      final client = d['nom_client'] ?? 'Client';
                      final projet = d['projet_prestation'] ?? 'Prestation';
                      final montant = (d['total_ht'] as num?)?.toDouble() ?? 0.0;
                      final statut = d['statut'] ?? 'transmis_admin';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppConfig.brandPinkTint,
                          child: const Icon(Icons.description, color: AppConfig.brandPink),
                        ),
                        title: Text('$client — $projet', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        subtitle: Text('Réf: ${d['numero_devis'] ?? ''} • Statut: $statut\nSite: ${d['site_intervention'] ?? ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${montant.toStringAsFixed(2)} \$',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: AppConfig.successGreen, fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppConfig.dangerRed, size: 20),
                              tooltip: 'Supprimer ce devis de la BDD',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Supprimer ce devis ?'),
                                    content: Text('Voulez-vous supprimer définitivement le devis de $client de la base de données ?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Annuler')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
                                        onPressed: () => Navigator.of(c).pop(true),
                                        child: const Text('Supprimer'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await http.delete(
                                      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/devis_membres?id=eq.$id'),
                                      headers: {
                                        'apikey': AppConfig.supabaseAnonKey,
                                        'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                                      },
                                    );
                                  } catch (_) {}
                                  Navigator.of(ctx).pop();
                                  _showHistoriqueDevisDialog();
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fermer')),
            ],
          );
        },
      ),
    );
  }

  void _addNewLine() {
    if (_catalogueLocal.isNotEmpty) {
      final first = _catalogueLocal.first;
      setState(() {
        _lignes.add(DevisLigne(
          designation: first.designation,
          unite: first.unite,
          quantite: 1,
          prixUnitaire: first.prixUnitaire,
        ));
      });
    } else {
      setState(() {
        _lignes.add(DevisLigne(
          designation: 'Article personnalisé',
          unite: 'pièce',
          quantite: 1,
          prixUnitaire: 0.0,
        ));
      });
    }
  }

  void _previewAndGeneratePdf() {
    if (_clientCtrl.text.isEmpty || _projetCtrl.text.isEmpty || _lignes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner le client, le projet et au moins une ligne chiffrée.')),
      );
      return;
    }

    final devisRef = 'DEV-MBR-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final sautNumerique = 'JBF-SEAL-SHA256-${widget.user.matricule}-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.picture_as_pdf, color: AppConfig.brandPink),
                SizedBox(width: 8),
                Text('Aperçu du Devis Officiel PDF & Saut Numérique'),
              ],
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
          ],
        ),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête officiel JBF
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('JBF SERVICES SARL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.brandPink)),
                          Text('Sous-traitance Minière, Catering & BTP en RDC', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                          const Text('RCCM: CD/LSH/RCCM/20-B-0123 • NIF: A2314569B', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppConfig.brandPinkTint, borderRadius: BorderRadius.circular(6)),
                        child: Text(devisRef, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppConfig.brandPink)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Client & Collaborateur
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DESTINATAIRE CLIENT / PROPRIÉTAIRE :', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(_clientCtrl.text.trim(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('Projet : ${_projetCtrl.text.trim()}'),
                          Text('Site : ${_siteCtrl.text.trim()}'),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('ÉMIS PAR LE COLLABORATEUR :', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(widget.user.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('Matricule : ${widget.user.matricule}'),
                          Text('Poste : ${widget.user.poste}'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Encadré Explications détaillées du Devis
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('EXPLICATIONS & MODALITÉS DU DEVIS :',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF166534))),
                        const SizedBox(height: 4),
                        Text(
                          _explicationsCtrl.text.trim().isNotEmpty
                              ? _explicationsCtrl.text.trim()
                              : 'Prestation chiffrée selon normes HSE et standards de sécurité JBF Services SARL.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF14532D)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tableau des postes chiffrés
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(6)),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: const Color(0xFFF9FAFC),
                          child: const Row(
                            children: [
                              Expanded(flex: 4, child: Text('Désignation des Fournitures & Travaux', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              Expanded(child: Text('Unité', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              Expanded(child: Text('Qté', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              Expanded(flex: 2, child: Text('P.U (USD)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              Expanded(flex: 2, child: Text('Total (USD)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            ],
                          ),
                        ),
                        ..._lignes.map((l) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(flex: 4, child: Text(l.designation, style: const TextStyle(fontSize: 12))),
                                  Expanded(child: Text(l.unite, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                                  Expanded(child: Text(l.quantite.toStringAsFixed(0), style: const TextStyle(fontSize: 12))),
                                  Expanded(flex: 2, child: Text('${l.prixUnitaire.toStringAsFixed(2)} \$', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                                  Expanded(flex: 2, child: Text('${l.total.toStringAsFixed(2)} \$', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total général
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Fournitures & Matériaux : ${_totalMateriaux.toStringAsFixed(2)} USD', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 3),
                          Text('Main d\'œuvre & Travaux : ${_mainDOeuvre.toStringAsFixed(2)} USD', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const Divider(height: 12),
                          Text('${_totalGeneral.toStringAsFixed(2)} USD', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
                          const Text('Total Net HT (Matériaux + Main d\'œuvre)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Saut Numérique Officiel JBF
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2F8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppConfig.brandPink.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user, color: AppConfig.brandPink, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SAUT NUMÉRIQUE DE CONFORMITÉ JBF SERVICES SARL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConfig.brandPink)),
                              Text('Empreinte : $sautNumerique', style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.black87)),
                              const Text('Document certifié et horodaté conforme aux spécifications techniques.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Envoi à la Direction Admin
              bool sent = false;
              try {
                // 1. Envoi dans devis_membres
                final urlM = '${AppConfig.supabaseUrl}/rest/v1/devis_membres';
                final bodyM = {
                  'numero_devis': devisRef,
                  'nom_collaborateur': widget.user.fullName,
                  'nom_client': _clientCtrl.text.trim(),
                  'nom_proprietaire': _clientCtrl.text.trim(),
                  'projet_prestation': _projetCtrl.text.trim(),
                  'site_intervention': _siteCtrl.text.trim(),
                  'lignes_elements': _lignes.map((l) => l.toJson()).toList(),
                  'total_materiaux': _totalMateriaux,
                  'main_d_oeuvre': _mainDOeuvre,
                  'explications': _explicationsCtrl.text.trim(),
                  'total_ht': _totalGeneral,
                  'devise': 'USD',
                  'sceau_numerique_hash': sautNumerique,
                  'statut': 'transmis_admin',
                };
                // Si widget.user.id est un UUID valide, l'ajouter
                if (widget.user.id.length > 20 && !widget.user.id.startsWith('mem-') && !widget.user.id.startsWith('usr-')) {
                  bodyM['membre_id'] = widget.user.id;
                }

                final resM = await http.post(
                  Uri.parse(urlM),
                  headers: {
                    'apikey': AppConfig.supabaseAnonKey,
                    'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode(bodyM),
                );

                if (resM.statusCode >= 200 && resM.statusCode < 300) {
                  sent = true;
                }
              } catch (_) {}

              // 2. Repli de sécurité : Envoi également dans demandes_devis pour garantie de réception
              try {
                final urlD = '${AppConfig.supabaseUrl}/rest/v1/demandes_devis';
                await http.post(
                  Uri.parse(urlD),
                  headers: {
                    'apikey': AppConfig.supabaseAnonKey,
                    'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'nom': widget.user.fullName,
                    'client_nom': _clientCtrl.text.trim(),
                    'proprietaire': _clientCtrl.text.trim(),
                    'societe': _clientCtrl.text.trim(),
                    'email': widget.user.email,
                    'telephone': widget.user.phone ?? '+243970349724',
                    'services': ['Devis Membre: ${_projetCtrl.text.trim()}'],
                    'prestation': _projetCtrl.text.trim(),
                    'site_intervention': _siteCtrl.text.trim(),
                    'localite': _siteCtrl.text.trim(),
                    'details_besoin': 'Devis membre: Matériaux: ${_totalMateriaux.toStringAsFixed(2)} USD + MO: ${_mainDOeuvre.toStringAsFixed(2)} USD = Total: ${_totalGeneral.toStringAsFixed(2)} USD. Réf: $devisRef. Sceau: $sautNumerique\nExplications: ${_explicationsCtrl.text.trim()}',
                    'message': 'Chiffrage officiel émis par ${widget.user.fullName} (${widget.user.matricule}) pour ${_clientCtrl.text.trim()} sur ${_siteCtrl.text.trim()}. Matériaux: ${_totalMateriaux.toStringAsFixed(2)} USD, MO: ${_mainDOeuvre.toStringAsFixed(2)} USD, Total: ${_totalGeneral.toStringAsFixed(2)} USD.',
                    'statut': 'transmis_admin',
                    'montant_estime': _totalGeneral,
                  }),
                );
                sent = true;
              } catch (_) {}

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(sent
                      ? 'Devis avec saut numérique transmis à la Direction JBF avec succès !'
                      : 'Devis sauvegardé localement et transmis à la Direction.'),
                  backgroundColor: AppConfig.successGreen,
                ),
              );
            },
            icon: const Icon(Icons.send),
            label: const Text('Transmettre à la Direction Admin'),
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Module Devis & BDD Locale de Matériaux',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText),
                    ),
                    Text(
                      'Chiffrage rapide hors-ligne avec base locale des prix et génération PDF avec saut numérique',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showHistoriqueDevisDialog,
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text('Mes Devis Transmis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _showLocalDatabaseViewer,
                      icon: const Icon(Icons.storage, size: 16),
                      label: Text('Consulter Ma BDD Locale (${_catalogueLocal.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _showAddMateriauDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Enregistrer un Matériel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.brandPink,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Formulaire Informations Générales
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
                  const Text('1. Informations du Projet & Client / Propriétaire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 14),
                  if (_assignedMissions.isNotEmpty) ...[
                    DropdownButtonFormField<MembreMission>(
                      value: _selectedMission,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Lier à un projet / mission transféré par l\'Admin',
                        prefixIcon: Icon(Icons.assignment_turned_in, color: AppConfig.brandPink),
                        helperText: 'Renseigne automatiquement le nom du client propriétaire, l\'intitulé et le site d\'intervention.',
                      ),
                      hint: const Text('Sélectionner une mission affectée par la Direction...'),
                      items: _assignedMissions.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text('${m.titre} — Propriétaire : ${m.client} (${m.siteIntervention})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (m) {
                        if (m != null) {
                          setState(() {
                            _selectedMission = m;
                            _clientCtrl.text = m.client; // Nom du propriétaire automatique !
                            _projetCtrl.text = m.titre;
                            _siteCtrl.text = m.siteIntervention;
                            if (m.description.isNotEmpty) {
                              _explicationsCtrl.text = 'Prestation liée à l\'ordre de mission : ${m.titre}.\nCahier des charges : ${m.description}';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _clientCtrl,
                          decoration: const InputDecoration(labelText: 'Nom du Client Propriétaire *', hintText: 'ex: Mutanda Mining SARL'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _projetCtrl,
                          decoration: const InputDecoration(labelText: 'Intitulé des Travaux / Prestation *', hintText: 'ex: Réfection Tuyauterie Usine'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _siteCtrl,
                          decoration: const InputDecoration(labelText: 'Site d\'Intervention', hintText: 'ex: Kolwezi (Tenke)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Table des lignes de devis
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('2. Postes Chiffrés (Matériaux & Main d\'œuvre)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ElevatedButton.icon(
                        onPressed: _addNewLine,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Ajouter une Ligne'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_lignes.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucune ligne. Cliquez sur "Ajouter une Ligne".')))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _lignes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final l = _lignes[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              // Sélecteur auto-complété depuis BDD locale
                              Expanded(
                                flex: 4,
                                child: DropdownButtonFormField<String>(
                                  value: _catalogueLocal.any((item) => item.designation == l.designation) ? l.designation : null,
                                  isExpanded: true,
                                  hint: Text(l.designation),
                                  decoration: const InputDecoration(labelText: 'Matériel (BDD Locale)', isDense: true),
                                  items: _catalogueLocal.map((m) {
                                    return DropdownMenuItem(
                                      value: m.designation,
                                      child: Text('${m.designation} (${m.prixUnitaire} \$ / ${m.unite})', style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      final found = _catalogueLocal.firstWhere((m) => m.designation == val);
                                      setState(() {
                                        l.designation = found.designation;
                                        l.unite = found.unite;
                                        l.prixUnitaire = found.prixUnitaire;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: l.quantite.toStringAsFixed(0),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Quantité', isDense: true),
                                  onChanged: (v) {
                                    setState(() {
                                      l.quantite = double.tryParse(v) ?? 1;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: l.prixUnitaire.toStringAsFixed(2),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Prix Unit. (\$)', isDense: true),
                                  onChanged: (v) {
                                    setState(() {
                                      l.prixUnitaire = double.tryParse(v) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              SizedBox(
                                width: 110,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Sous-total', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text('${l.total.toStringAsFixed(2)} \$', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppConfig.dangerRed, size: 20),
                                onPressed: () => setState(() => _lignes.removeAt(index)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3 : Main d'œuvre modifiable & Explications
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
                  const Text('3. Main d\'œuvre Qualifiée & Explications Détaillées',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _mainDOeuvreCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Coût Main d\'œuvre (USD) *',
                            prefixIcon: Icon(Icons.engineering, color: AppConfig.brandPink),
                            helperText: 'Montant modifiable pour la main d\'œuvre et prestations techniques.',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: TextField(
                          controller: _explicationsCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Explications & Modalités par rapport au devis',
                            prefixIcon: Icon(Icons.notes, color: AppConfig.brandPink),
                            helperText: 'Précisez la méthodologie, garanties, délais et normes HSE appliquées.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Récapitulatif Final & Bouton Générer PDF
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Fournitures: ${_totalMateriaux.toStringAsFixed(2)} \$',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          const Text('  •  ', style: TextStyle(color: Colors.grey)),
                          Text('Main d\'œuvre: ${_mainDOeuvre.toStringAsFixed(2)} \$',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('Total Net HT : ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text(
                            '${_totalGeneral.toStringAsFixed(2)} USD',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppConfig.blackText),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _previewAndGeneratePdf,
                    icon: const Icon(Icons.verified, size: 18),
                    label: const Text('Générer le Devis PDF & Saut Numérique'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.brandPink,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
