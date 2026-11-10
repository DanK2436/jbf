import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../models/client_models.dart';
import '../services/client_data_service.dart';
import '../widgets/stat_badge.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);
    final list = await _dataService.fetchMissions();
    if (!mounted) return;
    setState(() {
      _missions = list;
      _isLoading = false;
    });
  }

  Future<void> _contactChef(String chef, String missionRef) async {
    final uri = Uri.parse('https://wa.me/243970349724?text=Bonjour,%20question%20sur%20le%20chantier%20$missionRef%20(Supervisé%20par%20$chef)');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
          : RefreshIndicator(
              onRefresh: _loadMissions,
              color: AppConfig.brandPink,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            const Text(
                              'Suivi des Chantiers & Interventions',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                            ),
                            Text(
                              'Opérations actives sur sites miniers (Haut-Katanga & Lualaba)',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.radar, color: Color(0xFF16A34A), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Supervision GPS Directe',
                                style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _missions.length,
                      itemBuilder: (context, idx) {
                        final m = _missions[idx];
                        final isDone = m.statut == 'termine';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppConfig.brandPink.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            m.reference,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppConfig.brandPink,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Période : ${m.dateDebut} au ${m.dateFin}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                    StatBadge(
                                      label: isDone ? 'Chantier Livré' : 'En Exécution (${m.avancement}%)',
                                      color: isDone ? AppConfig.successGreen : const Color(0xFF0284C7),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  m.titre,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.pin_drop, size: 16, color: AppConfig.brandPink),
                                    const SizedBox(width: 4),
                                    Text(m.site, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Progress bar
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Avancement des travaux :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        Text('${m.avancement}% Réalisé', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConfig.brandPink)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: m.avancement / 100.0,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey.shade200,
                                        color: isDone ? AppConfig.successGreen : AppConfig.brandPink,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Bottom supervisor & actions
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 14,
                                          backgroundColor: AppConfig.brandPink,
                                          child: Icon(Icons.person, size: 16, color: Colors.white),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Superviseur : ${m.chef}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppConfig.whatsappGreen,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                      onPressed: () => _contactChef(m.chef, m.reference),
                                      icon: const Icon(Icons.chat, size: 16),
                                      label: const Text('Joindre Superviseur', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
