import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../models/client_models.dart';
import '../services/client_data_service.dart';

class MissionsScreen extends StatefulWidget {
  final ClientUser client;

  const MissionsScreen({super.key, required this.client});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  final _dataService = ClientDataService();
  bool _isLoading = true;
  List<ClientMission> _missions = [];
  Map<String, List<Map<String, dynamic>>> _missionsEtapes = {};

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);
    final list = await _dataService.fetchMissions();

    // Charger les étapes réelles pour chaque mission
    for (var m in list) {
      try {
        final url = '${AppConfig.apiBaseUrl}/client/missions/${m.id}/progression';
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['etapes'] != null) {
            _missionsEtapes[m.id] = (data['etapes'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _missions = list;
      _isLoading = false;
    });
  }

  Future<void> _contactSupport(String ref) async {
    final uri = Uri.parse('https://wa.me/243970349724?text=Bonjour,%20je%20souhaite%20valider%20le%20paiement%20de%20ma%20mission%20$ref');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
          : RefreshIndicator(
              onRefresh: _loadMissions,
              color: AppConfig.brandPink,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Suivi de Progression des Projets',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Accès conditionnel sécurisé : réservé aux projets dont le paiement a été validé par la Direction JBF',
                                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, size: 16, color: AppConfig.successGreen),
                              SizedBox(width: 6),
                              Text('Portail Partenaire Certifié', style: TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_missions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: const Center(
                          child: Text('Aucun projet actif pour votre compte client actuellement.'),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _missions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final m = _missions[index];
                          // Vérification conditionnelle du paiement
                          final bool isPaiementValide = m.statut == 'en_cours' || m.progressionPct > 0;
                          final etapes = _missionsEtapes[m.id] ?? [];

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Entête Projet (Responsive)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isPaiementValide ? AppConfig.brandPinkTint : Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.engineering,
                                              color: isPaiementValide ? AppConfig.brandPink : Colors.grey.shade600,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  m.titre,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConfig.blackText),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Réf: ${m.codeMission} • Site : ${m.siteIntervention}',
                                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                ),
                                                Text(
                                                  'Chef d\'Équipe : ${m.chefEquipe}',
                                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isPaiementValide ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isPaiementValide ? 'Paiement Confirmé' : 'Paiement En Attente',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isPaiementValide ? AppConfig.successGreen : Colors.amber.shade900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Divider(height: 1),

                                // Zone Conditionnelle (Responsive)
                                if (!isPaiementValide)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.lock_outline, color: Color(0xFFD97706), size: 24),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Suivi Détaillé & Livrables Verrouillés',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'La progression étape par étape et les PV techniques seront débloqués dès confirmation du règlement de l\'acompte par la Direction JBF.',
                                                    style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _contactSupport(m.codeMission),
                                            icon: const Icon(Icons.payment, size: 16),
                                            label: const Text('Valider le Paiement via Support'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFD97706),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Barre de progression
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: LinearProgressIndicator(
                                                  value: (m.progressionPct / 100.0).clamp(0.0, 1.0),
                                                  minHeight: 9,
                                                  backgroundColor: Colors.grey.shade200,
                                                  color: AppConfig.brandPink,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Text('${m.progressionPct}% achevé', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          ],
                                        ),
                                        const SizedBox(height: 18),

                                        // Étapes et jalons
                                        const Text('Jalons et Livrables Validés par JBF :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                        const SizedBox(height: 10),

                                        if (etapes.isEmpty)
                                          Text(
                                            'Rapport terrain : ${m.dernierRapport.isNotEmpty ? m.dernierRapport : "Chantier en cours selon le cahier des charges."}',
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                          )
                                        else
                                          Column(
                                            children: etapes.map((e) {
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 8.0),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.check_circle, size: 18, color: AppConfig.successGreen),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        e['titre_etape'] ?? 'Jalon validé',
                                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                      ),
                                                    ),
                                                    const Text('✓ Conforme', style: TextStyle(fontSize: 11, color: AppConfig.successGreen, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
