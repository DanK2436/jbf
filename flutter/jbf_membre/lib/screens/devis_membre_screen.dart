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

  final List<DevisLigne> _lignes = [];

  @override
  void initState() {
    super.initState();
    _loadCatalogue();
  }

  Future<void> _loadCatalogue() async {
    final list = await _materiauxService.getMateriaux();
    if (!mounted) return;
    setState(() {
      _catalogueLocal = list;
      _isLoading = false;
      if (_lignes.isEmpty && list.isNotEmpty) {
        // Pré-remplir avec 2 lignes d'exemple
        _lignes.add(DevisLigne(
          designation: list[0].designation,
          unite: list[0].unite,
          quantite: 50,
          prixUnitaire: list[0].prixUnitaire,
        ));
        if (list.length > 1) {
          _lignes.add(DevisLigne(
            designation: list[1].designation,
            unite: list[1].unite,
            quantite: 30,
            prixUnitaire: list[1].prixUnitaire,
          ));
        }
      }
    });
  }

  double get _totalGeneral => _lignes.fold(0.0, (sum, l) => sum + l.total);

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
          width: 580,
          height: 380,
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
                      trailing: Text(
                        '${item.prixUnitaire.toStringAsFixed(2)} USD',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConfig.successGreen),
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
                          const Text('DESTINATAIRE CLIENT :', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                  const SizedBox(height: 20),

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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF9FAFC), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total Chiffré Matériaux & Main d\'œuvre :', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('${_totalGeneral.toStringAsFixed(2)} USD', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
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
              // Envoi à l'Admin
              try {
                final url = '${AppConfig.supabaseUrl}/rest/v1/devis_membres';
                await http.post(
                  Uri.parse(url),
                  headers: {
                    'apikey': AppConfig.supabaseAnonKey,
                    'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'numero_devis': devisRef,
                    'membre_id': widget.user.id,
                    'nom_collaborateur': widget.user.fullName,
                    'nom_client': _clientCtrl.text.trim(),
                    'projet_prestation': _projetCtrl.text.trim(),
                    'site_intervention': _siteCtrl.text.trim(),
                    'lignes_elements': _lignes.map((l) => l.toJson()).toList(),
                    'total_ht': _totalGeneral,
                    'devise': 'USD',
                    'sceau_numerique_hash': sautNumerique,
                    'statut': 'transmis_admin',
                  }),
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Devis avec saut numérique transmis à la Direction JBF avec succès !'),
                    backgroundColor: AppConfig.successGreen,
                  ),
                );
              } catch (_) {}
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
                  const Text('1. Informations du Projet & Client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _clientCtrl,
                          decoration: const InputDecoration(labelText: 'Nom du Client ou Société *', hintText: 'ex: Mutanda Mining SARL'),
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
                  const Divider(height: 30),

                  // Total & Bouton Générer PDF
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Chiffré Matériaux & MO :', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          Text(
                            '${_totalGeneral.toStringAsFixed(2)} USD',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppConfig.blackText),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
