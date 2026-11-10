import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../models/client_models.dart';
import '../services/client_data_service.dart';
import '../widgets/kpi_card.dart';
import '../widgets/stat_badge.dart';

class DashboardScreen extends StatefulWidget {
  final ClientUser client;
  final Function(int) onNavigate;

  const DashboardScreen({
    super.key,
    required this.client,
    required this.onNavigate,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dataService = ClientDataService();
  bool _isLoading = true;
  List<ClientDevis> _devisList = [];
  List<ClientMission> _missionsList = [];
  List<ClientFacture> _facturesList = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final devis = await _dataService.fetchDevis(clientEmail: widget.client.email);
    final missions = await _dataService.fetchMissions();
    final factures = await _dataService.fetchFactures();

    if (!mounted) return;
    setState(() {
      _devisList = devis;
      _missionsList = missions;
      _facturesList = factures;
      _isLoading = false;
    });
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/243970349724?text=Bonjour%20JBF%20Service,%20je%20suis%20${Uri.encodeComponent(widget.client.companyName)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    final totalDevis = _devisList.length;
    final activesMissions = _missionsList.where((m) => m.statut == 'en_cours').length;
    final facturesPayees = _facturesList.where((f) => f.statut == 'payee').length;
    final double montantEngage = _devisList.fold(0.0, (sum, d) => sum + d.montantEstime);

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppConfig.brandPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConfig.brandPink, AppConfig.brandPinkDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppConfig.brandPink.withOpacity(0.3),
                    blurRadius: 12,
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ESPACE CLIENT PARTENAIRE',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.verified, color: Colors.white, size: 16),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.client.companyName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Interlocuteur : ${widget.client.fullName} • ${widget.client.site}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppConfig.brandPink,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => widget.onNavigate(1), // Navigue vers Devis
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Nouveau Devis', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // KPI Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: constraints.maxWidth > 900 ? 1.7 : 2.0,
                  children: [
                    KpiCard(
                      title: 'Devis & Demandes',
                      value: '$totalDevis dossier(s)',
                      subtitle: 'Budget estimé : \$${(montantEngage / 1000).toStringAsFixed(1)}k USD',
                      icon: Icons.request_quote_outlined,
                      color: AppConfig.brandPink,
                      onTap: () => widget.onNavigate(1),
                    ),
                    KpiCard(
                      title: 'Chantiers en Exécution',
                      value: '$activesMissions actif(s)',
                      subtitle: 'Supervision terrain JBF RDC',
                      icon: Icons.engineering_outlined,
                      color: const Color(0xFF0284C7),
                      onTap: () => widget.onNavigate(2),
                    ),
                    KpiCard(
                      title: 'Règlements & Factures',
                      value: '$facturesPayees acquittée(s)',
                      subtitle: '${_facturesList.length} facture(s) enregistrée(s)',
                      icon: Icons.receipt_long_outlined,
                      color: AppConfig.successGreen,
                      onTap: () => widget.onNavigate(3),
                    ),
                    KpiCard(
                      title: 'Qualité & Agrément',
                      value: '100% ARSP',
                      subtitle: 'Norme HACCP & ISO 45001',
                      icon: Icons.workspace_premium_outlined,
                      color: const Color(0xFFD97706),
                      onTap: () => widget.onNavigate(4),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Missions Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.precision_manufacturing, color: AppConfig.brandPink),
                            SizedBox(width: 8),
                            Text(
                              'Suivi en Temps Réel de vos Chantiers JBF',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigate(2),
                          child: const Text('Voir tous les chantiers →'),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_missionsList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('Aucun chantier actif pour le moment.')),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _missionsList.take(3).length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (context, idx) {
                          final m = _missionsList[idx];
                          return Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppConfig.brandPink.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.handyman, color: AppConfig.brandPink, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.titre,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      '${m.site} • Resp : ${m.chef}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: m.avancement / 100.0,
                                        backgroundColor: Colors.grey.shade200,
                                        color: AppConfig.brandPink,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${m.avancement}%',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppConfig.brandPink),
                                  ),
                                  StatBadge(
                                    label: m.statut == 'termine' ? 'Terminé' : 'En cours',
                                    color: m.statut == 'termine' ? AppConfig.successGreen : const Color(0xFF0284C7),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Recent Quotes Table
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.description_outlined, color: AppConfig.brandPink),
                            SizedBox(width: 8),
                            Text(
                              'Dernières Demandes de Devis & Proformas',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigate(1),
                          child: const Text('Gérer mes devis →'),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_devisList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('Aucun devis enregistré.')),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _devisList.take(3).length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (context, idx) {
                          final d = _devisList[idx];
                          final isValide = d.statut == 'valide';
                          return Row(
                            children: [
                              Text(
                                d.reference,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConfig.blackText),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.service, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text('${d.site} • ${d.date}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (d.montantEstime > 0)
                                Text(
                                  '\$${d.montantEstime.toStringAsFixed(0)} USD',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              const SizedBox(width: 12),
                              StatBadge(
                                label: isValide ? 'Validé' : (d.statut == 'en_cours' ? 'En étude' : 'Nouveau'),
                                color: isValide ? AppConfig.successGreen : AppConfig.brandPink,
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Hotline Assistance Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConfig.whatsappGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chat, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Besoin d\'une intervention urgente ou d\'un superviseur ?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF14532D)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Service Client direct JBF Services disponible 24/7 sur WhatsApp et par ligne directe.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.whatsappGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _openWhatsApp,
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Contacter sur WhatsApp'),
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
