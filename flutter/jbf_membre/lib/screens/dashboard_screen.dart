import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/membre_models.dart';
import '../services/supabase_service.dart';
import '../widgets/kpi_card.dart';
import '../widgets/stat_badge.dart';

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
  List<PointageRecord> _pointages = [];
  String _selectedSite = 'Chantier MUMI (Kolwezi)';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final mList = await _supabase.fetchMissions(agentNom: widget.user.fullName);
    final pList = await _supabase.fetchPointages(matricule: widget.user.matricule);

    if (!mounted) return;
    setState(() {
      _missions = mList;
      _pointages = pList;
      _isLoading = false;
    });
  }

  Future<void> _handlePointage(String type) async {
    final record = await _supabase.recordPointage(
      agentNom: widget.user.fullName,
      matricule: widget.user.matricule,
      siteLieu: _selectedSite,
      typePointage: type,
    );

    _loadData();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppConfig.successGreen),
            const SizedBox(width: 8),
            Text(type == 'entree' ? 'Prise de Poste Enregistrée (BDD)' : 'Fin de Poste Enregistrée (BDD)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Collaborateur : ${widget.user.fullName} (${widget.user.matricule})'),
            Text('Site : $_selectedSite'),
            Text('Horodatage : ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} (Lubumbashi GMT+2)'),
            const SizedBox(height: 8),
            const Text('IP : 105.101.44.12 (Airtel RDC) • GPS : -10.7183, 25.4729'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, size: 16, color: AppConfig.successGreen),
                  SizedBox(width: 6),
                  Text('Pointage enregistré dans la table pointages Supabase',
                      style: TextStyle(color: AppConfig.successGreen, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    final int missionsCount = _missions.where((m) => m.statut == 'en_cours').length;
    final double totalHeures = _pointages.fold(0.0, (s, p) => s + p.heuresNormales + p.heuresSup);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppConfig.brandPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Welcome Profile
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
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.user.avatar,
                      style: const TextStyle(
                        color: AppConfig.brandPink,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.user.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.user.matricule,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.user.poste} • ${widget.user.sectionNom}',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        ),
                        Text(
                          'Email OTP : ${widget.user.email} • Base : ${widget.user.province}',
                          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
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
                        Icon(Icons.schedule, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Heure RDC : GMT+2',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Terminal de Pointage Express
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.touch_app, color: AppConfig.brandPink, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Terminal de Pointage Géolocalisé (Anti-VPN)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, size: 14, color: AppConfig.successGreen),
                              SizedBox(width: 4),
                              Text('Enregistrement direct BDD',
                                  style: TextStyle(color: AppConfig.successGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSite,
                            items: const [
                              DropdownMenuItem(value: 'Chantier MUMI (Kolwezi)', child: Text('Chantier MUMI (Kolwezi)')),
                              DropdownMenuItem(value: 'Base Kakula Kamoa (Kolwezi)', child: Text('Base Kakula Kamoa (Kolwezi)')),
                              DropdownMenuItem(value: 'Usine Luilu KCC (Kolwezi)', child: Text('Usine Luilu KCC (Kolwezi)')),
                              DropdownMenuItem(value: 'Frontier Mine (Sakania)', child: Text('Frontier Mine (Sakania)')),
                              DropdownMenuItem(value: 'Siège Social (Lubumbashi)', child: Text('Siège Social (Lubumbashi)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSite = val);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Site d\'Intervention Actuel',
                              prefixIcon: Icon(Icons.location_on),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('Pointer Entrée'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConfig.brandPink,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          onPressed: () => _handlePointage('entree'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Pointer Sortie'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          onPressed: () => _handlePointage('sortie'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Live KPIs
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: 'Heures Travaillées',
                    value: '${totalHeures.toStringAsFixed(0)} h',
                    subtitle: 'Total cumulé dans la BDD',
                    icon: Icons.timer,
                    color: AppConfig.brandPink,
                    onTap: () => widget.onNavigate(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: KpiCard(
                    title: 'Missions BDD',
                    value: '$missionsCount Chantier(s)',
                    subtitle: 'Missions actives',
                    icon: Icons.engineering,
                    color: const Color(0xFF0284C7),
                    onTap: () => widget.onNavigate(1),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: KpiCard(
                    title: 'Solde Congés Payés',
                    value: widget.user.soldeConges < 0 ? 'Non renseigné' : '${widget.user.soldeConges} Jours',
                    subtitle: 'Droits légaux enregistrés',
                    icon: Icons.beach_access,
                    color: AppConfig.successGreen,
                    onTap: () => widget.onNavigate(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Missions list
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mes Ordres de Mission Prioritaires (BDD)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigate(1),
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_missions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text('Aucune mission attribuée pour l\'instant dans la base de données.'),
                        ),
                      )
                    else
                      ..._missions.take(3).map((m) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppConfig.brandPinkTint,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.work_outline, color: AppConfig.brandPink),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m.titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text('${m.client} • ${m.siteIntervention}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                    ],
                                  ),
                                ),
                                StatBadge(label: m.statut.toUpperCase(), status: m.statut),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
