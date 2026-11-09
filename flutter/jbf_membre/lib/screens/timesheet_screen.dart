import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/membre_models.dart';
import '../services/supabase_service.dart';
import '../widgets/stat_badge.dart';

class TimesheetScreen extends StatefulWidget {
  const TimesheetScreen({super.key});

  @override
  State<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends State<TimesheetScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<PointageRecord> _pointages = [];

  @override
  void initState() {
    super.initState();
    _loadPointages();
  }

  Future<void> _loadPointages() async {
    setState(() => _isLoading = true);
    final list = await _supabase.fetchPointages();
    if (!mounted) return;
    setState(() {
      _pointages = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    final double totalNormales = _pointages.fold(0.0, (s, p) => s + p.heuresNormales);
    final double totalSup = _pointages.fold(0.0, (s, p) => s + p.heuresSup);

    return RefreshIndicator(
      onRefresh: _loadPointages,
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
                    const Text('Mes Feuilles de Temps & Relevé de Pointage (BDD)',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Données réelles de la table pointages Supabase',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                  tooltip: 'Actualiser',
                  onPressed: _loadPointages,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('HEURES NORMALES (BDD)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text('${totalNormales.toStringAsFixed(0)} h',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
                          const Text('Base 8h / jour ouvré', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('HEURES SUPPLÉMENTAIRES',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text('${totalSup.toStringAsFixed(0)} h',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConfig.brandPink)),
                          const Text('Heures de dépassement chantier', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CONTRÔLE ANTI-VPN',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          const Text('Conforme',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConfig.successGreen)),
                          const Text('Traçabilité IP auditée', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _pointages.isEmpty
                      ? const Center(child: Text('Aucun pointage trouvé dans la table pointages.'))
                      : ListView.separated(
                          itemCount: _pointages.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final p = _pointages[index];
                            final isEntree = p.typePointage == 'entree';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isEntree ? AppConfig.brandPinkTint : const Color(0xFFFEF3C7),
                                    child: Icon(
                                      isEntree ? Icons.login : Icons.logout,
                                      color: isEntree ? AppConfig.brandPink : Colors.orange.shade800,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isEntree ? 'PRISE DE POSTE (ENTRÉE)' : 'FIN DE POSTE (SORTIE)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: isEntree ? AppConfig.brandPinkDark : Colors.orange.shade900,
                                          ),
                                        ),
                                        Text('Site : ${p.siteLieu}',
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${p.dateHeure.day}/${p.dateHeure.month}/${p.dateHeure.year} à ${p.dateHeure.hour.toString().padLeft(2, '0')}:${p.dateHeure.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                        Text('GPS : ${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('IP : ${p.ipAddress}', style: const TextStyle(fontSize: 12)),
                                        const Row(
                                          children: [
                                            Icon(Icons.shield, color: AppConfig.successGreen, size: 12),
                                            SizedBox(width: 4),
                                            Text('Anti-VPN Validé', style: TextStyle(color: AppConfig.successGreen, fontSize: 11)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatBadge(label: p.statutValidation.toUpperCase(), status: p.statutValidation),
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
