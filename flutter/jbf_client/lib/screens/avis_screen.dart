import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/client_models.dart';
import '../services/client_data_service.dart';

class AvisScreen extends StatefulWidget {
  final ClientUser client;

  const AvisScreen({super.key, required this.client});

  @override
  State<AvisScreen> createState() => _AvisScreenState();
}

class _AvisScreenState extends State<AvisScreen> {
  final _dataService = ClientDataService();
  bool _isLoading = true;
  List<ClientAvis> _avisList = [];

  @override
  void initState() {
    super.initState();
    _loadAvis();
  }

  Future<void> _loadAvis() async {
    setState(() => _isLoading = true);
    final list = await _dataService.fetchAvis();
    if (!mounted) return;
    setState(() {
      _avisList = list;
      _isLoading = false;
    });
  }

  void _openAddAvisDialog() {
    int selectedRating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Laisser une Évaluation Partenaire'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Entreprise : ${widget.client.companyName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              const Text('Votre note globale :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    icon: Icon(
                      starNum <= selectedRating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFEAB308),
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => selectedRating = starNum),
                  );
                }),
              ),
              const SizedBox(height: 12),
              const Text('Votre Témoignage / Commentaire :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Qualité des prestations, respect des délais, réactivité HSE...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                final txt = commentCtrl.text.trim();
                if (txt.isEmpty) return;

                Navigator.of(ctx).pop();
                setState(() => _isLoading = true);

                await _dataService.submitAvis(
                  auteur: widget.client.fullName,
                  entreprise: widget.client.companyName,
                  note: selectedRating,
                  commentaire: txt,
                );

                await _loadAvis();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Merci ! Votre avis a été enregistré avec succès.'),
                    backgroundColor: AppConfig.successGreen,
                  ),
                );
              },
              child: const Text('Publier mon Avis'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
          : RefreshIndicator(
              onRefresh: _loadAvis,
              color: AppConfig.brandPink,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            const Text(
                              'Évaluations & Satisfaction Partenaires',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                            ),
                            Text(
                              'Retours d\'expérience des donneurs d\'ordres miniers en RDC',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _openAddAvisDialog,
                          icon: const Icon(Icons.rate_review_outlined, size: 18),
                          label: const Text('Donner mon Avis'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Rating Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Column(
                            children: const [
                              Text(
                                '4.9',
                                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppConfig.brandPink),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Color(0xFFEAB308), size: 18),
                                  Icon(Icons.star, color: Color(0xFFEAB308), size: 18),
                                  Icon(Icons.star, color: Color(0xFFEAB308), size: 18),
                                  Icon(Icons.star, color: Color(0xFFEAB308), size: 18),
                                  Icon(Icons.star, color: Color(0xFFEAB308), size: 18),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text('Excellence 98%', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Standards Qualité Éprouvés',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '• Hygiène alimentaire et conformité HACCP validée en zone minière.\n• Chantiers BTP livrés sans accident avec arrêt de travail (Zéro LTI).\n• Réactivité 24/7 sur l\'ensemble des 26 provinces de la RDC.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _avisList.length,
                      itemBuilder: (context, idx) {
                        final a = _avisList[idx];
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
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppConfig.brandPink.withOpacity(0.1),
                                          child: Text(
                                            a.auteur.isNotEmpty ? a.auteur[0] : 'C',
                                            style: const TextStyle(color: AppConfig.brandPink, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(a.auteur, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            Text(a.entreprise, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        ...List.generate(
                                          a.note,
                                          (_) => const Icon(Icons.star, color: Color(0xFFEAB308), size: 16),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(a.date, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  a.commentaire,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.3),
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
            ),
    );
  }
}
