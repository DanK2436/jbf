import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

class RecrutementAdminScreen extends StatefulWidget {
  const RecrutementAdminScreen({super.key});

  @override
  State<RecrutementAdminScreen> createState() => _RecrutementAdminScreenState();
}

class _RecrutementAdminScreenState extends State<RecrutementAdminScreen> {
  bool _isLoading = true;
  bool _isRecrutementActif = true;
  List<Map<String, dynamic>> _candidatures = [];
  String _selectedStatut = 'tous';
  String _selectedProvince = 'Toutes';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadRecrutementStatut(),
      _loadCandidatures(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadRecrutementStatut() async {
    try {
      final url = '${AppConfig.apiBaseUrl}/recrutement/statut';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted && data['recrutement_actif'] != null) {
          setState(() {
            _isRecrutementActif = data['recrutement_actif'] == true;
          });
        }
      }
    } catch (_) {
      // Fallback Supabase
      try {
        final sbUrl = '${AppConfig.supabaseUrl}/rest/v1/config_cles_api?cle_nom=eq.recrutement_actif&select=*';
        final res = await http.get(
          Uri.parse(sbUrl),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
        );
        if (res.statusCode == 200) {
          final list = jsonDecode(res.body) as List;
          if (list.isNotEmpty && mounted) {
            setState(() {
              _isRecrutementActif = list[0]['cle_valeur'] == 'true' || list[0]['is_active'] == true;
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _loadCandidatures() async {
    try {
      final url = '${AppConfig.supabaseUrl}/rest/v1/candidatures?select=*&order=created_at.desc';
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (mounted) {
          setState(() {
            _candidatures = list.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement candidatures: $e');
    }
  }

  Future<void> _toggleRecrutementGlobal() async {
    final bool target = !_isRecrutementActif;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(target ? 'Activer la Page de Recrutement' : 'Suspendre la Page de Recrutement'),
        content: Text(
          target
              ? 'Voulez-vous ouvrir publiquement le formulaire de candidature sur le site web ? Les candidats pourront soumettre leurs CV.'
              : 'Voulez-vous fermer le formulaire public ? La page affichera un message informant que les sessions de recrutement sont temporairement suspendues.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: target ? AppConfig.successGreen : AppConfig.dangerRed,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(target ? 'Ouvrir les Candidatures' : 'Suspendre les Candidatures'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRecrutementActif = target);

    try {
      final url = '${AppConfig.apiBaseUrl}/admin/recrutement/toggle';
      await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'actif': target}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {
      try {
        final sbUrl = '${AppConfig.supabaseUrl}/rest/v1/config_cles_api';
        await http.post(
          Uri.parse(sbUrl),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
            'Content-Type': 'application/json',
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode({
            'cle_nom': 'recrutement_actif',
            'cle_valeur': target ? 'true' : 'false',
            'is_active': target,
            'updated_at': DateTime.now().toIso8601String(),
          }),
        );
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(target ? 'Campagnes de recrutement activées publiquement.' : 'Campagnes de recrutement suspendues sur le site web.'),
        backgroundColor: target ? AppConfig.successGreen : Colors.orange.shade800,
      ),
    );
  }

  void _showConvoquerDialog(Map<String, dynamic> cand) {
    final candId = cand['id'];
    final candNom = cand['nom_complet'];
    final candEmail = cand['email'];
    final dateCtrl = TextEditingController(text: '25 Novembre 2026 à 10h00 (Heure de Lubumbashi)');
    final lieuCtrl = TextEditingController(text: 'Direction Générale JBF Services, Siège Lubumbashi (ou Visioconférence)');
    final consignesCtrl = TextEditingController(text: 'Veuillez vous munir de vos originaux de diplômes, pièces d\'identité et certificats d\'aptitude médicale.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.mail_outline, color: AppConfig.brandPink),
            const SizedBox(width: 8),
            Text('Convoquer $candNom à un Entretien'),
          ],
        ),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Candidat : $candNom • Email : $candEmail', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Domaine : ${cand['domaine_expertise']} • Expérience : ${cand['annees_experience']} an(s)'),
                const Divider(height: 24),
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(labelText: 'Date & Heure de l\'Entretien *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lieuCtrl,
                  decoration: const InputDecoration(labelText: 'Lieu de Rendez-vous ou Lien Visio *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: consignesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Consignes & Documents requis à présenter'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Expédier la Convocation Officielle'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final url = '${AppConfig.apiBaseUrl}/admin/candidatures/$candId/convoquer';
                final res = await http.post(
                  Uri.parse(url),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'date_convocation': dateCtrl.text.trim(),
                    'lieu_ou_visio': lieuCtrl.text.trim(),
                    'message_consignes': consignesCtrl.text.trim(),
                    'envoyee_par': 'Direction des Ressources Humaines JBF Services',
                  }),
                );

                if (!mounted) return;
                if (res.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Convocation officielle expédiée avec succès à $candEmail !'),
                      backgroundColor: AppConfig.successGreen,
                    ),
                  );
                  _loadCandidatures();
                } else {
                  throw Exception('Erreur serveur');
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur envoi: $e'), backgroundColor: AppConfig.dangerRed),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateCandidatureStatut(String id, String statut) async {
    try {
      final url = '${AppConfig.supabaseUrl}/rest/v1/candidatures?id=eq.$id';
      await http.patch(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'statut': statut, 'updated_at': DateTime.now().toIso8601String()}),
      );
      _loadCandidatures();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut mis à jour : $statut'), backgroundColor: AppConfig.successGreen),
      );
    } catch (_) {}
  }

  List<Map<String, dynamic>> _getFilteredCandidatures() {
    return _candidatures.where((c) {
      final statut = (c['statut'] ?? 'en_attente').toString();
      final prov = (c['province_residence'] ?? '').toString();
      final nom = (c['nom_complet'] ?? '').toString().toLowerCase();
      final email = (c['email'] ?? '').toString().toLowerCase();
      final dom = (c['domaine_expertise'] ?? '').toString().toLowerCase();

      if (_selectedStatut != 'tous' && statut != _selectedStatut) return false;
      if (_selectedProvince != 'Toutes' && !prov.contains(_selectedProvince)) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return nom.contains(q) || email.contains(q) || dom.contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredCandidatures();
    final int total = _candidatures.length;
    final int enAttente = _candidatures.where((c) => (c['statut'] ?? '') == 'en_attente').length;
    final int convoques = _candidatures.where((c) => (c['statut'] ?? '') == 'convoque').length;
    final int acceptes = _candidatures.where((c) => (c['statut'] ?? '') == 'accepte').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: Column(
        children: [
          // Header Bar avec Switch d'Activation / Désactivation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gestion des Recrutements & Candidatures Déposées',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText),
                      ),
                      Text(
                        'Réception des CV déposés sans compte sur le site web public et émission des convocations officielles',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

                // Switch Activation / Désactivation Global
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isRecrutementActif ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isRecrutementActif ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isRecrutementActif ? Icons.check_circle : Icons.pause_circle,
                        color: _isRecrutementActif ? AppConfig.successGreen : AppConfig.dangerRed,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRecrutementActif ? 'PAGE PUBLIQUE OUVERTE' : 'PAGE PUBLIQUE SUSPENDUE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _isRecrutementActif ? const Color(0xFF166534) : const Color(0xFF991B1B),
                            ),
                          ),
                          Text(
                            _isRecrutementActif ? 'Les candidats peuvent postuler' : 'Formulaire web fermé',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: _isRecrutementActif ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _isRecrutementActif,
                        activeColor: AppConfig.successGreen,
                        inactiveThumbColor: AppConfig.dangerRed,
                        onChanged: (_) => _toggleRecrutementGlobal(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // KPIs Banner
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                _buildStatCard('Total Candidatures', total.toString(), Colors.blue.shade700, Icons.folder_shared),
                const SizedBox(width: 16),
                _buildStatCard('En Attente d\'Évaluation', enAttente.toString(), Colors.orange.shade800, Icons.hourglass_top),
                const SizedBox(width: 16),
                _buildStatCard('Convoqués à un Entretien', convoques.toString(), AppConfig.brandPink, Icons.mail_outline),
                const SizedBox(width: 16),
                _buildStatCard('Candidats Retenus / Admis', acceptes.toString(), AppConfig.successGreen, Icons.check_circle),
              ],
            ),
          ),

          // Filtres & Recherche
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher candidat par nom, email, spécialité...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF9FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedStatut,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'tous', child: Text('Tous les Statuts')),
                    DropdownMenuItem(value: 'en_attente', child: Text('En Attente')),
                    DropdownMenuItem(value: 'convoque', child: Text('Convoqués')),
                    DropdownMenuItem(value: 'accepte', child: Text('Retenus')),
                    DropdownMenuItem(value: 'rejete', child: Text('Rejetés')),
                  ],
                  onChanged: (v) => setState(() => _selectedStatut = v!),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualiser',
                  onPressed: _loadCandidatures,
                ),
              ],
            ),
          ),

          // Candidatures List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Aucune candidature correspondant aux critères.'),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final c = filtered[i];
                          final id = c['id'] ?? '';
                          final ref = 'JBF-REC-${id.toString().substring(0, id.toString().length >= 8 ? 8 : 4).toUpperCase()}';
                          final nom = c['nom_complet'] ?? 'Candidat';
                          final email = c['email'] ?? '';
                          final phone = c['telephone'] ?? '';
                          final province = c['province_residence'] ?? 'RDC';
                          final domaine = c['domaine_expertise'] ?? 'Général';
                          final exp = c['annees_experience'] ?? 0;
                          final statut = (c['statut'] ?? 'en_attente').toString();
                          final cvUrl = c['cv_url'] ?? '';

                          Color badgeBg = Colors.grey.shade100;
                          Color badgeText = Colors.grey.shade800;
                          if (statut == 'convoque') {
                            badgeBg = AppConfig.brandPinkTint;
                            badgeText = AppConfig.brandPink;
                          } else if (statut == 'accepte') {
                            badgeBg = const Color(0xFFDCFCE7);
                            badgeText = AppConfig.successGreen;
                          } else if (statut == 'rejete') {
                            badgeBg = const Color(0xFFFEE2E2);
                            badgeText = AppConfig.dangerRed;
                          } else if (statut == 'en_attente') {
                            badgeBg = const Color(0xFFFEF3C7);
                            badgeText = Colors.amber.shade900;
                          }

                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppConfig.brandPinkTint,
                                  child: Text(
                                    nom.substring(0, nom.length >= 2 ? 2 : 1).toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppConfig.brandPink),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                            child: Text(ref, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                                            child: Text(
                                              statut.toUpperCase(),
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeText),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Spécialité : $domaine • Expérience : $exp an(s) • Province : $province'),
                                      Text('Contact : $email • Tél WhatsApp : $phone', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (cvUrl.isNotEmpty)
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          if (cvUrl.startsWith('data:')) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('CV transmis au format binaire sécurisé.')),
                                            );
                                          } else {
                                            final uri = Uri.parse(cvUrl);
                                            if (await canLaunchUrl(uri)) launchUrl(uri);
                                          }
                                        },
                                        icon: const Icon(Icons.picture_as_pdf, size: 15),
                                        label: const Text('Consulter CV'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey.shade800,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _showConvoquerDialog(c),
                                      icon: const Icon(Icons.mail, size: 15),
                                      label: const Text('Convoquer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppConfig.brandPink,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (val) => _updateCandidatureStatut(id, val),
                                      itemBuilder: (ctx) => const [
                                        PopupMenuItem(value: 'accepte', child: Text('Retenir / Accepter')),
                                        PopupMenuItem(value: 'en_revue', child: Text('Mettre en Revue')),
                                        PopupMenuItem(value: 'rejete', child: Text('Rejeter')),
                                      ],
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

  Widget _buildStatCard(String title, String val, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
