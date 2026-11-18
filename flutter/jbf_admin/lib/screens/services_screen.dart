import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/file_picker_helper.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  bool _isLoading = true;
  bool _isSeeding = false;
  List<Map<String, dynamic>> _services = [];
  String _filterCategorie = 'toutes';
  String _searchQuery = '';

  static const List<String> _categories = [
    'toutes',
    'Mines & Industrie',
    'Alimentaire',
    'Construction',
    'Maintenance',
    'Sécurité',
    'Logistique',
    'Services Généraux',
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final url = '${AppConfig.supabaseUrl}/rest/v1/services_catalogue?select=*&order=ordre_affichage.asc';
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        // Decodage UTF-8 strict pour eviter les caracteres corrompus
        final utf8String = utf8.decode(res.bodyBytes);
        final list = jsonDecode(utf8String) as List;
        if (mounted) {
          setState(() {
            _services = list.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Erreur chargement services: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _syncToCmsConfig() async {
    try {
      final payload = {
        'cle_nom': 'cms_services_catalogue_json',
        'cle_valeur': jsonEncode(_services),
      };
      await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/config_cles_api?on_conflict=cle_nom'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json; charset=utf-8',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: utf8.encode(jsonEncode(payload)),
      );
    } catch (_) {}
  }

  Future<void> _toggleServiceActive(Map<String, dynamic> srv) async {
    final bool currentStatus = srv['est_actif'] == true;
    final bool newStatus = !currentStatus;
    final srvId = srv['id'];

    setState(() {
      srv['est_actif'] = newStatus;
    });

    try {
      final url = '${AppConfig.supabaseUrl}/rest/v1/services_catalogue?id=eq.$srvId';
      await http.patch(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: utf8.encode(jsonEncode({'est_actif': newStatus})),
      );

      _syncToCmsConfig();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'Service activé sur le site public.' : 'Service masqué du site public.'),
          backgroundColor: newStatus ? AppConfig.successGreen : Colors.orange,
        ),
      );
    } catch (e) {
      setState(() {
        srv['est_actif'] = currentStatus;
      });
    }
  }

  Future<void> _deleteService(Map<String, dynamic> srv) async {
    final srvId = srv['id'];
    final srvTitre = srv['titre'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce service'),
        content: Text('Voulez-vous supprimer définitivement "$srvTitre" du catalogue officiel ?'),
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

    if (confirm != true) return;

    try {
      final url = '${AppConfig.supabaseUrl}/rest/v1/services_catalogue?id=eq.$srvId';
      await http.delete(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      );
      setState(() {
        _services.removeWhere((s) => s['id'] == srvId);
      });
      _syncToCmsConfig();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service supprimé avec succès.'), backgroundColor: AppConfig.dangerRed),
        );
      }
    } catch (_) {}
  }

  void _showEditServiceDialog([Map<String, dynamic>? srv]) {
    final isEdit = srv != null;
    final titleCtrl = TextEditingController(text: srv?['titre'] ?? '');
    final catCtrl = TextEditingController(text: srv?['categorie'] ?? 'Mines & Industrie');
    final codeCtrl = TextEditingController(text: srv?['code_service'] ?? 'SRV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final descShortCtrl = TextEditingController(text: srv?['description_courte'] ?? '');
    final descFullCtrl = TextEditingController(text: srv?['description_complete'] ?? '');
    final tarifCtrl = TextEditingController(text: srv?['tarification_indicative'] ?? 'Sur devis');
    final certCtrl = TextEditingController(text: srv?['certifications'] ?? 'Standards ARSP & QHSE');
    final delaiCtrl = TextEditingController(text: srv?['delai_mobilisation'] ?? 'Mobilisation sous 24 à 48 heures');
    final ordreCtrl = TextEditingController(text: (srv?['ordre_affichage'] ?? (_services.length + 1)).toString());

    // Livrables / Points forts
    String initialFeatures = '';
    if (srv?['points_forts'] != null) {
      if (srv!['points_forts'] is List) {
        initialFeatures = (srv['points_forts'] as List).join('\n');
      } else {
        initialFeatures = srv['points_forts'].toString();
      }
    }
    final pointsCtrl = TextEditingController(text: initialFeatures);

    // Média / Image
    String mediaMode = 'url';
    final urlCtrl = TextEditingController(text: srv?['image_url'] ?? '');
    bool isUploading = false;
    bool isActive = srv?['est_actif'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Row(
            children: [
              Icon(isEdit ? Icons.edit_note : Icons.add_business, color: AppConfig.brandPink),
              const SizedBox(width: 8),
              Text(isEdit ? 'Modifier la Prestation Officielle' : 'Ajouter une Nouvelle Prestation'),
            ],
          ),
          content: SizedBox(
            width: 680,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Les modifications sont encodées en UTF-8 propre et répercutées instantanément sur la page Services du site web.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Titre & Code
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Titre de la Prestation *',
                            hintText: 'ex: Sous-Traitance Minière & Extraction',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: codeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Code *',
                            hintText: 'ex: SRV-01',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: ordreCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Ordre',
                            hintText: '1..15',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Catégorie
                  DropdownButtonFormField<String>(
                    value: _categories.contains(catCtrl.text) && catCtrl.text != 'toutes'
                        ? catCtrl.text
                        : 'Mines & Industrie',
                    decoration: const InputDecoration(labelText: 'Catégorie Opérationnelle *'),
                    items: _categories
                        .where((c) => c != 'toutes')
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDlgState(() => catCtrl.text = v);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Description courte (résumé vitrine)
                  TextField(
                    controller: descShortCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description Courte / Résumé (Carte Vitrine) *',
                      hintText: 'Accroche claire visible directement sur la grille des cartes...',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description détaillée (Drawer latéral)
                  TextField(
                    controller: descFullCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description Technique Complète (Bande Coulissante) *',
                      hintText: 'Périmètre d\'intervention complet, méthodologie et engagements...',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Livrables clés & Points forts
                  TextField(
                    controller: pointsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Points Forts & Livrables Clés (1 par ligne) *',
                      hintText: "Opérateurs certifiés\nSupervision HSE continue\nContrôle qualité laboratoire",
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Certifications & Délais
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: certCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Normes & Certifications',
                            hintText: 'ex: Agrément ARSP, ISO 45001, HACCP',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: delaiCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Délai de Mobilisation',
                            hintText: 'ex: Mobilisation sous 24 à 48 heures',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tarification
                  TextField(
                    controller: tarifCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tarification Indicative / Conditions',
                      hintText: 'ex: Sur devis personnalisé / Contrat cadre mensuel',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Source d'image : URL vs Upload
                  const Text('Image / Visuel de la Prestation :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'url', label: Text('Lien Image CDN / Web'), icon: Icon(Icons.link, size: 16)),
                      ButtonSegment(value: 'upload', label: Text('Upload Fichier (PC/Mobile)'), icon: Icon(Icons.upload_file, size: 16)),
                    ],
                    selected: {mediaMode},
                    onSelectionChanged: (set) => setDlgState(() => mediaMode = set.first),
                  ),
                  const SizedBox(height: 10),

                  if (mediaMode == 'url')
                    TextField(
                      controller: urlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL de l\'image (PNG, JPG, WebP)',
                        hintText: 'https://jbf-service.com/assets/services/catering.jpg',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                    )
                  else
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  setDlgState(() => isUploading = true);
                                  final picked = await FilePickerHelper.pickFile(
                                    title: 'Choisir une image pour la prestation',
                                    filter: 'Images (*.png;*.jpg;*.jpeg;*.webp)|*.png;*.jpg;*.jpeg;*.webp|Tous (*.*)|*.*',
                                  );
                                  if (picked != null) {
                                    final uploaded = await FilePickerHelper.uploadToSupabase(
                                      file: picked,
                                      bucket: 'galerie',
                                    );
                                    if (uploaded != null) {
                                      urlCtrl.text = uploaded;
                                    } else {
                                      urlCtrl.text = picked.path;
                                    }
                                  }
                                  setDlgState(() => isUploading = false);
                                },
                          icon: isUploading
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.folder_open, size: 16),
                          label: Text(isUploading ? 'Téléversement...' : 'Parcourir mon PC...'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            urlCtrl.text.isEmpty ? 'Aucun fichier sélectionné' : urlCtrl.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Prestation Active & Visible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: const Text('Désactivez pour masquer immédiatement cette prestation sur le site public.'),
                    value: isActive,
                    activeColor: AppConfig.brandPink,
                    onChanged: (v) => setDlgState(() => isActive = v),
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
                if (titleCtrl.text.trim().isEmpty || descShortCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez renseigner au moins le titre et la description courte.')),
                  );
                  return;
                }

                Navigator.of(ctx).pop();

                final List<String> featuresList = pointsCtrl.text
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final int ordre = int.tryParse(ordreCtrl.text.trim()) ?? 1;

                final Map<String, dynamic> payload = {
                  'code_service': codeCtrl.text.trim(),
                  'titre': titleCtrl.text.trim(),
                  'categorie': catCtrl.text.trim(),
                  'description_courte': descShortCtrl.text.trim(),
                  'description_complete': descFullCtrl.text.trim(),
                  'points_forts': featuresList.join('\n'),
                  'certifications': certCtrl.text.trim(),
                  'delai_mobilisation': delaiCtrl.text.trim(),
                  'tarification_indicative': tarifCtrl.text.trim(),
                  'image_url': urlCtrl.text.trim(),
                  'ordre_affichage': ordre,
                  'est_actif': isActive,
                  'updated_at': DateTime.now().toIso8601String(),
                };

                try {
                  if (isEdit) {
                    final srvId = srv['id'];
                    await http.patch(
                      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/services_catalogue?id=eq.$srvId'),
                      headers: {
                        'apikey': AppConfig.supabaseAnonKey,
                        'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                        'Content-Type': 'application/json; charset=utf-8',
                      },
                      body: utf8.encode(jsonEncode(payload)),
                    );
                  } else {
                    await http.post(
                      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/services_catalogue'),
                      headers: {
                        'apikey': AppConfig.supabaseAnonKey,
                        'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                        'Content-Type': 'application/json; charset=utf-8',
                      },
                      body: utf8.encode(jsonEncode(payload)),
                    );
                  }

                  await _loadServices();
                  await _syncToCmsConfig();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Prestation mise à jour et synchronisée avec le site !' : 'Nouvelle prestation ajoutée au catalogue !'),
                        backgroundColor: AppConfig.successGreen,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Erreur sauvegarde service: $e');
                }
              },
              child: Text(isEdit ? 'Enregistrer les modifications' : 'Créer la prestation'),
            ),
          ],
        ),
      ),
    );
  }

  // Initialisation complète des 15 services officiels JBF en UTF-8 propre
  Future<void> _restoreOfficialServices() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurer les 15 Prestations Officielles'),
        content: const Text(
          'Cette action va injecter ou réinitialiser l\'ensemble des 15 prestations officielles de JBF Service avec leurs descriptions techniques complètes, normes QHSE et livrables en UTF-8 propre.\n\nVoulez-vous continuer ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmer la Restauration'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSeeding = true);

    final List<Map<String, dynamic>> officialSeeds = [
      {
        'code_service': 'SRV-01',
        'titre': 'Alimentaire & Catering de Chantier',
        'categorie': 'Alimentaire',
        'description_courte': 'Restauration collective, gestion de cantines et conformité HACCP stricte.',
        'description_complete': "Prise en charge intégrale de la chaîne alimentaire pour bases de vie industrielles, camps miniers et événements professionnels en RDC. JBF Service assure l'approvisionnement en circuit court, la conservation sous chaîne de froid contrôlée et la préparation de menus équilibrés adaptés aux exigences caloriques des équipes de terrain.",
        'points_forts': "Production et service de repas chauds 24/7 (3 services par jour)\nGestion d'économats, chaîne du froid et traçabilité des denrées\nÉquipes de chefs formés aux standards internationaux HACCP\nApprovisionnement sécurisé en zones isolées et camps miniers",
        'certifications': 'Normes HACCP & Standards Sanitaires Internationaux',
        'delai_mobilisation': 'Mobilisation sous 24 à 48 heures',
        'tarification_indicative': 'Sur devis par convive / jour',
        'ordre_affichage': 1,
        'est_actif': true,
      },
      {
        'code_service': 'SRV-02',
        'titre': 'Sous-Traitance Minière & Extraction',
        'categorie': 'Mines & Industrie',
        'description_courte': "Main-d'œuvre qualifiée, extraction, convoyage et sécurité minière.",
        'description_complete': "Accompagnement opérationnel des compagnies minières dans les provinces du Haut-Katanga et du Lualaba. En conformité intégrale avec la loi ARSP, JBF Service déploie des opérateurs d'engins lourds certifiés, des techniciens d'extraction, des équipes de gestion de fosse et des spécialistes en concassage pour maximiser vos rendements.",
        'points_forts': "Opérateurs d'engins miniers certifiés (dumpers, pelles, chargeuses)\nSupervision HSE de chantier et prévention des risques d'accident\nÉquipes d'échantillonnage, concassage et contrôle qualité minerai\nConformité intégrale à la loi sur la sous-traitance privée (ARSP)",
        'certifications': 'Agrément ARSP & Certification HSE Mines',
        'delai_mobilisation': "Déploiement d'équipes sous 48 heures",
        'tarification_indicative': 'Au mètre cube extrait ou régie horaire',
        'ordre_affichage': 2,
        'est_actif': true,
      },
      {
        'code_service': 'SRV-03',
        'titre': 'BTP, Génie Civil & Construction',
        'categorie': 'Construction',
        'description_courte': 'Terrassement, gros œuvre, voiries et bâtiments industriels.',
        'description_complete': "Ingénierie, étude technique et réalisation d'infrastructures de génie civil lourd, plateformes logistiques, voiries de circulation et bâtiments administratifs ou industriels. Supervision de l'intégralité du cycle de construction, depuis le terrassement jusqu'à l'édification de charpentes métalliques.",
        'points_forts': "Travaux de terrassement, nivellement et stabilisation de sols\nCoulage de dalles béton armé et fondations industrielles lourdes\nConstruction de hangars métalliques et entrepôts de stockage\nAménagement de voiries intérieures et réseaux d'évacuation pluviale",
        'certifications': 'Normes Eurocodes & Cahiers des charges BTP',
        'delai_mobilisation': 'Étude sous 24h / Début travaux sous 3 jours',
        'tarification_indicative': 'Bordereau de prix unitaires (BPU) / Forfait',
        'ordre_affichage': 3,
        'est_actif': true,
      },
      {
        'code_service': 'SRV-04',
        'titre': 'Maintenance Industrielle & Soudure',
        'categorie': 'Maintenance',
        'description_courte': 'Soudure haute pression, tuyauterie industrielle et maintenance mécanique.',
        'description_complete': "Interventions curatives d'urgence et contrats annuels de maintenance préventive pour usines hydrométallurgiques, cimenteries et installations minières. Soudeurs et tuyauteurs homologués sur conduites haute pression, broyeurs, convoyeurs et circuits de fluides.",
        'points_forts': "Soudeurs homologués TIG/MIG/Arc sur conduites haute pression\nMaintenance préventive de broyeurs, convoyeurs et pompes\nUsinage, rectification de pièces mécaniques et chaudronnerie\nDiagnostics vibratoires et thermographiques sur équipements tournants",
        'certifications': 'Homologation Soudeurs ASME / ISO 9606',
        'delai_mobilisation': "Équipe d'urgence disponible sous 12 heures",
        'tarification_indicative': 'Taux horaire technicien / Forfait arrêt d\'usine',
        'ordre_affichage': 4,
        'est_actif': true,
      },
      {
        'code_service': 'SRV-05',
        'titre': 'Gardiennage, Sécurité Physique & Surveillance',
        'categorie': 'Sécurité',
        'description_courte': "Agents de sécurité formés, contrôle d'accès et sécurisation périmétrique.",
        'description_complete': "Dispositif complet de protection des installations critiques, sites miniers, entrepôts logistiques et résidences d'entreprise. Surveillance continue 24/7 appuyée par des brigades cynophiles et des rondes informatisées avec traçabilité GPS.",
        'points_forts': "Agents de sécurité formés aux protocoles de dissuasion et filtrage\nContrôle d'accès par badges électroniques et registres informatisés\nMaîtres-chiens et patrouilles mobiles de surveillance nocturne\nCoordination directe avec les forces de sécurité et secours",
        'certifications': 'Agrément Ministère de l\'Intérieur RDC',
        'delai_mobilisation': 'Postes pourvus sous 24 heures',
        'tarification_indicative': 'Facturation mensuelle par agent posté',
        'ordre_affichage': 5,
        'est_actif': true,
      },
      {
        'code_service': 'SRV-06',
        'titre': 'Nettoyage Industriel, Décontamination & Housekeeping',
        'categorie': 'Maintenance',
        'description_courte': 'Nettoyage haute pression, assainissement et entretien de bases de vie.',
        'description_complete': "Prestations spécialisées de nettoyage technique lourd, dégraissage haute pression d'ateliers de maintenance, entretien hôtelier rigoureux (housekeeping) et désinfection globale avec des produits biodégradables certifiés.",
        'points_forts': "Nettoyage et dégraissage haute pression de sols et machines\nEntretien hôtelier (housekeeping) et blanchisserie industrielle\nGestion des déchets, tri sélectif et évacuation conforme\nDératisation, désinsectisation et désinfection sanitaire périodique",
        'certifications': 'Protocoles d\'hygiène hospitalière et industrielle',
        'delai_mobilisation': 'Mise en place d\'équipes sous 24 heures',
        'tarification_indicative': 'Au mètre carré ou contrat mensuel',
        'ordre_affichage': 6,
        'est_actif': true,
      },
      {
        'code_service': 'SRV-07',
        'titre': 'Logistique, Fret & Transport Dédié',
        'categorie': 'Logistique',
        'description_courte': 'Flotte de camions, acheminement sécurisé et traçabilité GPS en RDC.',
        'description_complete': "Acheminement fiable et sécurisé de fret volumineux, d'équipements de chantier, de réactifs miniers et de produits alimentaires sur l'ensemble des 26 provinces. Chaque convoi dispose d'un suivi télématique par satellite en temps réel.",
        'points_forts': "Flotte de camions plateaux, bennes et fourgons frigorifiques\nSystème de géolocalisation GPS en temps réel pour chaque convoi\nGestion des formalités douanières et autorisations de transport\nEscorte sécurisée pour le fret à haute valeur ajoutée",
        'certifications': 'Assurance fret marchandise & Chauffeurs défensifs',
        'delai_mobilisation': 'Planning de chargement sous 24 heures',
        'tarification_indicative': 'À la tonne-kilomètre ou affrètement direct',
        'ordre_affichage': 7,
        'est_actif': true,
      },
      {
        'code_service': 'SRV-08',
        'titre': 'Gestion Intégrale de Bases de Vie & Camps',
        'categorie': 'Services Généraux',
        'description_courte': 'Facilities management complet pour camps miniers et chantiers isolés.',
        'description_complete': "Administration et maintenance multi-technique clé en main de camps de vie hébergeant de 50 à plus de 2 500 résidents. Hébergement, conciergerie, approvisionnement en eau potable, traitement des eaux usées et distribution électrique.",
        'points_forts': "Administration générale et conciergerie des hébergements\nMaintenance multi-technique des modules de vie\nAlimentation autonome en eau potable et gestion des eaux usées\nAnimations, espaces sportifs et bien-être des résidents",
        'certifications': 'Standards Internationaux de Camp Management',
        'delai_mobilisation': 'Audit et reprise de camp sous 7 jours',
        'tarification_indicative': 'Forfait mensuel global par résident',
        'ordre_affichage': 8,
        'est_actif': true,
      },
      {
        'code_service': 'SRV-09',
        'titre': 'Mise à Disposition de Main-d\'œuvre & Régie',
        'categorie': 'Services Généraux',
        'description_courte': 'Fourniture de personnel technique et ouvriers qualifiés en régie.',
        'description_complete': "Délégation agile de personnel opérationnel et technique pour absorber vos pics d'activité industrielle. JBF Service prend en charge l'ensemble du cycle contractuel, de la couverture sociale (CNSS), des visites médicales et du transport journalier.",
        'points_forts': "Manœuvres qualifiés, électriciens, coffreurs, maçons et ferrailleurs\nGestion administrative complète (contrats, CNSS, paie, transport)\nVisites médicales préalables et tests d'aptitude professionnelle\nRemplacement immédiat en cas d'absence ou d'indisponibilité",
        'certifications': 'Conformité Code du Travail & ONEM RDC',
        'delai_mobilisation': 'Sélection et déploiement sous 48 heures',
        'tarification_indicative': 'Taux journalier selon classification salariale',
        'ordre_affichage': 9,
        'est_actif': true,
      },
      {
        'code_service': 'SRV-10',
        'titre': 'Fourniture d\'Équipements de Protection (EPI)',
        'categorie': 'Mines & Industrie',
        'description_courte': 'Équipements de sécurité certifiés CE/ANSI pour sites à risques.',
        'description_complete': "Sélection, importation et livraison sur site d'équipements de protection individuelle certifiés selon les standards européens CE et américains ANSI. Protection contre les risques mécaniques, thermiques, chimiques et électriques.",
        'points_forts': "Casques de sécurité, lunettes balistiques, gants anticoupure\nChaussures de sécurité coquées S3 et bottes anti-perforation\nTenues haute visibilité ignifugées et combinaisons de travail\nHarnais de sécurité, masques respiratoires et protections auditives",
        'certifications': 'Certifications européennes CE & américaines ANSI',
        'delai_mobilisation': 'Livraison sur stock sous 24 à 48 heures',
        'tarification_indicative': 'Catalogue tarifaire unitaire avec remise volume',
        'ordre_affichage': 10,
        'est_actif': true,
      },
      {
        'code_service': 'SRV-11',
        'titre': 'Location & Maintenance d\'Engins de Chantier',
        'categorie': 'Construction',
        'description_courte': 'Grues, compacteurs, pelles, générateurs et outillage lourd.',
        'description_complete': "Parc d'engins récents de génie civil et de terrassement disponibles en location courte ou longue durée, avec ou sans mécaniciens-opérateurs certifiés. Suivi télématique et programme d'entretien préventif garantissant un taux de disponibilité supérieur à 95%.",
        'points_forts': "Pelles hydrauliques de 20t à 50t, chargeuses et bulldozers\nNiveleuses, rouleaux compacteurs et camions bennes 6x4 et 8x4\nContrat de maintenance préventive et mécanicien dédié sur site\nRemplacement immédiat de l'engin en cas de panne majeure",
        'certifications': 'Contrôles techniques périodiques à jour',
        'delai_mobilisation': 'Mise à disposition sous 48 heures',
        'tarification_indicative': 'Tarif journalier ou mensuel hors carburant',
        'ordre_affichage': 11,
        'est_actif': true,
      },
      {
        'code_service': 'SRV-12',
        'titre': 'Services Informatiques & Réseaux Télécoms',
        'categorie': 'Services Généraux',
        'description_courte': 'Câblage réseau, vidéosurveillance IP, serveurs et télécoms.',
        'description_complete': "Conception, installation et infogérance d'infrastructures informatiques résilientes pour sièges d'entreprise et sites miniers enclavés. Liaisons fibres optiques, faisceaux hertziens, réseaux Wi-Fi industriels, serveurs locaux et vidéosurveillance intelligente.",
        'points_forts': "Déploiement de réseaux locaux (LAN/Wi-Fi professionnel)\nInstallation de caméras IP haute résolution et serveurs NVR\nMaintenance de parcs informatiques, imprimantes et onduleurs\nLiaisons sécurisées VPN et solutions de connectivité satellite",
        'certifications': 'Standards Réseaux & Cybersécurité',
        'delai_mobilisation': 'Intervention sous 24 heures ouvrables',
        'tarification_indicative': 'Forfait infogérance mensuelle ou prestation projet',
        'ordre_affichage': 12,
        'est_actif': true,
      },
      {
        'code_service': 'SRV-13',
        'titre': 'Gestion des Ressources Humaines & Recrutement',
        'categorie': 'Services Généraux',
        'description_courte': 'Chasse de talents, gestion de paie et conformité droit du travail.',
        'description_complete': "Cabinet de recrutement spécialisé dans les métiers techniques, l'ingénierie et le management industriel en RDC. Sourcing de talents, évaluation des compétences, paie externalisée et sécurisation juridique des contrats.",
        'points_forts': "Sourcing et sélection rigoureuse de profils techniques et tertiaires\nGestion complète des contrats de travail, déclarations CNSS et fiscalité\nContrôle médical d'embauche et formation sécurité d'accueil\nSuivi rigoureux des présences et feuilles de temps certifiées",
        'certifications': 'Conformité Code du Travail RDC & ONEM',
        'delai_mobilisation': 'Présélection de profils sous 48 à 72 heures',
        'tarification_indicative': 'Pourcentage de la masse salariale brute',
        'ordre_affichage': 13,
        'est_actif': true,
      },
      {
        'code_service': 'SRV-14',
        'titre': 'Aménagement Paysager & Espaces Verts',
        'categorie': 'Services Généraux',
        'description_courte': 'Entretien d\'espaces verts, reboisement et réhabilitation écologique.',
        'description_complete': "Création, requalification et entretien régulier d'espaces verts, pelouses industrielles et périmètres de sécurité sur sites tertiaires et miniers. Végétalisation de terrils et réhabilitation écologique post-exploitation.",
        'points_forts': "Tonte, désherbage et entretien régulier des pelouses et massifs\nPlantation d'arbres d'alignement et haies de clôture naturelle\nSystèmes d'arrosage automatique et fertilisation raisonnée\nNettoyage et défrichage de pare-feux et zones tampons",
        'certifications': 'Pratiques écologiques et durables',
        'delai_mobilisation': 'Intervention programmée sous 48 heures',
        'tarification_indicative': 'Forfait mensuel selon superficie en hectares',
        'ordre_affichage': 14,
        'est_actif': true,
      },
      {
        'code_service': 'SRV-15',
        'titre': 'Installation Électrique & Énergies Renouvelables',
        'categorie': 'Construction',
        'description_courte': 'Électricité industrielle, groupes électrogènes et centrales solaires.',
        'description_complete': "Ingénierie électrotechnique pour environnements industriels et sites hors-réseau en RDC. Raccordement et maintenance de tableaux de distribution basse et moyenne tension, armoires d'inverseurs automatiques, générateurs industriels et parcs solaires photovoltaïques hybrides.",
        'points_forts': "Pose de tableaux électriques industriels et armoires d'inverseurs\nInstallation et maintenance de groupes électrogènes forte puissance\nSystèmes solaires photovoltaïques avec stockage batteries lithium\nContrôles de conformité et mise à la terre sécurisée des installations",
        'certifications': 'Normes de sécurité électrique NF C 15-100',
        'delai_mobilisation': 'Diagnostic et début de travaux sous 48 heures',
        'tarification_indicative': 'Devis d\'ingénierie selon puissance KVA installée',
        'ordre_affichage': 15,
        'est_actif': true,
      },
    ];

    try {
      for (final srv in officialSeeds) {
        await http.post(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/services_catalogue?on_conflict=code_service'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
            'Content-Type': 'application/json; charset=utf-8',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: utf8.encode(jsonEncode(srv)),
        );
      }
      await _loadServices();
      await _syncToCmsConfig();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les 15 prestations officielles ont été restaurées et synchronisées en UTF-8 propre !'),
            backgroundColor: AppConfig.successGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur restauration services: $e');
    }

    if (mounted) setState(() => _isSeeding = false);
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = _services.where((s) {
      final matchesCat = _filterCategorie == 'toutes' ||
          (s['categorie']?.toString().toLowerCase() == _filterCategorie.toLowerCase());
      final matchesSearch = _searchQuery.isEmpty ||
          (s['titre']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true) ||
          (s['code_service']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true) ||
          (s['description_courte']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) == true);
      return matchesCat && matchesSearch;
    }).toList();

    final int totalCount = _services.length;
    final int activeCount = _services.where((s) => s['est_actif'] == true).length;

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
                      Row(
                        children: [
                          const Text(
                            'Catalogue Dynamique des Services JBF',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppConfig.brandPinkTint, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              '$activeCount / $totalCount actifs',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConfig.brandPink),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Modifiez les 15 prestations en UTF-8 propre avec prise en charge d\'images, livrables, certifications et tarifs.',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isSeeding ? null : _restoreOfficialServices,
                  icon: _isSeeding
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.restore, size: 18),
                  label: Text(_isSeeding ? 'Restauration...' : 'Restaurer les 15 Prestations'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConfig.blackText,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _showEditServiceDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.brandPink,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher une prestation, mot-clé, code...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSel = _filterCategorie == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(cat == 'toutes' ? 'Toutes les catégories' : cat),
                            selected: isSel,
                            selectedColor: AppConfig.brandPinkTint,
                            checkmarkColor: AppConfig.brandPink,
                            labelStyle: TextStyle(
                              color: isSel ? AppConfig.brandPink : Colors.grey.shade700,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) => setState(() => _filterCategorie = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Services Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
                : filteredServices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.layers_clear_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Aucune prestation trouvée.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            const Text('Cliquez ci-dessous pour charger immédiatement les 15 prestations officielles de JBF Service.', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _restoreOfficialServices,
                              icon: const Icon(Icons.download),
                              label: const Text('Charger les 15 Prestations Officielles'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: filteredServices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final s = filteredServices[index];
                          final bool isActif = s['est_actif'] == true;
                          final code = s['code_service'] ?? 'SRV';
                          final titre = s['titre'] ?? 'Service JBF';
                          final cat = s['categorie'] ?? 'Industrie';
                          final desc = s['description_courte'] ?? '';
                          final tarif = s['tarification_indicative'] ?? 'Sur devis';
                          final cert = s['certifications'] ?? 'Standards ARSP';
                          final delai = s['delai_mobilisation'] ?? 'Sous 24h';
                          final imgUrl = s['image_url']?.toString() ?? '';

                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActif ? Colors.grey.shade200 : const Color(0xFFFCA5A5),
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail or Icon
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: isActif ? AppConfig.brandPinkTint : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                    image: imgUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(imgUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: imgUrl.isEmpty
                                      ? Center(
                                          child: Icon(
                                            Icons.handyman_outlined,
                                            color: isActif ? AppConfig.brandPink : Colors.grey.shade500,
                                            size: 26,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),

                                // Main Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            titre,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isActif ? AppConfig.blackText : Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              code,
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              cat,
                                              style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        desc,
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 14,
                                        runSpacing: 4,
                                        children: [
                                          Text(
                                            'Tarif : $tarif',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                                          ),
                                          Text(
                                            'Certif : $cert',
                                            style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                                          ),
                                          Text(
                                            'Délai : $delai',
                                            style: TextStyle(fontSize: 12, color: Colors.purple.shade700),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Action Buttons
                                Row(
                                  children: [
                                    Switch(
                                      value: isActif,
                                      activeColor: AppConfig.brandPink,
                                      onChanged: (_) => _toggleServiceActive(s),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                      tooltip: 'Modifier toutes les données',
                                      onPressed: () => _showEditServiceDialog(s),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppConfig.dangerRed),
                                      tooltip: 'Supprimer du catalogue',
                                      onPressed: () => _deleteService(s),
                                    ),
                                  ],
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
}
