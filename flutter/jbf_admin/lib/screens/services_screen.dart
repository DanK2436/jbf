import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _services = [];
  String _filterCategorie = 'toutes';

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final url = '${AppConfig.supabaseUrl}/rest/v1/services_catalogue?select=*&order=ordre_affichage.asc';
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (mounted) {
          setState(() {
            _services = list.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Erreur chargement services: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleServiceActive(Map<String, dynamic> srv) async {
    final bool currentStatus = srv['est_actif'] == true;
    final bool newStatus = !currentStatus;
    final srvId = srv['id'];

    setState(() {
      srv['est_actif'] = newStatus;
    });

    try {
      final url = '${AppConfig.supabaseUrl}/rest/v1/services_catalogue?id=eq.$srvId';
      await http.patch(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'est_actif': newStatus}),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'Service activé sur le catalogue.' : 'Service désactivé du catalogue public.'),
          backgroundColor: newStatus ? AppConfig.successGreen : Colors.orange,
        ),
      );
    } catch (e) {
      setState(() {
        srv['est_actif'] = currentStatus;
      });
    }
  }

  Future<void> _deleteService(Map<String, dynamic> srv) async {
    final srvId = srv['id'];
    final srvTitre = srv['titre'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce service'),
        content: Text('Voulez-vous supprimer définitivement "$srvTitre" du catalogue officiel ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final url = '${AppConfig.supabaseUrl}/rest/v1/services_catalogue?id=eq.$srvId';
      await http.delete(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      );
      setState(() {
        _services.removeWhere((s) => s['id'] == srvId);
      });
    } catch (_) {}
  }

  void _showEditServiceDialog([Map<String, dynamic>? srv]) {
    final isEdit = srv != null;
    final titleCtrl = TextEditingController(text: srv?['titre'] ?? '');
    final catCtrl = TextEditingController(text: srv?['categorie'] ?? 'Industrie & Mines');
    final descShortCtrl = TextEditingController(text: srv?['description_courte'] ?? '');
    final descFullCtrl = TextEditingController(text: srv?['description_complete'] ?? '');
    final tarifCtrl = TextEditingController(text: srv?['tarification_indicative'] ?? 'Sur devis');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(isEdit ? Icons.edit : Icons.add_business, color: AppConfig.brandPink),
            const SizedBox(width: 8),
            Text(isEdit ? 'Modifier le Service' : 'Ajouter un Nouveau Service'),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titre de la prestation *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: catCtrl,
                  decoration: const InputDecoration(labelText: 'Catégorie *', hintText: 'ex: Génie Civil, Maintenance...'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descShortCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description courte (Vitrine Web) *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descFullCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Détails techniques complets'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tarifCtrl,
                  decoration: const InputDecoration(labelText: 'Tarification indicative / Conditions'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
            onPressed: () async {
              if (titleCtrl.text.isEmpty || descShortCtrl.text.isEmpty) return;
              Navigator.of(ctx).pop();

              final payload = {
                'titre': titleCtrl.text.trim(),
                'categorie': catCtrl.text.trim(),
                'description_courte': descShortCtrl.text.trim(),
                'description_complete': descFullCtrl.text.trim(),
                'tarification_indicative': tarifCtrl.text.trim(),
                'updated_at': DateTime.now().toIso8601String(),
              };

              try {
                if (isEdit) {
                  final srvId = srv['id'];
                  await http.patch(
                    Uri.parse('${AppConfig.supabaseUrl}/rest/v1/services_catalogue?id=eq.$srvId'),
                    headers: {
                      'apikey': AppConfig.supabaseAnonKey,
                      'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode(payload),
                  );
                } else {
                  payload['code_service'] = 'SRV-${Date.now().toString().slice(-4)}';
                  payload['est_actif'] = true;
                  await http.post(
                    Uri.parse('${AppConfig.supabaseUrl}/rest/v1/services_catalogue'),
                    headers: {
                      'apikey': AppConfig.supabaseAnonKey,
                      'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode(payload),
                  );
                }
                _loadServices();
              } catch (_) {}
            },
            child: Text(isEdit ? 'Enregistrer les modifications' : 'Créer le service'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catalogue Dynamique des Services JBF',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText),
                      ),
                      Text(
                        'Activez, modifiez, désactivez ou supprimez les 15 prestations proposées sur le site public et l\'espace client',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showEditServiceDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouveau Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.brandPink,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Services Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
                : _services.isEmpty
                    ? const Center(child: Text('Aucun service enregistré dans le catalogue.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: _services.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final s = _services[index];
                          final bool isActif = s['est_actif'] == true;
                          final code = s['code_service'] ?? 'SRV';
                          final titre = s['titre'] ?? 'Service JBF';
                          final cat = s['categorie'] ?? 'Industrie';
                          final desc = s['description_courte'] ?? '';
                          final tarif = s['tarification_indicative'] ?? 'Sur devis';

                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActif ? Colors.grey.shade200 : const Color(0xFFFCA5A5),
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isActif ? AppConfig.brandPinkTint : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.handyman_outlined,
                                      color: isActif ? AppConfig.brandPink : Colors.grey.shade500,
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
                                            titre,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: isActif ? AppConfig.blackText : Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              code,
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              cat,
                                              style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        desc,
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tarif / Base : $tarif',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    Switch(
                                      value: isActif,
                                      activeColor: AppConfig.brandPink,
                                      onChanged: (_) => _toggleServiceActive(s),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                      tooltip: 'Modifier la description',
                                      onPressed: () => _showEditServiceDialog(s),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppConfig.dangerRed),
                                      tooltip: 'Supprimer du catalogue',
                                      onPressed: () => _deleteService(s),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
