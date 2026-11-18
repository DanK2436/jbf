import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/file_picker_helper.dart';

class ResourceItemModel {
  final String id;
  String titre;
  String categorie;
  String typeFichier;
  String taille;
  String description;
  String fichierUrl;
  final DateTime createdAt;

  ResourceItemModel({
    required this.id,
    required this.titre,
    required this.categorie,
    required this.typeFichier,
    required this.taille,
    required this.description,
    required this.fichierUrl,
    required this.createdAt,
  });

  factory ResourceItemModel.fromJson(Map<String, dynamic> j) {
    return ResourceItemModel(
      id: j['id']?.toString() ?? '',
      titre: j['titre'] ?? 'Document Technique',
      categorie: j['categorie'] ?? 'HSE & Sécurité',
      typeFichier: j['type_fichier'] ?? 'PDF',
      taille: j['taille'] ?? '2.4 MB',
      description: j['description'] ?? '',
      fichierUrl: j['fichier_url'] ?? 'https://jbf-service.com',
      createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'titre': titre,
        'categorie': categorie,
        'type_fichier': typeFichier,
        'taille': taille,
        'description': description,
        'fichier_url': fichierUrl,
      };
}

class ResourcesAdminScreen extends StatefulWidget {
  const ResourcesAdminScreen({super.key});

  @override
  State<ResourcesAdminScreen> createState() => _ResourcesAdminScreenState();
}

class _ResourcesAdminScreenState extends State<ResourcesAdminScreen> {
  bool _isLoading = true;
  List<ResourceItemModel> _resources = [];
  String _searchQuery = '';
  String _selectedCategory = 'Toutes';

  final List<String> _categories = [
    'Toutes',
    'HSE & Sécurité',
    'Directives Minières',
    'Procédures BTP & Génie Civil',
    'Protocoles Catering HACCP',
    'Maintenance & Outillage',
    'Logistique & Transport',
    'Fiches de Poste & Formulaires',
  ];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/ressources_hse?select=*&order=created_at.desc'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _resources = list.map((e) => ResourceItemModel.fromJson(e)).toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<ResourceItemModel> get _filteredResources {
    return _resources.where((r) {
      final matchCat = _selectedCategory == 'Toutes' || r.categorie == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          r.titre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.categorie.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  void _showAddOrEditDialog([ResourceItemModel? item]) {
    final isEditing = item != null;
    final titreCtrl = TextEditingController(text: item?.titre ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    final urlCtrl = TextEditingController(text: item?.fichierUrl ?? '');
    final tailleCtrl = TextEditingController(text: item?.taille ?? '2.5 MB');
    final localPathCtrl = TextEditingController();
    String selectedCat = (item != null && _categories.contains(item.categorie))
        ? item.categorie
        : 'HSE & Sécurité';
    String selectedType = item?.typeFichier ?? 'PDF';
    String sourceMode = 'lien'; // 'lien' ou 'upload'
    bool isUploading = false;
    String? selectedFileName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit : Icons.post_add, color: AppConfig.brandPink),
              const SizedBox(width: 8),
              Text(isEditing ? 'Modifier la Ressource Membre' : 'Partager une Ressource pour les Membres'),
            ],
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Les membres retrouveront ce document ou ce lien directement dans leur application.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titreCtrl,
                    decoration: const InputDecoration(labelText: 'Titre du document / de la ressource *', hintText: 'ex: Manuel HSE Concession Tenke'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCat,
                          decoration: const InputDecoration(labelText: 'Catégorie'),
                          items: _categories.where((c) => c != 'Toutes').map((c) {
                            return DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis));
                          }).toList(),
                          onChanged: (v) => setDlgState(() => selectedCat = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(labelText: 'Type de ressource'),
                          items: const [
                            DropdownMenuItem(value: 'PDF', child: Text('PDF Document')),
                            DropdownMenuItem(value: 'Word / DOCX', child: Text('Word / DOCX')),
                            DropdownMenuItem(value: 'Excel / XLSX', child: Text('Excel / XLSX')),
                            DropdownMenuItem(value: 'Lien Web', child: Text('Lien Web / Portail')),
                            DropdownMenuItem(value: 'JBF Sécurisé', child: Text('Conteneur .JBF')),
                            DropdownMenuItem(value: 'Image / Schéma', child: Text('Image PNG/JPG')),
                            DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                          ],
                          onChanged: (v) => setDlgState(() => selectedType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Point 8 : Choix partage de connaissances (Lien Web vs Upload Fichier)
                  const Text('Mode de partage de la connaissance * :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'lien', label: Text('Partage par Lien (URL)'), icon: Icon(Icons.link, size: 16)),
                      ButtonSegment(value: 'upload', label: Text('Partage par Upload Fichier'), icon: Icon(Icons.upload_file, size: 16)),
                    ],
                    selected: {sourceMode},
                    onSelectionChanged: (v) => setDlgState(() => sourceMode = v.first),
                  ),
                  const SizedBox(height: 14),

                  if (sourceMode == 'lien') ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: urlCtrl,
                            decoration: const InputDecoration(
                              labelText: 'URL de la ressource ou lien partagé *',
                              hintText: 'https://jbf-service.com/docs/... ou intranet',
                              prefixIcon: Icon(Icons.link),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: tailleCtrl,
                            decoration: const InputDecoration(labelText: 'Taille estimée', hintText: 'ex: 3.2 MB'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppConfig.brandPink.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
                                onPressed: isUploading
                                    ? null
                                    : () async {
                                        setDlgState(() => isUploading = true);
                                        final picked = await FilePickerHelper.pickFile(
                                          title: 'Choisir une ressource à partager',
                                          filter: 'Documents techniques (*.pdf;*.docx;*.xlsx;*.png;*.jpg)|*.pdf;*.docx;*.xlsx;*.png;*.jpg|Tous les fichiers (*.*)|*.*',
                                        );
                                        if (picked != null) {
                                          selectedFileName = picked.name;
                                          localPathCtrl.text = picked.path;
                                          tailleCtrl.text = picked.sizeFormatted;
                                          if (titreCtrl.text.isEmpty) {
                                            titreCtrl.text = picked.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
                                          }
                                          final mime = FilePickerHelper.getMimeType(picked.name);
                                          if (mime.contains('pdf')) {
                                            selectedType = 'PDF';
                                          } else if (mime.contains('word')) {
                                            selectedType = 'Word / DOCX';
                                          } else if (mime.contains('excel')) {
                                            selectedType = 'Excel / XLSX';
                                          } else if (mime.startsWith('image/')) {
                                            selectedType = 'Image / Schéma';
                                          }

                                          final uploaded = await FilePickerHelper.uploadToSupabase(
                                            file: picked,
                                            bucket: 'documents',
                                          );
                                          if (uploaded != null) {
                                            urlCtrl.text = uploaded;
                                          } else {
                                            urlCtrl.text = picked.path;
                                          }
                                        }
                                        setDlgState(() => isUploading = false);
                                      },
                                icon: isUploading
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.folder_open, size: 16),
                                label: Text(isUploading ? 'Téléversement...' : 'Parcourir mon PC / Téléphone...'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedFileName ?? 'Aucun fichier sélectionné',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selectedFileName != null ? FontWeight.bold : FontWeight.normal,
                                    color: selectedFileName != null ? AppConfig.blackText : Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (urlCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: AppConfig.successGreen),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Fichier prêt : ${urlCtrl.text}',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description / Instructions pour les membres', hintText: 'Précisez l\'usage, les consignes ou le cadre d\'application...'),
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
                if (titreCtrl.text.isEmpty || urlCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez renseigner le titre et le lien ou fichier de la ressource.')),
                  );
                  return;
                }

                Navigator.of(ctx).pop();
                setState(() => _isLoading = true);

                try {
                  if (isEditing) {
                    await http.patch(
                      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/ressources_hse?id=eq.${item.id}'),
                      headers: {
                        'apikey': AppConfig.supabaseAnonKey,
                        'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({
                        'titre': titreCtrl.text.trim(),
                        'categorie': selectedCat,
                        'type_fichier': selectedType,
                        'taille': tailleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'fichier_url': urlCtrl.text.trim(),
                      }),
                    );
                  } else {
                    await http.post(
                      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/ressources_hse'),
                      headers: {
                        'apikey': AppConfig.supabaseAnonKey,
                        'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode({
                        'titre': titreCtrl.text.trim(),
                        'categorie': selectedCat,
                        'type_fichier': selectedType,
                        'taille': tailleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'fichier_url': urlCtrl.text.trim(),
                        'created_at': DateTime.now().toIso8601String(),
                      }),
                    );
                  }
                  await _loadResources();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? 'Ressource mise à jour.' : 'Ressource ajoutée et mise à disposition des membres.'),
                        backgroundColor: AppConfig.successGreen,
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => _isLoading = false);
                }
              },
              child: Text(isEditing ? 'Enregistrer' : 'Publier la Ressource'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteResource(ResourceItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer définitivement'),
        content: Text('Voulez-vous supprimer définitivement "${item.titre}" de la base de données ? Les membres n\'y auront plus accès.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _resources.removeWhere((r) => r.id == item.id));
      try {
        final res = await http.delete(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/ressources_hse?id=eq.${item.id}'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
        );

        if (res.statusCode >= 200 && res.statusCode < 300) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ressource définitivement supprimée de la BDD.'), backgroundColor: AppConfig.successGreen),
          );
        } else {
          await _loadResources();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur suppression BDD (${res.statusCode})'), backgroundColor: AppConfig.dangerRed),
          );
        }
      } catch (e) {
        await _loadResources();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau: $e'), backgroundColor: AppConfig.dangerRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = _filteredResources;

    return Padding(
      padding: const EdgeInsets.all(22.0),
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
                    'Bibliothèque Documentaire & Ressources Membres (BDD)',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConfig.blackText),
                  ),
                  Text(
                    'Alimentez en direct les protocoles, fiches techniques et directives accessibles aux collaborateurs sur le terrain.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                    tooltip: 'Actualiser',
                    onPressed: _loadResources,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddOrEditDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter une Ressource'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Barre de recherche et filtre de catégorie
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Rechercher un protocole, document, procédure...',
                    fillColor: Colors.white,
                    filled: true,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Liste des ressources
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
                : docs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Aucune ressource dans cette vue.', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _showAddOrEditDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Publier un premier document pour les membres'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
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
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                doc.titre,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                              child: Text(
                                                doc.typeFichier,
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${doc.categorie} • ${doc.taille} • Ajouté le ${doc.createdAt.day.toString().padLeft(2, '0')}/${doc.createdAt.month.toString().padLeft(2, '0')}/${doc.createdAt.year}',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                        ),
                                        if (doc.description.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            doc.description,
                                            style: TextStyle(color: Colors.grey.shade800, fontSize: 12.5),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          'Lien : ${doc.fichierUrl}',
                                          style: TextStyle(color: Colors.blue.shade700, fontSize: 11.5),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    tooltip: 'Modifier',
                                    onPressed: () => _showAddOrEditDialog(doc),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppConfig.dangerRed),
                                    tooltip: 'Supprimer',
                                    onPressed: () => _deleteResource(doc),
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
    );
  }
}
