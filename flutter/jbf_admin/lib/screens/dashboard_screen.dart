import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/admin_models.dart';
import '../services/supabase_service.dart';
import '../widgets/kpi_card.dart';
import '../widgets/stat_badge.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<DevisItem> _devisList = [];
  List<MissionItem> _missionsList = [];
  List<PointageLog> _pointagesList = [];

  @override
  void initState() {
    super.initState();
    _loadLiveDatabaseData();
  }

  Future<void> _loadLiveDatabaseData() async {
    setState(() => _isLoading = true);
    final devis = await _supabase.fetchDevis();
    final missions = await _supabase.fetchMissions();
    final pointages = await _supabase.fetchPointages();

    if (!mounted) return;
    setState(() {
      _devisList = devis;
      _missionsList = missions;
      _pointagesList = pointages;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    final totalDevis = _devisList.length;
    final devisNouveaux = _devisList.where((d) => d.statut == 'nouveau').length;
    final missionsActives = _missionsList.where((m) => m.statut == 'en_cours').length;
    final effectifTotal = _missionsList.fold(0, (sum, m) => sum + m.effectif);
    final double caEstime = _devisList.fold(0.0, (sum, d) => sum + d.montantUsd);
    final alertesVpn = _pointagesList.where((p) => p.isVpn).length;

    return RefreshIndicator(
      onRefresh: _loadLiveDatabaseData,
      color: AppConfig.brandPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Welcome
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConfig.brandPink, AppConfig.brandPinkDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppConfig.brandPink.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SUPER DASHBOARD — DIRECTION GÉNÉRALE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Supervision Opérationnelle Nationale (RDC)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Données temps réel connectées à la base de données Supabase (PostgreSQL).',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.access_time_filled, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Lubumbashi GMT+2',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live KPI Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 550 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 2.1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    KpiCard(
                      title: 'Chiffre d\'Affaires Devis',
                      value: '\$${caEstime.toStringAsFixed(0)} USD',
                      subtitle: 'Montant total chiffré',
                      icon: Icons.monetization_on,
                      color: AppConfig.successGreen,
                      onTap: () => widget.onNavigate(1),
                    ),
                    KpiCard(
                      title: 'Demandes de Devis',
                      value: '$totalDevis ($devisNouveaux nouv.)',
                      subtitle: 'Directement depuis la BDD',
                      icon: Icons.request_quote,
                      color: AppConfig.brandPink,
                      onTap: () => widget.onNavigate(1),
                    ),
                    KpiCard(
                      title: 'Missions / Chantiers',
                      value: '$missionsActives active(s)',
                      subtitle: '$effectifTotal agent(s) mobilisé(s)',
                      icon: Icons.engineering,
                      color: const Color(0xFF0284C7),
                      onTap: () => widget.onNavigate(2),
                    ),
                    KpiCard(
                      title: 'Sécurité Pointage Anti-VPN',
                      value: '$alertesVpn Alerte(s)',
                      subtitle: alertesVpn > 0 ? 'Examen requis' : 'Tous pointages conformes',
                      icon: Icons.shield,
                      color: alertesVpn > 0 ? AppConfig.dangerRed : AppConfig.successGreen,
                      onTap: () => widget.onNavigate(3),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Two-column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Dernières Demandes de Devis (BDD)',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () => widget.onNavigate(1),
                                child: const Text('Voir tout'),
                              ),
                            ],
                          ),
                          const Divider(),
                          if (_devisList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(
                                child: Text('Aucune demande de devis dans la base de données.'),
                              ),
                            )
                          else
                            ..._devisList.take(4).map((d) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: AppConfig.brandPinkTint,
                                    child: const Icon(Icons.business, color: AppConfig.brandPink),
                                  ),
                                  title: Text(d.societe.isNotEmpty ? d.societe : d.nom,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text(
                                    '${d.services.join(", ")} • ${d.localite}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: StatBadge(label: d.statut.toUpperCase(), status: d.statut),
                                  onTap: () => widget.onNavigate(1),
                                )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Audit Pointages & IP (BDD)',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () => widget.onNavigate(3),
                                child: const Text('Gérer'),
                              ),
                            ],
                          ),
                          const Divider(),
                          if (_pointagesList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(
                                child: Text('Aucun pointage dans la base de données.'),
                              ),
                            )
                          else
                            ..._pointagesList.take(3).map((p) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: p.isVpn ? const Color(0xFFFEF2F2) : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: p.isVpn ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        p.isVpn ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                        color: p.isVpn ? AppConfig.dangerRed : AppConfig.successGreen,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.agentNom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            Text('${p.siteLieu} • ${p.ipAddress}',
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                          ],
                                        ),
                                      ),
                                      if (p.isVpn)
                                        const StatBadge(label: 'VPN DÉTECTÉ', status: 'alerte_vpn'),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
