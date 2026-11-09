import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/membre_models.dart';
import '../services/supabase_service.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<ResourceDoc> _docs = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    setState(() => _isLoading = true);
    final list = await _supabase.fetchResources();
    if (!mounted) return;
    setState(() {
      _docs = list;
      _isLoading = false;
    });
  }

  List<ResourceDoc> get _filteredDocs {
    if (_searchQuery.isEmpty) return _docs;
    return _docs.where((d) =>
        d.titre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        d.categorie.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        d.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    final docs = _filteredDocs;

    return RefreshIndicator(
      onRefresh: _loadDocs,
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
                    const Text('Bibliothèque Documentaire & Protocoles HSE (BDD)',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Directives extraites en direct de la table ressources_hse Supabase',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                  tooltip: 'Actualiser',
                  onPressed: _loadDocs,
                ),
              ],
            ),
            const SizedBox(height: 18),

            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher une procédure ou un protocole minière...',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 18),

            Expanded(
              child: docs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('Aucun document dans la table ressources_hse pour le moment.',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualiser'),
                            onPressed: _loadDocs,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppConfig.brandPinkTint,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.picture_as_pdf, color: AppConfig.brandPink, size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(doc.titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Text('${doc.categorie} • Format : ${doc.typeFichier} (${doc.taille})',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(doc.description, style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text('Consulter'),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Ouverture du document : ${doc.titre}')),
                                    );
                                  },
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
