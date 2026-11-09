import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/admin_models.dart';
import '../services/supabase_service.dart';
import '../widgets/stat_badge.dart';

class PointagesScreen extends StatefulWidget {
  const PointagesScreen({super.key});

  @override
  State<PointagesScreen> createState() => _PointagesScreenState();
}

class _PointagesScreenState extends State<PointagesScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<PointageLog> _pointages = [];
  bool _onlyVpnAlerts = false;

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

  List<PointageLog> get _filteredPointages {
    if (_onlyVpnAlerts) {
      return _pointages.where((p) => p.isVpn).toList();
    }
    return _pointages;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    final pointages = _filteredPointages;

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
                    const Text('Contrôle des Pointages & Sécurité Anti-VPN (BDD)',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Données réelles de la table pointages Supabase',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Seulement Alertes VPN'),
                      selected: _onlyVpnAlerts,
                      selectedColor: const Color(0xFFFEE2E2),
                      checkmarkColor: AppConfig.dangerRed,
                      onSelected: (val) => setState(() => _onlyVpnAlerts = val),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                      tooltip: 'Actualiser',
                      onPressed: _loadPointages,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: pointages.isEmpty
                      ? const Center(
                          child: Text('Aucun relevé de pointage dans la base de données.'),
                        )
                      : ListView.separated(
                          itemCount: pointages.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final p = pointages[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: p.isVpn ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      p.isVpn ? Icons.shield_outlined : Icons.verified_user,
                                      color: p.isVpn ? AppConfig.dangerRed : AppConfig.successGreen,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.agentNom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        Text('Matricule : ${p.matricule} • ${p.siteLieu}',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.typePointage == 'entree' ? 'POINTAGE ENTRÉE' : 'POINTAGE SORTIE',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: p.typePointage == 'entree' ? AppConfig.brandPink : Colors.orange.shade800,
                                          ),
                                        ),
                                        Text('${p.dateHeure.hour.toString().padLeft(2, '0')}:${p.dateHeure.minute.toString().padLeft(2, '0')} (Lubumbashi)',
                                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              p.isVpn ? Icons.vpn_lock : Icons.public,
                                              size: 14,
                                              color: p.isVpn ? AppConfig.dangerRed : Colors.grey.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text('IP : ${p.ipAddress}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: p.isVpn ? FontWeight.bold : FontWeight.normal,
                                                  color: p.isVpn ? AppConfig.dangerRed : Colors.grey.shade800,
                                                )),
                                          ],
                                        ),
                                        Text('GPS : ${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                  StatBadge(
                                    label: p.isVpn ? 'ALERTE VPN' : 'IP CONFORME',
                                    status: p.isVpn ? 'alerte_vpn' : 'valide',
                                  ),
                                  const SizedBox(width: 14),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle, color: AppConfig.successGreen),
                                        tooltip: 'Valider dans la BDD',
                                        onPressed: () async {
                                          await _supabase.updatePointageStatut(p.id, 'valide');
                                          _loadPointages();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Pointage de ${p.agentNom} validé dans Supabase')),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel, color: AppConfig.dangerRed),
                                        tooltip: 'Rejeter / Suspect',
                                        onPressed: () async {
                                          await _supabase.updatePointageStatut(p.id, 'rejete');
                                          _loadPointages();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Pointage de ${p.agentNom} marqué rejeté dans Supabase')),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
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
