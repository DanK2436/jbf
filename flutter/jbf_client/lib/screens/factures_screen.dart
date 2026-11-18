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

  Widget _buildSummaryCard(String title, double amount, Color bgColor, Color borderColor, Color titleColor, Color amountColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: titleColor)),
              const SizedBox(height: 4),
              Text('\$${amount.toStringAsFixed(0)} USD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: amountColor)),
            ],
          ),
          Icon(Icons.account_balance_wallet_outlined, color: titleColor.withOpacity(0.4), size: 24),
        ],
      ),
    );
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Factures & Devis Validés',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Situation comptable et documents certifiés conformes ARSP / DGI',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),

                    // Financial Summary Cards (Responsive Stack on Mobile)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        if (isMobile) {
                          return Column(
                            children: [
                              _buildSummaryCard('TOTAL FACTURÉ', total, Colors.white, Colors.grey.shade300, Colors.grey.shade700, AppConfig.blackText),
                              const SizedBox(height: 10),
                              _buildSummaryCard('MONTANT ACQUITTÉ', totalPaye, const Color(0xFFDCFCE7), const Color(0xFF86EFAC), const Color(0xFF15803D), const Color(0xFF166534)),
                              const SizedBox(height: 10),
                              _buildSummaryCard('SOLDE À RÉGLER', reste, const Color(0xFFFEF3C7), const Color(0xFFFCD34D), const Color(0xFFB45309), const Color(0xFF92400E)),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: _buildSummaryCard('TOTAL FACTURÉ', total, Colors.white, Colors.grey.shade300, Colors.grey.shade700, AppConfig.blackText)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildSummaryCard('MONTANT ACQUITTÉ', totalPaye, const Color(0xFFDCFCE7), const Color(0xFF86EFAC), const Color(0xFF15803D), const Color(0xFF166534))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildSummaryCard('SOLDE À RÉGLER', reste, const Color(0xFFFEF3C7), const Color(0xFFFCD34D), const Color(0xFFB45309), const Color(0xFF92400E))),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _factures.length,
                      itemBuilder: (context, idx) {
                        final f = _factures[idx];
                        final isPaye = f.statut == 'payee';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isPaye ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isPaye ? Icons.check_circle_outline : Icons.pending_actions,
                                        color: isPaye ? AppConfig.successGreen : const Color(0xFFD97706),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            f.libelle,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppConfig.blackText),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Réf : ${f.reference}',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                          ),
                                          Text(
                                            'Date : ${f.date} • Échéance : ${f.echeance}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 18),
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Text(
                                      '\$${f.montantUsd.toStringAsFixed(0)} USD',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppConfig.blackText),
                                    ),
                                    StatBadge(
                                      label: isPaye ? 'Payée' : 'En attente de paiement',
                                      color: isPaye ? AppConfig.successGreen : const Color(0xFFD97706),
                                    ),
                                  ],
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
