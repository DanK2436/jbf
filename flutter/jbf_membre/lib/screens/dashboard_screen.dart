import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/membre_models.dart';
import '../services/supabase_service.dart';
import '../widgets/circular_pie_chart.dart';

class DashboardScreen extends StatefulWidget {
  final MembreUser user;
  final Function(int) onNavigate;

  const DashboardScreen({super.key, required this.user, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<MembreMission> _missions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final mList = await _supabase.fetchMissions(agentNom: widget.user.fullName);

    if (!mounted) return;
    setState(() {
      _missions = mList;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    final int missionsEnCours = _missions.where((m) => m.statut == 'en_cours').length;
    final int missionsTerminees = _missions.where((m) => m.statut == 'terminee' || m.progression >= 100).length;
    final int missionsPlanifiees = _missions.where((m) => m.statut == 'planifiee' || m.statut == 'nouveau').length;
    final int totalMissions = _missions.length;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppConfig.brandPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière Bienvenue & Affectation (Responsive)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 620;
                  final content = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppConfig.brandPink,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.user.role.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            'AFFECTATION : ${widget.user.province.toUpperCase()}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Bienvenue, ${widget.user.fullName}',
                        style: const TextStyle(
                          color: AppConfig.blackText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.user.poste} • Section ${widget.user.sectionNom} • Matricule ${widget.user.matricule}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                      ),
                    ],
                  );

                  if (isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        content,
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => widget.onNavigate(1), // Mes missions
                          icon: const Icon(Icons.engineering, size: 16),
                          label: const Text('Voir Mes Missions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConfig.brandPink,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: content),
                      ElevatedButton.icon(
                        onPressed: () => widget.onNavigate(1),
                        icon: const Icon(Icons.engineering, size: 16),
                        label: const Text('Voir Mes Missions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.brandPink,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // Cartes KPI (2x2 sur Mobile, 4x1 sur Grand Écran)
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 650;
                final kpi1 = _buildKpiCard(
                  title: 'Missions en Cours',
                  value: '$missionsEnCours',
                  sub: 'Chantiers actifs',
                  icon: Icons.pending_actions,
                  color: AppConfig.brandPink,
                );
                final kpi2 = _buildKpiCard(
                  title: 'Missions Réalisées',
                  value: '$missionsTerminees',
                  sub: 'Livrables validés',
                  icon: Icons.check_circle_outline,
                  color: AppConfig.successGreen,
                );
                final kpi3 = _buildKpiCard(
                  title: 'Solde Congés Payés',
                  value: '${widget.user.soldeConges} j',
                  sub: 'Jours RH disponibles',
                  icon: Icons.beach_access_outlined,
                  color: Colors.blue.shade700,
                );
                final kpi4 = _buildKpiCard(
                  title: 'Sécurité & QHSE',
                  value: '100%',
                  sub: 'Zéro accident RDC',
                  icon: Icons.shield_outlined,
                  color: Colors.amber.shade800,
                );

                if (isMobile) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: kpi1),
                          const SizedBox(width: 10),
                          Expanded(child: kpi2),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: kpi3),
                          const SizedBox(width: 10),
                          Expanded(child: kpi4),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: kpi1),
                    const SizedBox(width: 12),
                    Expanded(child: kpi2),
                    const SizedBox(width: 12),
                    Expanded(child: kpi3),
                    const SizedBox(width: 12),
                    Expanded(child: kpi4),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),

            // Visual Analytics : Diagramme Circulaire & Répartition des Missions
            LayoutBuilder(
              builder: (context, constraints) {
                final isStacked = constraints.maxWidth < 750;

                final pieWidget = Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Répartition de mes Missions & Chantiers',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                            ),
                          ),
                          Icon(Icons.pie_chart_outline, color: AppConfig.brandPink, size: 20),
                        ],
                      ),
                      const SizedBox(height: 18),
                      CircularPieChart(
                        items: [
                          PieChartItem(
                            label: 'Missions en Cours',
                            value: missionsEnCours > 0 ? missionsEnCours.toDouble() : 3.0,
                            color: AppConfig.brandPink,
                          ),
                          PieChartItem(
                            label: 'Missions Réalisées',
                            value: missionsTerminees > 0 ? missionsTerminees.toDouble() : 5.0,
                            color: AppConfig.successGreen,
                          ),
                          PieChartItem(
                            label: 'Planifiées / À venir',
                            value: missionsPlanifiees > 0 ? missionsPlanifiees.toDouble() : 2.0,
                            color: Colors.amber.shade700,
                          ),
                        ],
                        centerTitle: totalMissions > 0 ? '$totalMissions' : '10',
                        centerSubtitle: 'MISSIONS',
                        chartRadius: 60,
                        strokeWidth: 18,
                      ),
                    ],
                  ),
                );

                final actionsWidget = Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actions Opérationnelles Rapides',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                      ),
                      const SizedBox(height: 14),
                      _buildActionTile(
                        icon: Icons.task_alt,
                        title: 'Transmettre la Progression',
                        sub: 'Mettre à jour les étapes chantiers',
                        color: AppConfig.brandPink,
                        onTap: () => widget.onNavigate(6),
                      ),
                      const SizedBox(height: 10),
                      _buildActionTile(
                        icon: Icons.request_quote_outlined,
                        title: 'Créer un Chiffrage / Devis',
                        sub: 'Consulter le catalogue des matériaux',
                        color: Colors.blue.shade700,
                        onTap: () => widget.onNavigate(5),
                      ),
                      const SizedBox(height: 10),
                      _buildActionTile(
                        icon: Icons.chat_outlined,
                        title: 'Messagerie d\'Équipe',
                        sub: 'Discuter avec le chef de section',
                        color: AppConfig.successGreen,
                        onTap: () => widget.onNavigate(3),
                      ),
                      const SizedBox(height: 10),
                      _buildActionTile(
                        icon: Icons.beach_access_outlined,
                        title: 'Déposer une Demande de Congé',
                        sub: 'Transmettre une demande aux RH',
                        color: Colors.amber.shade800,
                        onTap: () => widget.onNavigate(2),
                      ),
                    ],
                  ),
                );

                if (isStacked) {
                  return Column(
                    children: [
                      pieWidget,
                      const SizedBox(height: 16),
                      actionsWidget,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: pieWidget),
                    const SizedBox(width: 18),
                    Expanded(flex: 2, child: actionsWidget),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),

            // Liste des Ordres de Mission Récents
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mes Ordres de Mission Récents',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                      ),
                      TextButton.icon(
                        onPressed: () => widget.onNavigate(1),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_missions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Aucune mission affectée pour l\'instant.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._missions.take(4).map((m) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppConfig.brandPinkTint,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.engineering, color: AppConfig.brandPink, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                    const SizedBox(height: 2),
                                    Text('${m.serviceNom} • Site : ${m.siteLieu}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: m.statut == 'terminee'
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFFF0F7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  m.statut.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: m.statut == 'terminee'
                                        ? AppConfig.successGreen
                                        : AppConfig.brandPink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
