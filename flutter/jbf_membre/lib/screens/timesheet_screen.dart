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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mes Feuilles de Temps & Pointages',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Relevé des heures travaillées et conformité anti-VPN',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                  tooltip: 'Actualiser',
                  onPressed: _loadPointages,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary Cards (Responsive on Mobile)
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final card1 = Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('HEURES NORMALES',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('${totalNormales.toStringAsFixed(0)} h',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
                        const Text('Base 8h / jour ouvré', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
                final card2 = Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('HEURES SUPPLÉMENTAIRES',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('${totalSup.toStringAsFixed(0)} h',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConfig.brandPink)),
                        const Text('Dépassement chantier', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
                final card3 = Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CONTRÔLE ANTI-VPN',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        SizedBox(height: 4),
                        Text('Conforme',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConfig.successGreen)),
                        Text('Traçabilité IP auditée', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                      ],
                    ),
                  ),
                );

                if (isMobile) {
                  return Column(
                    children: [
                      card1,
                      const SizedBox(height: 8),
                      card2,
                      const SizedBox(height: 8),
                      card3,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: card1),
                    const SizedBox(width: 12),
                    Expanded(child: card2),
                    const SizedBox(width: 12),
                    Expanded(child: card3),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: _pointages.isEmpty
                      ? const Center(child: Text('Aucun pointage trouvé dans la table pointages.'))
                      : ListView.separated(
                          itemCount: _pointages.length,
                          separatorBuilder: (_, __) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final p = _pointages[index];
                            final isEntree = p.typePointage == 'entree';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isEntree ? AppConfig.brandPinkTint : const Color(0xFFFEF3C7),
                                      child: Icon(
                                        isEntree ? Icons.login : Icons.logout,
                                        color: isEntree ? AppConfig.brandPink : Colors.orange.shade800,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isEntree ? 'PRISE DE POSTE (ENTRÉE)' : 'FIN DE POSTE (SORTIE)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              color: isEntree ? AppConfig.brandPinkDark : Colors.orange.shade900,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${p.dateHeure.day}/${p.dateHeure.month}/${p.dateHeure.year} à ${p.dateHeure.hour.toString().padLeft(2, '0')}:${p.dateHeure.minute.toString().padLeft(2, '0')} • Site : ${p.siteLieu}',
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
                                        const SizedBox(width: 10),
                                        const Icon(Icons.shield, color: AppConfig.successGreen, size: 13),
                                        const SizedBox(width: 4),
                                        const Text('Anti-VPN Conforme', style: TextStyle(color: AppConfig.successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    StatBadge(label: p.statutValidation.toUpperCase(), status: p.statutValidation),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                ),
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
