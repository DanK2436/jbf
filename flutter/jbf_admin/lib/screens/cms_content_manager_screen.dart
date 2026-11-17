import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

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
  final _emailOfficielCtrl = TextEditingController(text: 'bintijudith104@gmail.com');
  final _adresseSiegeCtrl = TextEditingController(text: 'Lubumbashi, Haut-Katanga, RDC');

  // Textes & Slogans
  final _titreHeroCtrl = TextEditingController(text: 'Leader Multi-Services & Sous-Traitance Agréée ARSP en RDC');
  final _sousTitreHeroCtrl = TextEditingController(text: 'Mines & Extraction • BTP & Génie Civil • Catering Industriel HACCP');

  // Toggles de Sections & Pages
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
            }
          }
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveCmsConfig() async {
    setState(() => _isSaving = true);

    try {
      // Sauvegarde des paramètres dans Supabase
      final List<Map<String, dynamic>> rows = [
        {'cle_nom': 'contact_whatsapp', 'cle_valeur': _phoneWhatsappCtrl.text.trim()},
        {'cle_nom': 'contact_appels', 'cle_valeur': _phoneAppelsCtrl.text.trim()},
        {'cle_nom': 'contact_email', 'cle_valeur': _emailOfficielCtrl.text.trim()},
        {'cle_nom': 'contact_adresse', 'cle_valeur': _adresseSiegeCtrl.text.trim()},
        {'cle_nom': 'titre_hero_principal', 'cle_valeur': _titreHeroCtrl.text.trim()},
        {'cle_nom': 'soustitre_hero_principal', 'cle_valeur': _sousTitreHeroCtrl.text.trim()},
      ];

      for (var entry in _sectionToggles.entries) {
        rows.add({'cle_nom': entry.key, 'cle_valeur': entry.value.toString()});
      }

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
        content: Text('Configuration du site et des applications sauvegardée avec succès !'),
        backgroundColor: AppConfig.successGreen,
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
                  const Text('Gestionnaire de Contenus & Feature Toggles',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
                  Text('Activez ou désactivez textes, sections, téléphones, emails et pages pour le Web et les Apps',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
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
          const SizedBox(height: 22),

          // BLOC 1: COORDONNÉES OFFICIELLES (TÉLÉPHONES & EMAILS)
          _buildCard(
            title: '1. Coordonnées Officielles (Numéros, Emails & Siège)',
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

          // BLOC 2: TEXTES MAJEURS & SLOGANS
          _buildCard(
            title: '2. Textes & Titres Majeurs (Site Web & Applications)',
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

          // BLOC 3: ACTIVATION / DÉSACTIVATION DES SECTIONS & PAGES
          _buildCard(
            title: '3. Activation / Désactivation des Sections, Pages & Champs',
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

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
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
            children: [
              Icon(icon, color: AppConfig.brandPink, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
