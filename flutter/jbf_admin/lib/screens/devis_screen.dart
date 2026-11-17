import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/admin_models.dart';
import '../services/supabase_service.dart';
import '../widgets/stat_badge.dart';
import 'client_chat_admin_screen.dart';

class DevisScreen extends StatefulWidget {
  const DevisScreen({super.key});

  @override
  State<DevisScreen> createState() => _DevisScreenState();
}

class _DevisScreenState extends State<DevisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<DevisItem> _devisClients = [];
  List<Map<String, dynamic>> _devisMembres = [];
  String _selectedFilter = 'tous';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllDevis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllDevis() async {
    setState(() => _isLoading = true);
    final list = await _supabase.fetchDevis();

    // 1. Charger les devis soumis par les membres depuis devis_membres
    List<Map<String, dynamic>> membresList = [];
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/devis_membres?select=*&order=created_at.desc'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final l = jsonDecode(res.body) as List;
        membresList = l.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}

    // 2. Extraire également les devis membres reçus via demandes_devis
    final clientOnlyList = <DevisItem>[];
    for (final d in list) {
      final isMembreDevis = d.statut == 'transmis_admin' ||
          d.societe.startsWith('JBF Terrain') ||
          d.services.any((s) => s.toLowerCase().contains('devis membre')) ||
          d.message.toLowerCase().contains('chiffré par') ||
          d.message.toLowerCase().contains('chiffrage officiel');

      if (isMembreDevis) {
        // Ajouter dans la liste des devis membres si pas déjà présent
        final alreadyIn = membresList.any((m) => (m['numero_devis'] ?? m['id']) == d.id);
        if (!alreadyIn) {
          membresList.add({
            'id': d.id,
            'numero_devis': d.id.startsWith('DEV-') ? d.id : 'DEV-MBR-${d.id.substring(0, d.id.length > 8 ? 8 : d.id.length)}',
            'nom_collaborateur': d.nom,
            'nom_client': d.societe.replaceFirst('JBF Terrain — ', '').replaceFirst('JBF Terrain - ', ''),
            'projet_prestation': d.services.isNotEmpty ? d.services.first.replaceFirst('Devis Membre: ', '') : 'Prestation Terrain',
            'site_intervention': d.localite,
            'total_ht': d.montantUsd,
            'devise': 'USD',
            'statut': d.statut,
            'notes_direction': d.message,
            'created_at': d.createdAt.toIso8601String(),
          });
        }
      } else {
        clientOnlyList.add(d);
      }
    }

    if (!mounted) return;
    setState(() {
      _devisClients = clientOnlyList;
      _devisMembres = membresList;
      _isLoading = false;
    });
  }

  void _showValiderDevisMembreDialog(Map<String, dynamic> devis) {
    final margeCtrl = TextEditingController(text: '20');
    final totalHt = (devis['total_ht'] as num?)?.toDouble() ?? 0.0;
    double margePct = 20.0;
    double prixFinal = totalHt * (1 + margePct / 100);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.verified, color: AppConfig.brandPink),
              const SizedBox(width: 8),
              Text('Valider & Transmettre au Client — ${devis['numero_devis'] ?? 'Devis'}'),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Projet : ${devis['projet_prestation'] ?? 'Prestation'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Client destinataire : ${devis['nom_client'] ?? 'Client'}'),
                Text('Collaborateur / Auteur : ${devis['nom_collaborateur'] ?? 'Membre JBF'}'),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Coût des Matériaux & MO (Membre) :'),
                    Text('${totalHt.toStringAsFixed(2)} USD', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: margeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Marge Commerciale JBF (%)', suffixText: '%'),
                  onChanged: (val) {
                    final p = double.tryParse(val) ?? 0.0;
                    setDlgState(() {
                      margePct = p;
                      prixFinal = totalHt * (1 + margePct / 100);
                    });
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConfig.brandPinkTint,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppConfig.brandPink.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Prix Final Facturé au Client :', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${prixFinal.toStringAsFixed(2)} USD',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.brandPink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  final devisId = devis['id'];
                  await http.patch(
                    Uri.parse('${AppConfig.supabaseUrl}/rest/v1/devis_membres?id=eq.$devisId'),
                    headers: {
                      'apikey': AppConfig.supabaseAnonKey,
                      'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'statut': 'transmis_client',
                      'marge_appliquee_pct': margePct,
                      'prix_final_client': prixFinal,
                      'updated_at': DateTime.now().toIso8601String(),
                    }),
                  );
                  _loadAllDevis();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Devis validé et expédié au client avec la marge appliquée !'),
                      backgroundColor: AppConfig.successGreen,
                    ),
                  );
                } catch (_) {}
              },
              child: const Text('Valider & Transmettre au Client'),
            ),
          ],
        ),
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
                        'Gestion & Chiffrage des Devis',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText),
                      ),
                      Text(
                        'Traitement des demandes clients & Réception des devis chiffrés par les membres de terrain',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppConfig.brandPink,
                  labelColor: AppConfig.brandPink,
                  unselectedLabelColor: Colors.grey.shade600,
                  tabs: [
                    Tab(icon: const Icon(Icons.inbox), text: 'Demandes Clients Directes (${_devisClients.length})'),
                    Tab(icon: const Icon(Icons.engineering), text: 'Devis Reçus des Membres (${_devisMembres.length})'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1 : Devis Clients Directs
                      _buildClientsTab(),

                      // TAB 2 : Devis Membres
                      _buildMembresTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _accepterDevisClient(DevisItem d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppConfig.successGreen),
            SizedBox(width: 8),
            Text('Accepter cette Demande de Devis'),
          ],
        ),
        content: Text(
          'Accepter la demande de ${d.nom} (${d.societe}) ?\n\nCela va passer le statut à "Accepté" et ouvrir automatiquement une conversation avec le client pour lui transmettre les devis et partager les fichiers.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.successGreen),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Accepter & Ouvrir la Conversation'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 1. Mettre à jour le statut dans demandes_devis
    try {
      await http.patch(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/demandes_devis?id=eq.${d.id}'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'statut': 'accepte'}),
      );
    } catch (_) {}

    // 2. Créer le message automatique d'ouverture de conversation
    try {
      await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/messages_chat'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'canal_type': 'client_${d.id}',
          'expediteur_nom': 'Direction Générale JBF',
          'expediteur_avatar': 'DG',
          'section_nom': d.services.isNotEmpty ? d.services.first : 'Devis',
          'message': 'Bonjour ${d.nom}, votre demande de devis (${d.services.join(", ")}) a été acceptée par la Direction Générale JBF Services SARL. Vous pouvez échanger directement vos fichiers et devis détaillés ici.',
          'created_at': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}

    _loadAllDevis();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Devis accepté ! Ouverture de la conversation client...'),
        backgroundColor: AppConfig.successGreen,
      ),
    );

    // 3. Ouvrir directement la conversation dans ClientChatAdminScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientChatAdminScreen(
          preselectedClientId: d.id,
          preselectedClientName: d.nom,
          preselectedClientEmail: d.email,
          preselectedCompany: d.societe,
        ),
      ),
    );
  }

  Future<void> _refuserDevisClient(DevisItem d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser cette Demande de Devis'),
        content: Text('Voulez-vous marquer comme refusée la demande de ${d.nom} (${d.societe}) ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Refuser le Devis'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await http.patch(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/demandes_devis?id=eq.${d.id}'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'statut': 'refuse'}),
      );
      _loadAllDevis();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande de devis refusée.'), backgroundColor: AppConfig.dangerRed),
      );
    } catch (_) {}
  }

  Widget _buildClientsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _devisClients.length,
      itemBuilder: (context, i) {
        final d = _devisClients[i];
        final isAccepte = d.statut == 'accepte' || d.statut == 'valide';
        final isRefuse = d.statut == 'refuse';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppConfig.brandPinkTint,
                  child: const Icon(Icons.request_quote, color: AppConfig.brandPink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.societe.isNotEmpty ? d.societe : d.nom,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text('Prestations: ${d.services.join(", ")} • Ville: ${d.localite}'),
                      Text('Contact: ${d.email} • Tél: ${d.telephone}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      if (d.message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Note : ${d.message}', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      d.montantUsd > 0 ? '\$${d.montantUsd.toStringAsFixed(0)} USD' : 'En attente chiffrage',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: d.montantUsd > 0 ? AppConfig.successGreen : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatBadge(label: d.statut.toUpperCase(), status: d.statut),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (!isAccepte && !isRefuse) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.successGreen, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Accepter'),
                            onPressed: () => _accepterDevisClient(d),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: AppConfig.dangerRed, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                            icon: const Icon(Icons.close, size: 14),
                            label: const Text('Refuser'),
                            onPressed: () => _refuserDevisClient(d),
                          ),
                        ] else if (isAccepte) ...[
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                            icon: const Icon(Icons.chat, size: 14),
                            label: const Text('Ouvrir Chat & Partager Devis'),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ClientChatAdminScreen(
                                    preselectedClientId: d.id,
                                    preselectedClientName: d.nom,
                                    preselectedClientEmail: d.email,
                                    preselectedCompany: d.societe,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembresTab() {
    if (_devisMembres.isEmpty) {
      return const Center(child: Text('Aucun devis soumis par les membres de terrain pour le moment.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _devisMembres.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final d = _devisMembres[i];
        final numDevis = d['numero_devis'] ?? 'DEVIS-MBR';
        final membre = d['nom_collaborateur'] ?? 'Membre JBF';
        final client = d['nom_client'] ?? 'Client Partenaire';
        final projet = d['projet_prestation'] ?? 'Prestation';
        final totalHt = (d['total_ht'] as num?)?.toDouble() ?? 0.0;
        final statut = d['statut'] ?? 'transmis_admin';

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade50,
                child: Icon(Icons.handyman, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(numDevis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                          child: Text('Chiffré par : $membre', style: TextStyle(fontSize: 11, color: Colors.blue.shade800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Client cible : $client • Projet : $projet'),
                    Text('Coût chiffré : ${totalHt.toStringAsFixed(2)} USD (Matériaux + Main d\'œuvre)'),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showValiderDevisMembreDialog(d),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Valider & Appliquer Marge'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppConfig.dangerRed),
                        tooltip: 'Refuser / Supprimer ce devis membre',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Refuser ce devis membre ?'),
                              content: Text('Voulez-vous supprimer le devis $numDevis soumis par $membre ?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Annuler')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
                                  onPressed: () => Navigator.of(c).pop(true),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final id = d['id']?.toString() ?? '';
                            try {
                              await http.delete(
                                Uri.parse('${AppConfig.supabaseUrl}/rest/v1/devis_membres?id=eq.$id'),
                                headers: {
                                  'apikey': AppConfig.supabaseAnonKey,
                                  'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                                },
                              );
                            } catch (_) {}
                            _loadAllDevis();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
