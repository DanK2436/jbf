import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/client_models.dart';
import '../services/client_data_service.dart';
import '../widgets/stat_badge.dart';

class FacturesScreen extends StatefulWidget {
  final ClientUser client;

  const FacturesScreen({super.key, required this.client});

  @override
  State<FacturesScreen> createState() => _FacturesScreenState();
}

class _FacturesScreenState extends State<FacturesScreen> {
  final _dataService = ClientDataService();
  bool _isLoading = true;
  List<ClientFacture> _factures = [];

  @override
  void initState() {
    super.initState();
    _loadFactures();
  }

  Future<void> _loadFactures() async {
    setState(() => _isLoading = true);
    final list = await _dataService.fetchFactures();
    if (!mounted) return;
    setState(() {
      _factures = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double total = _factures.fold(0.0, (s, f) => s + f.montantUsd);
    final double totalPaye = _factures.where((f) => f.statut == 'payee').fold(0.0, (s, f) => s + f.montantUsd);
    final double reste = total - totalPaye;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
          : RefreshIndicator(
              onRefresh: _loadFactures,
              color: AppConfig.brandPink,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Factures & Devis Validés',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                    ),
                    Text(
                      'Situation comptable et documents certifiés conformes ARSP / DGI',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),

                    // Financial Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TOTAL FACTURÉ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 6),
                                Text('\$${total.toStringAsFixed(0)} USD', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('MONTANT ACQUITTÉ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                                const SizedBox(height: 6),
                                Text('\$${totalPaye.toStringAsFixed(0)} USD', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFCD34D)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('SOLDE À RÉGLER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                const SizedBox(height: 6),
                                Text('\$${reste.toStringAsFixed(0)} USD', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _factures.length,
                      itemBuilder: (context, idx) {
                        final f = _factures[idx];
                        final isPaye = f.statut == 'payee';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isPaye ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isPaye ? Icons.check_circle_outline : Icons.pending_actions,
                                color: isPaye ? AppConfig.successGreen : const Color(0xFFD97706),
                              ),
                            ),
                            title: Text(
                              f.libelle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text('Réf : ${f.reference} • Date : ${f.date} • Échéance : ${f.echeance}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${f.montantUsd.toStringAsFixed(0)} USD',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppConfig.blackText),
                                ),
                                const SizedBox(height: 4),
                                StatBadge(
                                  label: isPaye ? 'Payée' : 'En attente',
                                  color: isPaye ? AppConfig.successGreen : const Color(0xFFD97706),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Banking & Wire Coordinates Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Coordonnées de Règlements Bancaires JBF Services RDC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 6),
                          Text('• Rawbank RDC (USD & CDF) : Compte Société JBF Services SARL', style: TextStyle(fontSize: 12)),
                          Text('• EquityBCDC RDC : Compte Opérations Industrielles', style: TextStyle(fontSize: 12)),
                          Text('• Mentionnez impérativement votre référence devis/facture lors du virement.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
