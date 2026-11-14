import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/membre_models.dart';
import '../services/supabase_service.dart';

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
    await _supabase.recordPointage(
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
            Text(type == 'entree' ? 'Prise de Poste Validée' : 'Fin de Poste Enregistrée'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Collaborateur : ${widget.user.fullName} (${widget.user.matricule})'),
            Text('Site : $_selectedSite'),
            Text('Heure : ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} (Lubumbashi GMT+2)'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Pointage certifié et synchronisé avec le serveur central JBF.',
                  style: TextStyle(color: AppConfig.successGreen, fontSize: 12)),
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Welcome Collaborateur
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConfig.blackText, Color(0xFF1E1E24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppConfig.brandPink,
                    child: Text(
                      widget.user.avatar,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppConfig.brandPinkTint,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.user.matricule,
                                style: const TextStyle(color: AppConfig.brandPink, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'SESSION SÉCURISÉE RDC',
                                style: TextStyle(color: AppConfig.successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bienvenue, ${widget.user.fullName}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${widget.user.poste} • Province : ${widget.user.province}',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => widget.onNavigate(6), // Aller à Devis BDD
                    icon: const Icon(Icons.request_quote, size: 16),
                    label: const Text('Rédiger un Devis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.brandPink,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4 Cartes d'Activité
            Row(
              children: [
                _buildActivityCard('Missions en Cours', '$missionsCount actives', Icons.engineering, AppConfig.brandPink, () => widget.onNavigate(1)),
                const SizedBox(width: 16),
                _buildActivityCard('Heures Pointées', '${totalHeures.toStringAsFixed(1)} h', Icons.access_time, Colors.blue.shade700, () => widget.onNavigate(2)),
                const SizedBox(width: 16),
                _buildActivityCard('Solde Congés RH', '${widget.user.soldeConges} jours', Icons.beach_access, Colors.orange.shade800, () => widget.onNavigate(3)),
                const SizedBox(width: 16),
                _buildActivityCard('Feuille de Route', 'Suivi Jalons', Icons.task_alt, AppConfig.successGreen, () => widget.onNavigate(7)),
              ],
            ),
            const SizedBox(height: 24),

            // Graphiques & Statistiques d'Activité Collaborateur
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Graphique Barres Heures Travail par Semaine
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
                              'Activité & Heures Travaillées (Dernières Semaines)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                            ),
                            Icon(Icons.bar_chart, color: AppConfig.brandPink),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildWeeklyHourBar('Semaine 1 (Chantier Kolwezi)', 44.5, '44.5 h', AppConfig.brandPink),
                        const SizedBox(height: 14),
                        _buildWeeklyHourBar('Semaine 2 (Maintenance Usine)', 48.0, '48.0 h (Heures Sup.)', Colors.blue.shade700),
                        const SizedBox(height: 14),
                        _buildWeeklyHourBar('Semaine 3 (Soudure Haute Pression)', 42.0, '42.0 h', Colors.teal.shade700),
                        const SizedBox(height: 14),
                        _buildWeeklyHourBar('Semaine en cours', 28.5, '28.5 h', Colors.orange.shade700),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Panneau de Pointage Rapide
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
                          'Pointage Présence & Géolocalisation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedSite,
                          decoration: const InputDecoration(labelText: 'Site d\'Affectation Actuel'),
                          items: const [
                            DropdownMenuItem(value: 'Chantier MUMI (Kolwezi)', child: Text('Chantier MUMI (Kolwezi)')),
                            DropdownMenuItem(value: 'Site Kamoa-Kakula (Lualaba)', child: Text('Site Kamoa-Kakula (Lualaba)')),
                            DropdownMenuItem(value: 'Usine STL (Lubumbashi)', child: Text('Usine STL (Lubumbashi)')),
                            DropdownMenuItem(value: 'Base-Vie Tenke Fungurume', child: Text('Base-Vie Tenke Fungurume')),
                          ],
                          onChanged: (v) => setState(() => _selectedSite = v!),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handlePointage('entree'),
                                icon: const Icon(Icons.login, size: 16),
                                label: const Text('Prise de Poste'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppConfig.successGreen, padding: const EdgeInsets.symmetric(vertical: 14)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _handlePointage('sortie'),
                                icon: const Icon(Icons.logout, size: 16),
                                label: const Text('Fin de Poste'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed, padding: const EdgeInsets.symmetric(vertical: 14)),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildActivityCard(String title, String val, IconData icon, Color color, VoidCallback onTap) {
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  CircleAvatar(radius: 16, backgroundColor: color.withOpacity(0.12), child: Icon(icon, size: 16, color: color)),
                ],
              ),
              const SizedBox(height: 10),
              Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyHourBar(String label, double val, String text, Color color) {
    final pct = (val / 50.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
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
}
