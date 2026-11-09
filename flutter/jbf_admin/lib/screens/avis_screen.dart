import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/admin_models.dart';
import '../services/supabase_service.dart';
import '../widgets/stat_badge.dart';

class AvisScreen extends StatefulWidget {
  const AvisScreen({super.key});

  @override
  State<AvisScreen> createState() => _AvisScreenState();
}

class _AvisScreenState extends State<AvisScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<AvisItem> _avisList = [];

  @override
  void initState() {
    super.initState();
    _loadAvis();
  }

  Future<void> _loadAvis() async {
    setState(() => _isLoading = true);
    final list = await _supabase.fetchAvis();
    if (!mounted) return;
    setState(() {
      _avisList = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    return RefreshIndicator(
      onRefresh: _loadAvis,
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
                    const Text('Modération des Avis & Témoignages Clients (BDD)',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Données réelles de la table avis_clients Supabase',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                  tooltip: 'Actualiser',
                  onPressed: _loadAvis,
                ),
              ],
            ),
            const SizedBox(height: 18),

            Expanded(
              child: _avisList.isEmpty
                  ? const Center(child: Text('Aucun avis client dans la base de données.'))
                  : ListView.builder(
                      itemCount: _avisList.length,
                      itemBuilder: (context, index) {
                        final a = _avisList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppConfig.brandPinkTint,
                                  child: Text('${a.note}★', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConfig.brandPink)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('${a.nom} (${a.entreprise})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          const SizedBox(width: 10),
                                          StatBadge(
                                            label: a.approuve ? 'EN LIGNE' : 'MASQUÉ',
                                            status: a.approuve ? 'valide' : 'rejete',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Prestation : ${a.service}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                      const SizedBox(height: 6),
                                      Text('« ${a.commentaire} »', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        a.approuve ? Icons.visibility_off : Icons.visibility,
                                        color: a.approuve ? Colors.grey : AppConfig.brandPink,
                                      ),
                                      tooltip: a.approuve ? 'Masquer dans Supabase' : 'Publier dans Supabase',
                                      onPressed: () async {
                                        await _supabase.toggleAvisApprouve(a.id, !a.approuve);
                                        _loadAvis();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppConfig.dangerRed),
                                      tooltip: 'Supprimer de Supabase',
                                      onPressed: () async {
                                        await _supabase.deleteAvis(a.id);
                                        _loadAvis();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
