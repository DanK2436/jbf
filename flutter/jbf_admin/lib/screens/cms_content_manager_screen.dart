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

class CmsContentManagerScreen extends StatefulWidget {
  const CmsContentManagerScreen({super.key});

  @override
  State<CmsContentManagerScreen> createState() => _CmsContentManagerScreenState();
}

class _CmsContentManagerScreenState extends State<CmsContentManagerScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadCmsConfig();
  }

  @override
  void dispose() {
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
    } catch (_) {}

    // 2. Charger depuis Supabase (config_cles_api)
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/config_cles_api?select=*'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
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
            } else if (cle == 'titre_hero_principal') {
              _titreHeroCtrl.text = val;
            } else if (cle == 'soustitre_hero_principal') {
              _sousTitreHeroCtrl.text = val;
            } else if (cle == 'cms_custom_elements_json') {
              try {
                final List<dynamic> dec = jsonDecode(val);
                _customElements = dec.map((e) => CustomCmsElement.fromJson(e)).toList();
              } catch (_) {}
            }
          }
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveCmsConfig() async {
    setState(() => _isSaving = true);

    // 1. Sauvegarde en cache local persistant
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('JBF_CMS_CUSTOM_ELEMENTS', jsonEncode(_customElements.map((e) => e.toJson()).toList()));
    } catch (_) {}

    // 2. Préparation des lignes pour Supabase
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
    ];

    for (var entry in _sectionToggles.entries) {
      rows.add({'cle_nom': entry.key, 'cle_valeur': entry.value.toString()});
    }

    for (var elem in _customElements) {
      rows.add({'cle_nom': 'cms_${elem.key}', 'cle_valeur': elem.isActive ? elem.value : '__DESACTIVE__'});
    }

    try {
      for (var r in rows) {
        await http.post(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/config_cles_api'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode(r),
        );
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration du site et des applications sauvegardée et synchronisée avec succès !'),
        backgroundColor: AppConfig.successGreen,
      ),
    );
  }

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

    return SingleChildScrollView(
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
                  const Text('Gestionnaire de Contenus & Éléments Dynamiques',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
                  Text('Activez, désactivez ou ajoutez des textes, images, backgrounds, champs, sections, numéros et emails pour le Web et les Apps',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
                    onPressed: () => _showAddOrEditElementDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter un Élément CMS'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.brandPink,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onPressed: _isSaving ? null : _saveCmsConfig,
                    icon: const Icon(Icons.save, size: 18),
                    label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer Tout'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),

          // BLOC 1: ÉLÉMENTS CMS DYNAMIQUES CRÉÉS PAR L'ADMIN
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

          // BLOC 2: COORDONNÉES OFFICIELLES (TÉLÉPHONES & EMAILS)
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
