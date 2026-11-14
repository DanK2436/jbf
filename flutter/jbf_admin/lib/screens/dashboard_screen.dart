import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/admin_models.dart';
import '../services/supabase_service.dart';
import '../services/otp_service.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  String? _otpConfiguredEmail;
  List<DevisItem> _devisList = [];
  List<MissionItem> _missionsList = [];
  List<PointageLog> _pointagesList = [];

  // Statistiques financières V2
  double _caTotalEncaisse = 142500.0;
  double _depensesMois = 51200.0;
  int _totalUtilisateurs = 0;

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
    final otpEmail = await OtpService().getConfiguredOtpEmail();

    // Compter les utilisateurs réels
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?select=id'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        _totalUtilisateurs = list.length;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _devisList = devis;
      _missionsList = missions;
      _pointagesList = pointages;
      _otpConfiguredEmail = otpEmail;
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
    final alertesVpn = _pointagesList.where((p) => p.isVpn).length;

    return RefreshIndicator(
      onRefresh: _loadLiveDatabaseData,
      color: AppConfig.brandPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Direction Exécutive
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConfig.blackText, Color(0xFF1E1E24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppConfig.brandPink,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'DIRECTION GÉNÉRALE RDC',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'SUPERVISION MULTI-PROVINCES EN TEMPS RÉEL',
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'JBF Service SARL — Tableau de Bord Stratégique',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mines & Énergie (Katanga / Lualaba) • BTP & Génie Civil • Catering Industriel • 26 Provinces',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => widget.onNavigate(7), // Aller à finances
                    icon: const Icon(Icons.receipt_long, size: 16),
                    label: const Text('Émettre un Reçu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.brandPink,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4 KPIs Majeurs
            Row(
              children: [
                _buildMetricCard(
                  'Trésorerie & Encaissements',
                  '${_caTotalEncaisse.toStringAsFixed(0)} USD',
                  '+18.4% ce mois',
                  Icons.payments_outlined,
                  AppConfig.successGreen,
                  () => widget.onNavigate(7),
                ),
                const SizedBox(width: 16),
                _buildMetricCard(
                  'Missions & Chantiers Actifs',
                  '$missionsActives en cours',
                  '$effectifTotal agents déployés',
                  Icons.engineering_outlined,
                  AppConfig.brandPink,
                  () => widget.onNavigate(2),
                ),
                const SizedBox(width: 16),
                _buildMetricCard(
                  'Comptes & Utilisateurs',
                  '$_totalUtilisateurs inscrits',
                  'Clients, Membres & Admins',
                  Icons.people_alt_outlined,
                  Colors.blue.shade700,
                  () => widget.onNavigate(1),
                ),
                const SizedBox(width: 16),
                _buildMetricCard(
                  'Devis & Nouvelles Commandes',
                  '$totalDevis demandes',
                  '$devisNouveaux en attente de cotation',
                  Icons.request_quote_outlined,
                  Colors.orange.shade800,
                  () => widget.onNavigate(4),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Raccourcis d'Actions Rapides
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(Icons.person_add_outlined, 'Utilisateurs', () => widget.onNavigate(1)),
                  _buildQuickAction(Icons.account_tree_outlined, 'Projets WBS', () => widget.onNavigate(2)),
                  _buildQuickAction(Icons.handyman_outlined, 'Services (15)', () => widget.onNavigate(5)),
                  _buildQuickAction(Icons.badge_outlined, 'RH & Compétences', () => widget.onNavigate(6)),
                  _buildQuickAction(Icons.account_balance_outlined, 'Finance & Factures', () => widget.onNavigate(7)),
                  _buildQuickAction(Icons.campaign_outlined, 'CMS & Diffusion', () => widget.onNavigate(8)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Visual Analytics: Répartition Sectorielle & Géographique
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne Gauche : Répartition par Secteur
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(22),
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
                            Text(
                              'Répartition de l\'Activité par Secteur',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                            ),
                            Icon(Icons.pie_chart_outline, color: AppConfig.brandPink, size: 20),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildSectorBar('Sous-traitance Minière & Extraction', 0.52, '52%', AppConfig.brandPink),
                        const SizedBox(height: 14),
                        _buildSectorBar('BTP, Génie Civil & Construction', 0.24, '24%', Colors.blue.shade700),
                        const SizedBox(height: 14),
                        _buildSectorBar('Catering Industriel & Base-Vie', 0.14, '14%', Colors.orange.shade700),
                        const SizedBox(height: 14),
                        _buildSectorBar('Maintenance Industrielle & Usinage', 0.10, '10%', Colors.teal.shade700),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Colonne Droite : Provinces & Alertes
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Activité par Province (RDC)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                        ),
                        const SizedBox(height: 16),
                        _buildProvinceTile('Haut-Katanga (Lubumbashi, Likasi)', '45%', AppConfig.brandPink),
                        _buildProvinceTile('Lualaba (Kolwezi, Fungurume)', '38%', Colors.blue.shade700),
                        _buildProvinceTile('Kinshasa & Kongo Central', '12%', Colors.teal.shade700),
                        _buildProvinceTile('Nord-Kivu & Haut-Uele', '5%', Colors.orange.shade700),
                      ],
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

  Widget _buildMetricCard(String title, String val, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  CircleAvatar(radius: 16, backgroundColor: color.withOpacity(0.12), child: Icon(icon, size: 16, color: color)),
                ],
              ),
              const SizedBox(height: 10),
              Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText)),
              const SizedBox(height: 4),
              Text(sub, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppConfig.brandPinkTint,
              child: Icon(icon, color: AppConfig.brandPink, size: 20),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorBar(String title, double pct, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.grey.shade100,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProvinceTile(String name, String pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontSize: 12.5)),
            ],
          ),
          Text(pct, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
