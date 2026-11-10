import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/client_models.dart';
import '../services/client_data_service.dart';
import '../widgets/stat_badge.dart';

class DevisScreen extends StatefulWidget {
  final ClientUser client;

  const DevisScreen({super.key, required this.client});

  @override
  State<DevisScreen> createState() => _DevisScreenState();
}

class _DevisScreenState extends State<DevisScreen> {
  final _dataService = ClientDataService();
  bool _isLoading = true;
  List<ClientDevis> _allDevis = [];
  String _filter = 'all';

  final List<String> _servicesJBF = [
    '1. Catering Minier & Gestion Base-Vie (Norme HACCP)',
    '2. Maintenance Industrielle & Électromécanique',
    '3. Chaudronnerie Lourde & Tuyauterie Haute Pression',
    '4. Gardiennage & Sécurité Privée Minière',
    '5. BTP, Génie Civil & Terrassement Lourd',
    '6. Transport du Personnel & Navettes Minières',
    '7. Location d\'Engins Lourds (Bennes 8x4, Grues, Bulldozers)',
    '8. Climatisation Industrielle HVAC & Chambres Froides',
    '9. Fourniture Industrielle & Consommables Miniers',
    '10. Nettoyage Industriel & Décontamination de Sites',
    '11. Réseaux Informatiques, Fibre Optique & VSAT Satellite',
    '12. Aménagement de Pistes Minières & Asphaltage',
    '13. Audit HSE, Sécurité au Travail & Norme ISO 45001',
    '14. Topographie & Cartographie par Drone Spécialisé',
    '15. Pompage d\'Exhaure & Traitement des Eaux d\'Infiltration',
  ];

  @override
  void initState() {
    super.initState();
    _loadDevis();
  }

  Future<void> _loadDevis() async {
    setState(() => _isLoading = true);
    final list = await _dataService.fetchDevis(clientEmail: widget.client.email);
    if (!mounted) return;
    setState(() {
      _allDevis = list;
      _isLoading = false;
    });
  }

  void _openCreateDevisDialog() {
    String selectedService = _servicesJBF.first;
    final siteCtrl = TextEditingController(text: widget.client.site);
    final descCtrl = TextEditingController();
    final montantCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.post_add, color: AppConfig.brandPink),
              SizedBox(width: 10),
              Text('Demander un Nouveau Devis JBF'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pôle Métier / Prestation Demandée :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedService,
                    isExpanded: true,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: _servicesJBF
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedService = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Site Minier / Localité d\'Intervention :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: siteCtrl,
                    decoration: const InputDecoration(hintText: 'ex: Usine hydrométallurgique Kolwezi, Site Kamoa-Kakula...'),
                  ),
                  const SizedBox(height: 14),
                  const Text('Détails du Cahier des Charges & Volumes :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Spécifiez effectifs, contraintes techniques, dates requises...'),
                  ),
                  const SizedBox(height: 14),
                  const Text('Budget Estimatif Envisagé (Optionnel USD) :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: montantCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(prefixText: '\$ ', suffixText: 'USD', hintText: 'ex: 45000'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final site = siteCtrl.text.trim();
                final desc = descCtrl.text.trim();
                final mnt = double.tryParse(montantCtrl.text.trim()) ?? 0.0;
                if (site.isEmpty || desc.isEmpty) return;

                Navigator.of(ctx).pop();
                setState(() => _isLoading = true);

                await _dataService.createDevis(
                  service: selectedService,
                  site: site,
                  description: desc,
                  client: widget.client,
                  montantEstime: mnt,
                );

                await _loadDevis();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Demande de devis pour "$selectedService" transmise à la Direction Commerciale JBF.'),
                    backgroundColor: AppConfig.successGreen,
                  ),
                );
              },
              child: const Text('Transmettre ma Demande'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _allDevis.where((d) {
      if (_filter == 'valide') return d.statut == 'valide';
      if (_filter == 'en_cours') return d.statut == 'en_cours' || d.statut == 'en_etude';
      return true;
    }).toList();

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Action Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gestion des Devis & Commandes',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                          ),
                          Text(
                            '${filteredList.length} demande(s) enregistrée(s) pour ${widget.client.companyName}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _openCreateDevisDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Initier un Devis'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Chips
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text('Tous (${_allDevis.length})'),
                        selected: _filter == 'all',
                        onSelected: (_) => setState(() => _filter = 'all'),
                        selectedColor: AppConfig.brandPink,
                        labelStyle: TextStyle(color: _filter == 'all' ? Colors.white : AppConfig.blackText),
                      ),
                      ChoiceChip(
                        label: Text('Validés (${_allDevis.where((d) => d.statut == 'valide').length})'),
                        selected: _filter == 'valide',
                        onSelected: (_) => setState(() => _filter = 'valide'),
                        selectedColor: AppConfig.successGreen,
                        labelStyle: TextStyle(color: _filter == 'valide' ? Colors.white : AppConfig.blackText),
                      ),
                      ChoiceChip(
                        label: Text('En Étude (${_allDevis.where((d) => d.statut != 'valide').length})'),
                        selected: _filter == 'en_cours',
                        onSelected: (_) => setState(() => _filter = 'en_cours'),
                        selectedColor: const Color(0xFF0284C7),
                        labelStyle: TextStyle(color: _filter == 'en_cours' ? Colors.white : AppConfig.blackText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quotes List
                  if (filteredList.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.folder_open, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('Aucune demande de devis dans cette catégorie.', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _openCreateDevisDialog,
                                child: const Text('Créer ma première demande'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredList.length,
                      itemBuilder: (context, idx) {
                        final d = filteredList[idx];
                        final isValide = d.statut == 'valide';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: Text(
                                            d.reference,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(d.date, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                    StatBadge(
                                      label: isValide ? 'Devis Validé' : (d.statut == 'en_cours' ? 'En étude' : 'Nouveau'),
                                      color: isValide ? AppConfig.successGreen : AppConfig.brandPink,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  d.service,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(d.site, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  d.description,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (d.montantEstime > 0)
                                      Text(
                                        'Chiffrage Estimatif : \$${d.montantEstime.toStringAsFixed(0)} USD',
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppConfig.brandPink, fontSize: 14),
                                      )
                                    else
                                      const Text(
                                        'Chiffrage en cours par les ingénieurs JBF',
                                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                                      ),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Dossier ${d.reference} suivi par le pôle commercial JBF Services.')),
                                        );
                                      },
                                      icon: const Icon(Icons.info_outline, size: 16),
                                      label: const Text('Détails'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
