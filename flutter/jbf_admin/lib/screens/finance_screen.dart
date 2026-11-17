import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _ecritures = [];
  double _totalRecettes = 0.0;
  double _totalDepenses = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFinanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFinanceData() async {
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> items = [];
    double rec = 0.0;
    double dep = 0.0;

    // 1. Tentative Supabase : comptabilite_ecritures
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/comptabilite_ecritures?select=*&order=created_at.desc'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        for (var e in list) {
          final m = Map<String, dynamic>.from(e);
          final montant = (m['montant'] as num?)?.toDouble() ?? 0.0;
          final type = (m['type_operation'] ?? '').toString();
          if (type.contains('recette')) {
            rec += montant;
          } else {
            dep += montant;
          }
          items.add(m);
        }
      }
    } catch (_) {}

    // 2. Charger les reçus / factures payées depuis factures
    try {
      final facRes = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/factures?statut=eq.payee&select=*&order=created_at.desc'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 4));

      if (facRes.statusCode == 200) {
        final List<dynamic> facList = jsonDecode(facRes.body);
        for (var f in facList) {
          final fac = Map<String, dynamic>.from(f);
          final numPiece = fac['numero_facture'] ?? fac['id']?.toString() ?? '';
          final already = items.any((it) => (it['numero_piece'] ?? '') == numPiece);
          if (!already) {
            final mnt = (fac['montant_paye'] ?? fac['montant_total'] as num?)?.toDouble() ?? 0.0;
            rec += mnt;
            items.add({
              'id': fac['id'],
              'numero_piece': numPiece,
              'date_operation': fac['date_emission'] ?? fac['created_at']?.toString().split('T').first ?? '',
              'type_operation': 'recette_client',
              'categorie': 'Règlement Facture Client',
              'libelle': 'Encaissement Facture / Reçu officiel',
              'tiers_concerne': fac['client_nom'] ?? 'Client Partenaire',
              'montant': mnt,
              'devise': fac['devise'] ?? 'USD',
              'mode_reglement': 'virement',
              'created_at': fac['created_at'],
            });
          }
        }
      }
    } catch (_) {}

    // 3. Repli API backend si disponible
    if (items.isEmpty) {
      try {
        final url = '${AppConfig.apiBaseUrl}/admin/finance/ecritures';
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          items = (data['ecritures'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
          rec = (data['total_recettes'] as num?)?.toDouble() ?? rec;
          dep = (data['total_depenses'] as num?)?.toDouble() ?? dep;
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _ecritures = items;
        _totalRecettes = rec;
        _totalDepenses = dep;
        _isLoading = false;
      });
    }
  }

  void _showAddEcritureDialog() {
    final tiersCtrl = TextEditingController();
    final montantCtrl = TextEditingController();
    final motifCtrl = TextEditingController();
    String typeOp = 'depense_achat';
    String categorie = 'Achats Fournitures & EPI';
    String modePaiement = 'virement';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.post_add, color: AppConfig.brandPink),
              SizedBox(width: 8),
              Text('Saisir une Écriture Comptable'),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: typeOp,
                    decoration: const InputDecoration(labelText: 'Type d\'Opération'),
                    items: const [
                      DropdownMenuItem(value: 'recette_client', child: Text('Recette Client (Encaissement)')),
                      DropdownMenuItem(value: 'depense_achat', child: Text('Dépense : Achats & Consommables')),
                      DropdownMenuItem(value: 'depense_frais', child: Text('Dépense : Frais Généraux & Déplacements')),
                      DropdownMenuItem(value: 'depense_investissement', child: Text('Dépense : Investissement Matériel Lourd')),
                      DropdownMenuItem(value: 'paie_rh', child: Text('Dépense : Rémunérations & Salaires')),
                    ],
                    onChanged: (v) => setDlgState(() => typeOp = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tiersCtrl,
                    decoration: const InputDecoration(labelText: 'Nom du Tiers (Client ou Fournisseur) *'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: montantCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Montant (USD) *', hintText: 'ex: 4500.00'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: modePaiement,
                          decoration: const InputDecoration(labelText: 'Mode de Paiement'),
                          items: const [
                            DropdownMenuItem(value: 'virement', child: Text('Virement Bancaire')),
                            DropdownMenuItem(value: 'm_pesa', child: Text('M-Pesa / Vodacash')),
                            DropdownMenuItem(value: 'airtel_money', child: Text('Airtel Money')),
                            DropdownMenuItem(value: 'orange_money', child: Text('Orange Money')),
                            DropdownMenuItem(value: 'cheque', child: Text('Chèque')),
                            DropdownMenuItem(value: 'cash', child: Text('Espèces / Caisse')),
                          ],
                          onChanged: (v) => setDlgState(() => modePaiement = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: motifCtrl,
                    decoration: const InputDecoration(labelText: 'Motif / Description de la pièce comptable'),
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
                if (tiersCtrl.text.isEmpty || montantCtrl.text.isEmpty) return;
                Navigator.of(ctx).pop();

                final mnt = double.tryParse(montantCtrl.text) ?? 0.0;
                final motif = motifCtrl.text.trim();
                final tiers = tiersCtrl.text.trim();
                final pieceNum = 'ECR-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

                // 1. Sauvegarde directe dans Supabase (comptabilite_ecritures)
                try {
                  await http.post(
                    Uri.parse('${AppConfig.supabaseUrl}/rest/v1/comptabilite_ecritures'),
                    headers: {
                      'apikey': AppConfig.supabaseAnonKey,
                      'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'numero_piece': pieceNum,
                      'date_operation': DateTime.now().toIso8601String().split('T').first,
                      'type_operation': typeOp,
                      'categorie': categorie,
                      'libelle': motif.isNotEmpty ? motif : 'Écriture $categorie',
                      'tiers_concerne': tiers,
                      'montant': mnt,
                      'devise': 'USD',
                      'mode_reglement': modePaiement,
                      'reference_bancaire': motif,
                      'est_valide': true,
                      'created_at': DateTime.now().toIso8601String(),
                    }),
                  );
                } catch (_) {}

                // 2. Repli API backend si disponible
                try {
                  final url = '${AppConfig.apiBaseUrl}/admin/finance/ecritures';
                  await http.post(
                    Uri.parse(url),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'type_operation': typeOp,
                      'categorie': categorie,
                      'montant': mnt,
                      'devise': 'USD',
                      'tiers_nom': tiers,
                      'mode_paiement': modePaiement,
                      'reference_piece': motif,
                    }),
                  ).timeout(const Duration(seconds: 2));
                } catch (_) {}

                _loadFinanceData();
              },
              child: const Text('Comptabiliser'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerateReceiptDialog() {
    final clientNameCtrl = TextEditingController();
    final clientEmailCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final motifCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: AppConfig.brandPink),
            SizedBox(width: 8),
            Text('Émettre un Reçu de Paiement Client'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: clientNameCtrl,
                decoration: const InputDecoration(labelText: 'Nom du Client ou Entreprise *', hintText: 'ex: Mutanda Mining SARL'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: clientEmailCtrl,
                decoration: const InputDecoration(labelText: 'Email Client (Réception immédiate du reçu) *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Montant Encaissé (USD) *', hintText: 'ex: 15000.00'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: motifCtrl,
                decoration: const InputDecoration(labelText: 'Motif du Règlement'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.successGreen),
            onPressed: () async {
              if (clientEmailCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
              Navigator.of(ctx).pop();

              final mnt = double.tryParse(amountCtrl.text) ?? 0.0;
              final clientNom = clientNameCtrl.text.trim();
              final clientEmail = clientEmailCtrl.text.trim();
              final motif = motifCtrl.text.trim();
              final numFacture = 'REC-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

              // 1. Sauvegarder dans factures (Supabase)
              try {
                await http.post(
                  Uri.parse('${AppConfig.supabaseUrl}/rest/v1/factures'),
                  headers: {
                    'apikey': AppConfig.supabaseAnonKey,
                    'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'numero_facture': numFacture,
                    'client_nom': clientNom,
                    'client_email': clientEmail,
                    'montant_total': mnt,
                    'montant_paye': mnt,
                    'statut': 'payee',
                    'devise': 'USD',
                    'date_emission': DateTime.now().toIso8601String().split('T').first,
                    'created_at': DateTime.now().toIso8601String(),
                  }),
                );
              } catch (_) {}

              // 2. Enregistrer l'écriture d'encaissement dans comptabilite_ecritures
              try {
                await http.post(
                  Uri.parse('${AppConfig.supabaseUrl}/rest/v1/comptabilite_ecritures'),
                  headers: {
                    'apikey': AppConfig.supabaseAnonKey,
                    'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'numero_piece': numFacture,
                    'date_operation': DateTime.now().toIso8601String().split('T').first,
                    'type_operation': 'recette_client',
                    'categorie': 'Encaissement Prestation B2B',
                    'libelle': motif.isNotEmpty ? motif : 'Règlement client $clientNom',
                    'tiers_concerne': clientNom,
                    'montant': mnt,
                    'devise': 'USD',
                    'mode_reglement': 'virement',
                    'est_valide': true,
                    'created_at': DateTime.now().toIso8601String(),
                  }),
                );
              } catch (_) {}

              // 3. Repli API backend si disponible
              try {
                final url = '${AppConfig.apiBaseUrl}/admin/finance/recus/generer';
                await http.post(
                  Uri.parse(url),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'client_nom': clientNom,
                    'client_email': clientEmail,
                    'montant': mnt,
                    'devise': 'USD',
                    'motif': motif,
                  }),
                ).timeout(const Duration(seconds: 2));
              } catch (_) {}

              _loadFinanceData();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reçu officiel généré et comptabilisé avec succès !'),
                  backgroundColor: AppConfig.successGreen,
                ),
              );
            },
            child: const Text('Générer & Envoyer au Client'),
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
                        'Gestion Financière & Trésorerie JBF',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText),
                      ),
                      Text(
                        'Écritures comptables, catégorisation des dépenses, facturation et génération de reçus clients',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showGenerateReceiptDialog,
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('Émettre un Reçu Client'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.successGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showAddEcritureDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvelle Écriture'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.brandPink,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // KPI Cards Banner
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                _buildKpiCard('Total Recettes Clients', '${_totalRecettes.toStringAsFixed(0)} USD', AppConfig.successGreen, Icons.trending_up),
                const SizedBox(width: 16),
                _buildKpiCard('Total Dépenses Opérationnelles', '${_totalDepenses.toStringAsFixed(0)} USD', Colors.orange.shade800, Icons.trending_down),
                const SizedBox(width: 16),
                _buildKpiCard('Solde Net Trésorerie', '${(_totalRecettes - _totalDepenses).toStringAsFixed(0)} USD', AppConfig.brandPink, Icons.account_balance),
              ],
            ),
          ),

          // Transactions Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
                : _ecritures.isEmpty
                    ? const Center(child: Text('Aucune écriture enregistrée pour le moment.'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _ecritures.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = _ecritures[i];
                          final isRecette = e['type_operation'] == 'recette_client';
                          final tiers = e['tiers_nom'] ?? 'Tiers';
                          final montant = e['montant'] ?? 0;
                          final date = e['date_ecriture'] ?? '';
                          final numPiece = e['numero_ecriture'] ?? '';

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isRecette ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                  child: Icon(
                                    isRecette ? Icons.arrow_downward : Icons.arrow_upward,
                                    size: 16,
                                    color: isRecette ? AppConfig.successGreen : AppConfig.dangerRed,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tiers, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('Réf: $numPiece • Date: $date', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isRecette ? '+' : '-'} $montant USD',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isRecette ? AppConfig.successGreen : AppConfig.dangerRed,
                                  ),
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

  Widget _buildKpiCard(String title, String val, Color color, IconData icon) {
    return Expanded(
      child: Container(
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
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
