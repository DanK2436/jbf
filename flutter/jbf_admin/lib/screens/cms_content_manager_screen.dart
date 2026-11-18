import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class CustomCmsElement {
  final String id;
  String type; // 'texte', 'image_background', 'champ_formulaire', 'section', 'contact'
  String key;
  String label;
  String value;
  String targetPlatform; // 'Web Public', 'App Client', 'App Membre', 'Tous'
  bool isActive;

  CustomCmsElement({
    required this.id,
    required this.type,
    required this.key,
    required this.label,
    required this.value,
    this.targetPlatform = 'Tous',
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'key': key,
        'label': label,
        'value': value,
        'targetPlatform': targetPlatform,
        'isActive': isActive,
      };

  factory CustomCmsElement.fromJson(Map<String, dynamic> j) => CustomCmsElement(
        id: j['id']?.toString() ?? '',
        type: j['type'] ?? 'texte',
        key: j['key'] ?? '',
        label: j['label'] ?? '',
        value: j['value'] ?? '',
        targetPlatform: j['targetPlatform'] ?? 'Tous',
        isActive: j['isActive'] == null ? true : (j['isActive'] == true),
      );
}

class FaqItemModel {
  String id;
  String question;
  String reponse;
  String categorie;
  int ordreAffichage;
  bool estActif;

  FaqItemModel({
    required this.id,
    required this.question,
    required this.reponse,
    required this.categorie,
    this.ordreAffichage = 1,
    this.estActif = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'reponse': reponse,
        'categorie': categorie,
        'ordre_affichage': ordreAffichage,
        'est_actif': estActif,
      };

  factory FaqItemModel.fromJson(Map<String, dynamic> j) => FaqItemModel(
        id: j['id']?.toString() ?? 'faq_${DateTime.now().millisecondsSinceEpoch}',
        question: j['question']?.toString() ?? '',
        reponse: j['reponse']?.toString() ?? '',
        categorie: j['categorie']?.toString() ?? 'general',
        ordreAffichage: (j['ordre_affichage'] is int)
            ? j['ordre_affichage']
            : int.tryParse(j['ordre_affichage']?.toString() ?? '1') ?? 1,
        estActif: j['est_actif'] == null ? true : (j['est_actif'] == true),
      );
}

class CmsContentManagerScreen extends StatefulWidget {
  const CmsContentManagerScreen({super.key});

  @override
  State<CmsContentManagerScreen> createState() => _CmsContentManagerScreenState();
}

class _CmsContentManagerScreenState extends State<CmsContentManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaving = false;

  // Contacts
  final _phoneWhatsappCtrl = TextEditingController(text: '+243 970 349 724');
  final _phoneAppelsCtrl = TextEditingController(text: '+243 822 357 053');
  final _emailOfficielCtrl = TextEditingController(text: 'dankande3@gmail.com');
  final _adresseSiegeCtrl = TextEditingController(text: 'Lubumbashi, Haut-Katanga, RDC');

  // Textes & Slogans
  final _titreHeroCtrl = TextEditingController(text: 'Leader Multi-Services & Sous-Traitance Agréée ARSP en RDC');
  final _sousTitreHeroCtrl = TextEditingController(text: 'Mines & Extraction • BTP & Génie Civil • Catering Industriel HACCP');

  // Toggles natifs de Sections & Pages
  final Map<String, bool> _sectionToggles = {
    'hero_3d_experience': true,
    'banniere_recrutement': true,
    'section_15_services': true,
    'section_temoignages_avis': true,
    'section_actualites_blog': true,
    'section_galerie_photos': true,
    'formulaire_devis_public': true,
    'page_carrieres_active': true,
    'module_chat_direct_client': true,
    'module_devis_membres': true,
    'validation_strict_fichiers_cv': true,
  };

  final Map<String, String> _sectionLabels = {
    'hero_3d_experience': 'Expérience WebGL 3D & Cristaux Miniers (Page d\'accueil)',
    'banniere_recrutement': 'Bandeau & Campagne de Recrutement Public',
    'section_15_services': 'Grille & Catalogue des 15 Pôles de Services JBF',
    'section_temoignages_avis': 'Section des Avis & Témoignages Clients vérifiés',
    'section_actualites_blog': 'Fil d\'actualités économiques et minières (Blog)',
    'section_galerie_photos': 'Galerie des réalisations chantiers & vidéos',
    'formulaire_devis_public': 'Formulaire de demande de cotation / devis express',
    'page_carrieres_active': 'Page Carrières & Dépôt des candidatures sans compte',
    'module_chat_direct_client': 'Messagerie et Live Chat sur le portail client',
    'module_devis_membres': 'Module de chiffrage terrain et matériaux membres',
    'validation_strict_fichiers_cv': 'Obligation stricte du CV PDF pour postuler',
  };

  // Liste des Éléments CMS Dynamiques créés par l'admin
  List<CustomCmsElement> _customElements = [];

  // FAQ Dynamique
  List<FaqItemModel> _faqItems = [];
  String _faqSearch = '';
  String _faqCategoryFilter = 'toutes';

  static const Map<String, String> _faqCategoryLabels = {
    'toutes': 'Toutes les catégories',
    'devis': 'Devis & Tarification',
    'terrain': 'Déploiement & 26 Provinces',
    'hse': 'Loi ARSP & Normes QHSE',
    'organisation': 'Organisation & Encadrement',
    'general': 'Général & Sous-traitance',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCmsConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneWhatsappCtrl.dispose();
    _phoneAppelsCtrl.dispose();
    _emailOfficielCtrl.dispose();
    _adresseSiegeCtrl.dispose();
    _titreHeroCtrl.dispose();
    _sousTitreHeroCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCmsConfig() async {
    setState(() => _isLoading = true);

    // 1. Charger depuis le cache local persistant
    try {
      final prefs = await SharedPreferences.getInstance();
      final customJson = prefs.getString('JBF_CMS_CUSTOM_ELEMENTS');
      if (customJson != null) {
        final List<dynamic> dec = jsonDecode(customJson);
        _customElements = dec.map((e) => CustomCmsElement.fromJson(e)).toList();
      }
      final faqJson = prefs.getString('JBF_CMS_FAQ_ITEMS');
      if (faqJson != null) {
        final List<dynamic> dec = jsonDecode(faqJson);
        _faqItems = dec.map((e) => FaqItemModel.fromJson(e)).toList();
      }
    } catch (_) {}

    // 2. Charger depuis Supabase (config_cles_api) en UTF-8 strict
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/config_cles_api?select=*'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final utf8Str = utf8.decode(res.bodyBytes);
        final List<dynamic> list = jsonDecode(utf8Str);
        for (var row in list) {
          final cle = row['cle_nom']?.toString();
          final val = row['cle_valeur']?.toString();
          if (cle != null && val != null) {
            if (_sectionToggles.containsKey(cle)) {
              _sectionToggles[cle] = val == 'true' || val == '1';
            } else if (cle == 'contact_whatsapp') {
              _phoneWhatsappCtrl.text = val;
            } else if (cle == 'contact_appels') {
              _phoneAppelsCtrl.text = val;
            } else if (cle == 'contact_email') {
              _emailOfficielCtrl.text = val;
            } else if (cle == 'contact_adresse') {
              _adresseSiegeCtrl.text = val;
            } else if (cle == 'titre_hero_principal') {
              _titreHeroCtrl.text = val;
            } else if (cle == 'soustitre_hero_principal') {
              _sousTitreHeroCtrl.text = val;
            } else if (cle == 'cms_custom_elements_json') {
              try {
                final List<dynamic> dec = jsonDecode(val);
                _customElements = dec.map((e) => CustomCmsElement.fromJson(e)).toList();
              } catch (_) {}
            } else if (cle == 'cms_faq_items_json' && _faqItems.isEmpty) {
              try {
                final List<dynamic> dec = jsonDecode(val);
                _faqItems = dec.map((e) => FaqItemModel.fromJson(e)).toList();
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}

    // 3. Charger depuis table faq_items de Supabase si disponible
    try {
      final faqRes = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/faq_items?select=*&order=ordre_affichage.asc'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 4));

      if (faqRes.statusCode == 200) {
        final utf8Faq = utf8.decode(faqRes.bodyBytes);
        final List<dynamic> dbFaq = jsonDecode(utf8Faq);
        if (dbFaq.isNotEmpty) {
          _faqItems = dbFaq.map((e) => FaqItemModel.fromJson(e)).toList();
        }
      }
    } catch (_) {}

    // 4. Si la FAQ est encore vide, peupler par défaut avec les 12 questions officielles
    if (_faqItems.isEmpty) {
      _faqItems = _getOfficialDefaultFaq();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  List<FaqItemModel> _getOfficialDefaultFaq() {
    return [
      FaqItemModel(
        id: 'faq_1',
        categorie: 'devis',
        ordreAffichage: 1,
        question: "Quel est le délai de transmission d'un devis commercial chiffré ?",
        reponse: "Toute demande de cotation soumise via notre site web ou par courriel officiel fait l'objet d'un accusé de réception immédiat.\nNos ingénieurs d'affaires et métreurs vous transmettent une proposition technique et financière détaillée sous un délai garanti de 24 heures ouvrables pour les demandes courantes (gardiennage, catering, mise à disposition de main-d'œuvre) et sous 48 heures pour les chantiers complexes de génie civil ou de maintenance d'usine nécessitant une étude d'ingénierie préliminaire.",
      ),
      FaqItemModel(
        id: 'faq_2',
        categorie: 'devis',
        ordreAffichage: 2,
        question: "Quelles sont vos modalités de facturation et devises acceptées ?",
        reponse: "Nos conditions de règlement sont parfaitement adaptées aux standards industriels et miniers :\n- Contrats récurrents (catering, gardiennage, maintenance) : Facturation mensuelle à terme échu sur la base des états de présence ou situations de travaux validées.\n- Missions ponctuelles (BTP, arrêts d'usines, convoyage) : Acompte de mobilisation (30% à 50%) puis solde à réception définitive des livrables.\nLes paiements sont acceptés par virement bancaire sécurisé en USD ou en Francs Congolais (CDF) sur nos comptes bancaires d'entreprise domiciliés en RDC.",
      ),
      FaqItemModel(
        id: 'faq_3',
        categorie: 'devis',
        ordreAffichage: 3,
        question: "Proposez-vous des contrats-cadres pluriannuels avec des remises de volume ?",
        reponse: "Oui. Pour les grands donneurs d'ordres industriels et miniers engageant des volumes réguliers ou combinant plusieurs de nos 15 prestations (ex: Gestion globale de camp de vie + Gardiennage + Catering), nous mettons en place des contrats-cadres de sous-traitance pluriannuels.\nCes accords confèrent des tarifs préférentiels dégressifs, des engagements de niveau de service (SLA chiffrés) et la désignation d'un Directeur de Compte dédié joignable 24h/24.",
      ),
      FaqItemModel(
        id: 'faq_4',
        categorie: 'terrain',
        ordreAffichage: 4,
        question: "Dans quelles provinces de la RDC vos équipes peuvent-elles intervenir ?",
        reponse: "JBF Service possède une capacité de projection opérationnelle sur l'ensemble des 26 provinces de la République Démocratique du Congo.\nGrâce à nos bases et hubs logistiques établis à Lubumbashi (Haut-Katanga), Kolwezi (Lualaba) et Kinshasa, nous approvisionnons et déployons nos brigades techniques jusque dans les sites miniers les plus enclavés (Kibali, Tenke, Kamoa, Doko, Matadi, etc.).",
      ),
      FaqItemModel(
        id: 'faq_5',
        categorie: 'terrain',
        ordreAffichage: 5,
        question: "Quel est le délai moyen de mobilisation d'équipes sur site ?",
        reponse: "Nos délais de déploiement sont parmi les plus compétitifs du marché congolais :\n- Interventions d'urgence (soudure, maintenance, renfort de sécurité) : Mobilisation sous 12 à 24 heures.\n- Déploiements complets de brigades (équipes de catering de 500 repas/jour, régie BTP, gardiennage de site) : Mobilisation complète sous 48 à 72 heures incluant visites médicales d'aptitude, badges et inductions de sécurité.",
      ),
      FaqItemModel(
        id: 'faq_6',
        categorie: 'terrain',
        ordreAffichage: 6,
        question: "Prenez-vous en charge l'intendance et la logistique complète d'acheminement ?",
        reponse: "Absolument. JBF Service fonctionne en autonomie complète selon les termes convenus au cahier des charges :\nNous assurons l'acheminement de notre personnel qualifié, le transport de notre outillage lourd, l'approvisionnement en denrées certifiées et consommables industriels, ainsi que l'hébergement de nos équipes de relève. Le donneur d'ordre peut ainsi se concentrer sur son cœur de métier.",
      ),
      FaqItemModel(
        id: 'faq_7',
        categorie: 'hse',
        ordreAffichage: 7,
        question: "JBF Service est-elle officiellement enregistrée et certifiée ARSP ?",
        reponse: "Oui, sans réserve. JBF Service est une société de droit congolais en règle intégrale avec les dispositions de la Loi n° 17/001 du 8 février 2017 régissant la sous-traitance dans le secteur privé en RDC.\nNous détenons notre certificat d'enregistrement auprès de l'ARSP et fournissons à chaque appel d'offres notre dossier complet de régularité fiscale (DGI) et sociale (CNSS).",
      ),
      FaqItemModel(
        id: 'faq_8',
        categorie: 'hse',
        ordreAffichage: 8,
        question: "Quels sont vos protocoles de sécurité industrielle et d'hygiène HACCP ?",
        reponse: "La sécurité et la conformité sont nos priorités absolues :\n- QHSE Minier & Industriel : Alignement rigoureux sur les normes ISO 45001 et ISO 9001 avec causeries sécurité matinales (« Tool Box Talks ») et analyse quotidienne des risques (JSA).\n- Restauration & Catering : Application stricte de la méthode HACCP, contrôle microbiologique des denrées et respect sans faille de la chaîne du froid.\n- Soudure Industrielle : Soudeurs qualifiés et certifiés selon les normes ASME IX et ISO 9606.",
      ),
      FaqItemModel(
        id: 'faq_9',
        categorie: 'hse',
        ordreAffichage: 9,
        question: "Fournissez-vous les Équipements de Protection Individuelle (EPI) à vos équipes ?",
        reponse: "Oui. Tous nos agents déployés sur site sont intégralement dotés d'EPI certifiés CE et conformes aux exigences spécifiques de chaque mine ou usine :\nCasques avec jugulaire, lunettes de protection balistiques, gants anticoupure adaptés aux tâches, chaussures de sécurité coquées S3, gilets haute visibilité floqués JBF Service et harnais anti-chute vérifiés pour le travail en hauteur.",
      ),
      FaqItemModel(
        id: 'faq_10',
        categorie: 'organisation',
        ordreAffichage: 10,
        question: "Comment est encadrée et supervisée chaque mission sur le terrain ?",
        reponse: "Chaque détachement opérationnel est structuré hiérarchiquement :\nUn Superviseur de Site ou Chef de Brigade assure le commandement direct et la coordination opérationnelle quotidienne avec vos chefs d'équipe, tandis qu'un Officier QHSE veille à la conformité réglementaire et à la prévention des incidents.",
      ),
      FaqItemModel(
        id: 'faq_11',
        categorie: 'organisation',
        ordreAffichage: 11,
        question: "Quels rapports de suivi d'activité transmettez-vous aux clients ?",
        reponse: "Nous assurons une traçabilité totale à travers :\n- Des feuilles de pointage et de présence quotidiennes émargées.\n- Des rapports hebdomadaires d'avancement technique et d'avancement des travaux.\n- Des revues mensuelles de performance (KPI) portant sur la qualité de service, le respect des délais et les statistiques QHSE (taux de fréquence et de gravité zéro accident).",
      ),
      FaqItemModel(
        id: 'faq_12',
        categorie: 'organisation',
        ordreAffichage: 12,
        question: "Comment planifier une visite technique préalable sur notre site ?",
        reponse: "Nos ingénieurs d'affaires se déplacent gratuitement sur vos sites d'exploitation pour auditer les installations et évaluer les besoins réels avant cotation.\nVous pouvez nous contacter directement par téléphone au +243 822 357 053 ou via notre formulaire de contact en ligne pour convenir d'une date d'audit technique.",
      ),
    ];
  }

  Future<void> _saveCmsConfig() async {
    setState(() => _isSaving = true);

    // 1. Sauvegarde en cache local persistant
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('JBF_CMS_CUSTOM_ELEMENTS', jsonEncode(_customElements.map((e) => e.toJson()).toList()));
      await prefs.setString('JBF_CMS_FAQ_ITEMS', jsonEncode(_faqItems.map((e) => e.toJson()).toList()));
    } catch (_) {}

    // 2. Préparation des lignes pour Supabase config_cles_api
    final List<Map<String, dynamic>> rows = [
      {'cle_nom': 'contact_whatsapp', 'cle_valeur': _phoneWhatsappCtrl.text.trim()},
      {'cle_nom': 'contact_appels', 'cle_valeur': _phoneAppelsCtrl.text.trim()},
      {'cle_nom': 'contact_email', 'cle_valeur': _emailOfficielCtrl.text.trim()},
      {'cle_nom': 'contact_adresse', 'cle_valeur': _adresseSiegeCtrl.text.trim()},
      {'cle_nom': 'titre_hero_principal', 'cle_valeur': _titreHeroCtrl.text.trim()},
      {'cle_nom': 'soustitre_hero_principal', 'cle_valeur': _sousTitreHeroCtrl.text.trim()},
      {
        'cle_nom': 'cms_custom_elements_json',
        'cle_valeur': jsonEncode(_customElements.map((e) => e.toJson()).toList())
      },
      {
        'cle_nom': 'cms_faq_items_json',
        'cle_valeur': jsonEncode(_faqItems.map((e) => e.toJson()).toList())
      },
    ];

    for (var entry in _sectionToggles.entries) {
      rows.add({'cle_nom': entry.key, 'cle_valeur': entry.value.toString()});
    }

    for (var elem in _customElements) {
      rows.add({'cle_nom': 'cms_${elem.key}', 'cle_valeur': elem.isActive ? elem.value : '__DESACTIVE__'});
    }

    try {
      for (var r in rows) {
        final res = await http.post(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/config_cles_api?on_conflict=cle_nom'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
            'Content-Type': 'application/json; charset=utf-8',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: utf8.encode(jsonEncode(r)),
        );

        if (res.statusCode >= 400) {
          await http.patch(
            Uri.parse('${AppConfig.supabaseUrl}/rest/v1/config_cles_api?cle_nom=eq.${Uri.encodeComponent(r['cle_nom'])}'),
            headers: {
              'apikey': AppConfig.supabaseAnonKey,
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: utf8.encode(jsonEncode({'cle_valeur': r['cle_valeur']})),
          );
        }
      }

      // 3. Synchronisation directe dans la table faq_items si elle existe
      for (var faq in _faqItems) {
        try {
          await http.post(
            Uri.parse('${AppConfig.supabaseUrl}/rest/v1/faq_items?on_conflict=question'),
            headers: {
              'apikey': AppConfig.supabaseAnonKey,
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
              'Content-Type': 'application/json; charset=utf-8',
              'Prefer': 'resolution=merge-duplicates',
            },
            body: utf8.encode(jsonEncode({
              'question': faq.question,
              'reponse': faq.reponse,
              'categorie': faq.categorie,
              'ordre_affichage': faq.ordreAffichage,
              'est_actif': faq.estActif,
            })),
          );
        } catch (_) {}
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration et FAQ synchronisées en UTF-8 avec le site web et les applications !'),
        backgroundColor: AppConfig.successGreen,
      ),
    );
  }

  // DIALOG : AJOUTER OU MODIFIER UNE QUESTION FAQ
  void _showAddOrEditFaqDialog([FaqItemModel? item]) {
    final isEditing = item != null;
    final qCtrl = TextEditingController(text: item?.question ?? '');
    final rCtrl = TextEditingController(text: item?.reponse ?? '');
    final catCtrl = TextEditingController(text: item?.categorie ?? 'devis');
    final ordreCtrl = TextEditingController(text: (item?.ordreAffichage ?? (_faqItems.length + 1)).toString());
    bool isActive = item?.estActif ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_note : Icons.quiz_outlined, color: AppConfig.brandPink),
              const SizedBox(width: 8),
              Text(isEditing ? 'Modifier la Question FAQ' : 'Ajouter une Question FAQ'),
            ],
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Le texte est encodé en UTF-8 standard sans caractères corrompus (accents, apostrophes, tirets préservés).',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),

                  // Catégorie
                  DropdownButtonFormField<String>(
                    value: _faqCategoryLabels.containsKey(catCtrl.text) && catCtrl.text != 'toutes'
                        ? catCtrl.text
                        : 'devis',
                    decoration: const InputDecoration(labelText: 'Catégorie / Thème FAQ *'),
                    items: _faqCategoryLabels.entries
                        .where((e) => e.key != 'toutes')
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDlgState(() => catCtrl.text = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Ordre d'affichage
                  TextField(
                    controller: ordreCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ordre d\'Affichage *',
                      hintText: '1..20',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Question
                  TextField(
                    controller: qCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Question posée par le client *',
                      hintText: 'ex: Quel est le délai moyen de déploiement de vos équipes ?',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Réponse
                  TextField(
                    controller: rCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Réponse détaillée officielle *',
                      hintText: 'Rédigez la réponse complète en français clair...',
                    ),
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Question Active & Visible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: const Text('Désactivez pour masquer temporairement sur la page FAQ du site public.'),
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
              onPressed: () {
                if (qCtrl.text.trim().isEmpty || rCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez renseigner la question et la réponse.')),
                  );
                  return;
                }

                Navigator.of(ctx).pop();
                final int ordre = int.tryParse(ordreCtrl.text.trim()) ?? 1;

                setState(() {
                  if (isEditing) {
                    item.question = qCtrl.text.trim();
                    item.reponse = rCtrl.text.trim();
                    item.categorie = catCtrl.text.trim();
                    item.ordreAffichage = ordre;
                    item.estActif = isActive;
                  } else {
                    _faqItems.add(FaqItemModel(
                      id: 'faq_${DateTime.now().millisecondsSinceEpoch}',
                      question: qCtrl.text.trim(),
                      reponse: rCtrl.text.trim(),
                      categorie: catCtrl.text.trim(),
                      ordreAffichage: ordre,
                      estActif: isActive,
                    ));
                  }
                  _faqItems.sort((a, b) => a.ordreAffichage.compareTo(b.ordreAffichage));
                });

                _saveCmsConfig();
              },
              child: Text(isEditing ? 'Enregistrer les modifications' : 'Ajouter la Question'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteFaqItem(FaqItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette question FAQ ?'),
        content: Text('Voulez-vous supprimer définitivement la question :\n\n"${item.question}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _faqItems.removeWhere((e) => e.id == item.id);
              });
              _saveCmsConfig();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreOfficialFaq() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurer la FAQ Officielle JBF'),
        content: const Text(
          'Cette action va réinitialiser les 12 questions et réponses officielles de la FAQ JBF Service en UTF-8 propre.\n\nVoulez-vous continuer ?',
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

    setState(() {
      _faqItems = _getOfficialDefaultFaq();
    });
    await _saveCmsConfig();
  }

  // DIALOG ELEMENTS CMS
  void _showAddOrEditElementDialog([CustomCmsElement? item]) {
    final isEditing = item != null;
    final keyCtrl = TextEditingController(text: item?.key ?? '');
    final labelCtrl = TextEditingController(text: item?.label ?? '');
    final valCtrl = TextEditingController(text: item?.value ?? '');
    String selectedType = item?.type ?? 'texte';
    String selectedPlatform = item?.targetPlatform ?? 'Tous';
    bool isActive = item?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_note : Icons.add_circle_outline, color: AppConfig.brandPink),
              const SizedBox(width: 8),
              Text(isEditing ? 'Modifier l\'Élément CMS' : 'Ajouter un Élément CMS (Texte, Média, Champ...)'),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Définissez un texte, un arrière-plan, un champ ou une section dynamique pour le Web ou les Apps.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(labelText: 'Nature de l\'Élément'),
                          items: const [
                            DropdownMenuItem(value: 'texte', child: Text('Texte / Slogan / Paragraphe')),
                            DropdownMenuItem(value: 'image_background', child: Text('Image / Background / Bannière')),
                            DropdownMenuItem(value: 'champ_formulaire', child: Text('Champ de Formulaire / Input')),
                            DropdownMenuItem(value: 'section', child: Text('Section Complète de Page')),
                            DropdownMenuItem(value: 'contact', child: Text('Numéro Téléphone / Email Contact')),
                          ],
                          onChanged: (v) => setDlgState(() => selectedType = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedPlatform,
                          decoration: const InputDecoration(labelText: 'Destination Cible'),
                          items: const [
                            DropdownMenuItem(value: 'Tous', child: Text('Toutes Plateformes')),
                            DropdownMenuItem(value: 'Web Public', child: Text('Site Web Public')),
                            DropdownMenuItem(value: 'App Client', child: Text('Application Client')),
                            DropdownMenuItem(value: 'App Membre', child: Text('Application Membre')),
                          ],
                          onChanged: (v) => setDlgState(() => selectedPlatform = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Libellé / Titre descriptif *',
                      hintText: 'ex: Image Background Hero, Slogan Partenariat...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyCtrl,
                    enabled: !isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Identifiant Unique (Clé système) *',
                      hintText: 'ex: bg_hero_chantier, slogan_mines, champ_nif...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: valCtrl,
                    maxLines: selectedType == 'texte' ? 3 : 2,
                    decoration: InputDecoration(
                      labelText: selectedType == 'image_background'
                          ? 'URL de l\'image / Background CDN *'
                          : (selectedType == 'champ_formulaire' ? 'Placeholder / Type du champ *' : 'Valeur / Contenu du texte *'),
                      hintText: selectedType == 'image_background'
                          ? 'https://.../bg_minier.jpg'
                          : 'Saisissez le texte ou la valeur...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Élément Actif & Visible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: const Text('Désactivez pour masquer instantanément sur le site et les applications'),
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
              onPressed: () {
                if (labelCtrl.text.isEmpty || keyCtrl.text.isEmpty || valCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez renseigner tous les champs obligatoires (*).')),
                  );
                  return;
                }

                Navigator.of(ctx).pop();
                setState(() {
                  if (isEditing) {
                    item.label = labelCtrl.text.trim();
                    item.type = selectedType;
                    item.value = valCtrl.text.trim();
                    item.targetPlatform = selectedPlatform;
                    item.isActive = isActive;
                  } else {
                    _customElements.add(CustomCmsElement(
                      id: 'cms_${DateTime.now().millisecondsSinceEpoch}',
                      type: selectedType,
                      key: keyCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
                      label: labelCtrl.text.trim(),
                      value: valCtrl.text.trim(),
                      targetPlatform: selectedPlatform,
                      isActive: isActive,
                    ));
                  }
                });
                _saveCmsConfig();
              },
              child: Text(isEditing ? 'Mettre à jour' : 'Ajouter l\'Élément'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCustomElement(CustomCmsElement elem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet élément CMS ?'),
        content: Text('Voulez-vous supprimer définitivement "${elem.label}" (${elem.key}) ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _customElements.removeWhere((e) => e.id == elem.id);
              });
              _saveCmsConfig();
            },
            child: const Text('Supprimer'),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gestionnaire de Contenus CMS & Foire Aux Questions (FAQ)',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
                    Text('Modifiez les textes, sections, contacts et la FAQ du site web public et des applications en UTF-8 propre.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.brandPink,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onPressed: _isSaving ? null : _saveCmsConfig,
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save, size: 18),
                      label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer & Synchroniser Tout'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppConfig.brandPink,
              unselectedLabelColor: Colors.grey.shade700,
              indicatorColor: AppConfig.brandPink,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                const Tab(icon: Icon(Icons.dashboard_customize, size: 18), text: 'Textes, Contacts & Sections CMS'),
                Tab(
                  icon: const Icon(Icons.quiz_outlined, size: 18),
                  text: 'Foire Aux Questions (FAQ) (${_faqItems.length})',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralCmsTab(),
                _buildFaqManagerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 1 : CONTENUS GÉNÉRAUX CMS
  Widget _buildGeneralCmsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BLOC 1: ÉLÉMENTS CMS DYNAMIQUES
          _buildCard(
            title: '1. Éléments CMS Personnalisés (Textes, Images, Backgrounds, Champs & Sections)',
            icon: Icons.dashboard_customize,
            trailing: TextButton.icon(
              onPressed: () => _showAddOrEditElementDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter'),
            ),
            child: _customElements.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.layers_clear, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text('Aucun élément CMS personnalisé créé pour l\'instant.', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => _showAddOrEditElementDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter un texte, une image ou une section'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _customElements.length,
                    separatorBuilder: (_, __) => const Divider(height: 14),
                    itemBuilder: (context, i) {
                      final item = _customElements[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: item.isActive ? const Color(0xFFF9FAFC) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: item.isActive ? Colors.grey.shade300 : Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: item.isActive ? AppConfig.brandPinkTint : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                item.type == 'image_background'
                                    ? Icons.image
                                    : (item.type == 'champ_formulaire'
                                        ? Icons.input
                                        : (item.type == 'section' ? Icons.view_quilt : Icons.title)),
                                color: item.isActive ? AppConfig.brandPink : Colors.grey,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(item.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                        child: Text(item.type.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                        child: Text(item.targetPlatform, style: TextStyle(fontSize: 10, color: Colors.blue.shade800)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Clé : ${item.key} • Valeur : ${item.value}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: item.isActive,
                              activeColor: AppConfig.brandPink,
                              onChanged: (val) {
                                setState(() {
                                  item.isActive = val;
                                });
                                _saveCmsConfig();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                              tooltip: 'Modifier',
                              onPressed: () => _showAddOrEditElementDialog(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: AppConfig.dangerRed),
                              tooltip: 'Supprimer',
                              onPressed: () => _deleteCustomElement(item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 22),

          // BLOC 2: COORDONNÉES OFFICIELLES
          _buildCard(
            title: '2. Coordonnées Officielles (Numéros, Emails & Siège)',
            icon: Icons.contact_phone,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneWhatsappCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Numéro WhatsApp Officiel (Affiché sur Web/Apps)',
                          prefixIcon: Icon(Icons.chat_bubble, color: Color(0xFF25D366)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _phoneAppelsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Numéro Appels Téléphoniques GSM Directs',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailOfficielCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Adresse Email Principale de Contact & Devis',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _adresseSiegeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Adresse du Siège Central en RDC',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // BLOC 3: TEXTES MAJEURS & SLOGANS
          _buildCard(
            title: '3. Textes & Titres Majeurs (Site Web & Applications)',
            icon: Icons.title,
            child: Column(
              children: [
                TextField(
                  controller: _titreHeroCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titre Principal d\'Accueil (Hero)',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _sousTitreHeroCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sous-titre / Spécialités Principales',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // BLOC 4: ACTIVATION / DÉSACTIVATION DES SECTIONS & PAGES
          _buildCard(
            title: '4. Activation / Désactivation des Sections & Pages Préconfigurées',
            icon: Icons.toggle_on,
            child: Column(
              children: _sectionToggles.entries.map((entry) {
                final label = _sectionLabels[entry.key] ?? entry.key;
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppConfig.brandPink,
                  title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: Text('Paramètre système : ${entry.key}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  value: entry.value,
                  onChanged: (val) {
                    setState(() {
                      _sectionToggles[entry.key] = val;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2 : GESTIONNAIRE COMPLET DE LA FOIRE AUX QUESTIONS (FAQ)
  Widget _buildFaqManagerTab() {
    final filteredFaq = _faqItems.where((item) {
      final matchesCat = _faqCategoryFilter == 'toutes' || item.categorie == _faqCategoryFilter;
      final matchesSearch = _faqSearch.isEmpty ||
          item.question.toLowerCase().contains(_faqSearch.toLowerCase()) ||
          item.reponse.toLowerCase().contains(_faqSearch.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    final int totalFaq = _faqItems.length;
    final int activeFaq = _faqItems.where((e) => e.estActif).length;

    return Column(
      children: [
        // Top Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher une question, mot-clé, thème...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _faqSearch = val.trim()),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _faqCategoryLabels.entries.map((e) {
                      final isSel = _faqCategoryFilter == e.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(e.value),
                          selected: isSel,
                          selectedColor: AppConfig.brandPinkTint,
                          checkmarkColor: AppConfig.brandPink,
                          labelStyle: TextStyle(
                            color: isSel ? AppConfig.brandPink : Colors.grey.shade700,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _faqCategoryFilter = e.key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              OutlinedButton.icon(
                onPressed: _restoreOfficialFaq,
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('Restaurer la FAQ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConfig.blackText,
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddOrEditFaqDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nouvelle Question'),
                style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Info Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          color: const Color(0xFFF8FAFC),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Affichage de ${filteredFaq.length} question(s) sur $totalFaq au total ($activeFaq actives)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              ),
              const Text(
                'Toutes les modifications sont synchronisées avec le site web (faq.html) en UTF-8 propre.',
                style: TextStyle(fontSize: 11.5, color: Colors.teal),
              ),
            ],
          ),
        ),

        // FAQ List
        Expanded(
          child: filteredFaq.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.quiz_outlined, size: 52, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Aucune question FAQ trouvée.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _restoreOfficialFaq,
                        icon: const Icon(Icons.download),
                        label: const Text('Restaurer les 12 Questions Officielles'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(22),
                  itemCount: filteredFaq.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filteredFaq[index];
                    final catLabel = _faqCategoryLabels[item.categorie] ?? item.categorie;

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: item.estActif ? Colors.grey.shade200 : const Color(0xFFFCA5A5),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: item.estActif ? AppConfig.brandPinkTint : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '#${item.ordreAffichage}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: item.estActif ? AppConfig.brandPink : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        catLabel,
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!item.estActif)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Masquée sur le site',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.question,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: item.estActif ? AppConfig.blackText : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.reponse,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Row(
                            children: [
                              Switch(
                                value: item.estActif,
                                activeColor: AppConfig.brandPink,
                                onChanged: (val) {
                                  setState(() => item.estActif = val);
                                  _saveCmsConfig();
                                },
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                tooltip: 'Modifier la question',
                                onPressed: () => _showAddOrEditFaqDialog(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppConfig.dangerRed, size: 20),
                                tooltip: 'Supprimer la question',
                                onPressed: () => _deleteFaqItem(item),
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
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppConfig.brandPink, size: 20),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
