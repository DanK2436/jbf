import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GalleryItemModel {
  final String id;
  String titre;
  String categorie;
  String typeMedia; // 'image' ou 'video'
  String mediaUrl;
  String description;
  bool estPublie;
  int ordre;

  GalleryItemModel({
    required this.id,
    required this.titre,
    required this.categorie,
    required this.typeMedia,
    required this.mediaUrl,
    this.description = '',
    this.estPublie = true,
    this.ordre = 0,
  });

  factory GalleryItemModel.fromJson(Map<String, dynamic> j) {
    final rawType = (j['type'] ?? j['type_media'] ?? '').toString().toLowerCase();
    final url = (j['url'] ?? j['media_url'] ?? j['img_url'] ?? j['video_url'] ?? '').toString();
    final isVideo = rawType.contains('vid') || url.endsWith('.mp4') || url.contains('youtube') || url.contains('vimeo');

    return GalleryItemModel(
      id: j['id']?.toString() ?? '',
      titre: j['titre'] ?? j['title'] ?? 'Réalisation JBF',
      categorie: j['categorie'] ?? j['category'] ?? 'Général',
      typeMedia: isVideo ? 'video' : 'image',
      mediaUrl: url.isNotEmpty ? url : 'assets/gallery_construction.jpg',
      description: j['description'] ?? '',
      estPublie: j['publie'] != null ? (j['publie'] == true) : (j['est_publie'] == null ? true : (j['est_publie'] == true)),
      ordre: int.tryParse(j['ordre']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'titre': titre,
        'categorie': categorie,
        'type_media': typeMedia,
        'media_url': mediaUrl,
        'description': description,
        'est_publie': estPublie,
        'ordre': ordre,
      };
}

class GalleryManagementScreen extends StatefulWidget {
  const GalleryManagementScreen({super.key});

  @override
  State<GalleryManagementScreen> createState() => _GalleryManagementScreenState();
}

class _GalleryManagementScreenState extends State<GalleryManagementScreen> {
  bool _isLoading = true;
  List<GalleryItemModel> _items = [];
  String _selectedCategory = 'Toutes';

  final List<String> _categories = [
    'Toutes',
    'Mines & Extraction',
    'BTP & Génie Civil',
    'Catering HACCP',
    'Maintenance & Soudure',
    'Logistique & Engins',
    'Énergie MT/HT',
  ];

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    setState(() => _isLoading = true);
    List<GalleryItemModel> fetched = [];

    // 1. Charger depuis galerie_items (Supabase)
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/galerie_items?select=*&order=created_at.desc'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        fetched = list.map((e) => GalleryItemModel.fromJson(e)).toList();
      }
    } catch (_) {}

    // 2. Si galerie_items est vide, vérifier la table synonyme gallery_images
    if (fetched.isEmpty) {
      try {
        final res2 = await http.get(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/gallery_images?select=*&order=created_at.desc'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
        ).timeout(const Duration(seconds: 4));

        if (res2.statusCode == 200) {
          final List<dynamic> list2 = jsonDecode(res2.body);
          fetched = list2.map((e) => GalleryItemModel.fromJson(e)).toList();
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _items = fetched;
        _isLoading = false;
      });
    }
  }

  void _showAddOrEditDialog([GalleryItemModel? item]) {
    final isEditing = item != null;
    final titreCtrl = TextEditingController(text: item?.titre ?? '');
    final urlCtrl = TextEditingController(text: item?.mediaUrl ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    String selectedCat = item?.categorie ?? 'Mines & Extraction';
    String selectedType = item?.typeMedia ?? 'image';
    bool isPublie = item?.estPublie ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit : Icons.add_photo_alternate, color: AppConfig.brandPink),
              const SizedBox(width: 10),
              Text(isEditing ? 'Modifier le Média' : 'Publier une Photo / Vidéo sur la Galerie'),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Titre ou Légende Officielle *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titreCtrl,
                    decoration: const InputDecoration(hintText: 'Ex: Raccordement TGBT Centrale Kolwezi'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCat,
                          decoration: const InputDecoration(labelText: 'Pôle de Service / Secteur'),
                          items: _categories.where((c) => c != 'Toutes').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setDlgState(() => selectedCat = v!),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(labelText: 'Format du Média'),
                          items: const [
                            DropdownMenuItem(value: 'image', child: Text('Photo / Image HD')),
                            DropdownMenuItem(value: 'video', child: Text('Vidéo Reportage (.mp4)')),
                          ],
                          onChanged: (v) => setDlgState(() => selectedType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('URL / Chemin du Fichier *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(
                      hintText: 'https://jbf-service.com/assets/... ou URL CDN',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Description Technique', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Contexte du chantier, localisation en RDC, effectifs mobilisés...'),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    title: const Text('Visible sur le site web public (Page Galerie)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Permet d\'activer ou de masquer le média instantanément'),
                    value: isPublie,
                    activeColor: AppConfig.brandPink,
                    onChanged: (v) => setDlgState(() => isPublie = v),
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
                    const SnackBar(content: Text('Veuillez renseigner le titre et l\'URL du média.')),
                  );
                  return;
                }

                Navigator.of(ctx).pop();
                setState(() => _isLoading = true);

                final payload = {
                  'titre': titreCtrl.text.trim(),
                  'categorie': selectedCat,
                  'type': selectedType == 'video' ? 'video' : 'photo',
                  'type_media': selectedType,
                  'url': urlCtrl.text.trim(),
                  'media_url': urlCtrl.text.trim(),
                  'img_url': urlCtrl.text.trim(),
                  'video_url': selectedType == 'video' ? urlCtrl.text.trim() : null,
                  'description': descCtrl.text.trim(),
                  'publie': isPublie,
                  'est_publie': isPublie,
                };

                try {
                  if (isEditing) {
                    await http.patch(
                      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/galerie_items?id=eq.${item.id}'),
                      headers: {
                        'apikey': AppConfig.supabaseAnonKey,
                        'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode(payload),
                    );
                    try {
                      await http.patch(
                        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/gallery_images?id=eq.${item.id}'),
                        headers: {
                          'apikey': AppConfig.supabaseAnonKey,
                          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode(payload),
                      );
                    } catch (_) {}
                  } else {
                    payload['created_at'] = DateTime.now().toIso8601String();
                    await http.post(
                      Uri.parse('${AppConfig.supabaseUrl}/rest/v1/galerie_items'),
                      headers: {
                        'apikey': AppConfig.supabaseAnonKey,
                        'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode(payload),
                    );
                    try {
                      await http.post(
                        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/gallery_images'),
                        headers: {
                          'apikey': AppConfig.supabaseAnonKey,
                          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
                          'Content-Type': 'application/json',
                        },
                        body: jsonEncode(payload),
                      );
                    } catch (_) {}
                  }
                } catch (_) {}

                _loadGallery();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing ? 'Média mis à jour avec succès.' : 'Média publié sur la galerie avec succès.'),
                    backgroundColor: AppConfig.successGreen,
                  ),
                );
              },
              child: Text(isEditing ? 'Mettre à jour' : 'Publier sur la Galerie'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(GalleryItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce média'),
        content: Text('Voulez-vous supprimer définitivement "${item.titre}" de la galerie ?'),
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

    if (confirm == true) {
      setState(() => _items.removeWhere((i) => i.id == item.id));
      try {
        await http.delete(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/galerie_items?id=eq.${item.id}'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
        );
        try {
          await http.delete(
            Uri.parse('${AppConfig.supabaseUrl}/rest/v1/gallery_images?id=eq.${item.id}'),
            headers: {
              'apikey': AppConfig.supabaseAnonKey,
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
            },
          );
        } catch (_) {}
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Média supprimé avec succès.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'Toutes'
        ? _items
        : _items.where((i) => i.categorie == _selectedCategory).toList();

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
                  const Text('Gestionnaire de la Galerie Publique (Photos & Vidéos)',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
                  Text('Diffusez vos réalisations chantiers sur gallery.html et les applications',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                    tooltip: 'Actualiser',
                    onPressed: _loadGallery,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
                    icon: const Icon(Icons.add_photo_alternate, size: 18),
                    label: const Text('Publier un Média'),
                    onPressed: () => _showAddOrEditDialog(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Barre de filtre par catégorie
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppConfig.brandPink,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Grille des Médias
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
                : filtered.isEmpty
                    ? const Center(child: Text('Aucun média publié dans cette catégorie.'))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisExtent: 290,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) {
                          final item = filtered[idx];
                          final isVideo = item.typeMedia == 'video';

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail
                                Container(
                                  height: 135,
                                  color: const Color(0xFF1E1E24),
                                  alignment: Alignment.center,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Center(
                                        child: Icon(
                                          isVideo ? Icons.videocam : Icons.image,
                                          size: 48,
                                          color: Colors.white38,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isVideo ? Colors.purple : AppConfig.brandPink,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isVideo ? 'VIDÉO HD' : 'PHOTO HD',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: item.estPublie ? AppConfig.successGreen : Colors.grey,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.estPublie ? 'PUBLIÉ' : 'MASQUÉ',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.categorie.toUpperCase(),
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.titre,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.description,
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Spacer(),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 18, color: AppConfig.blackText),
                                              tooltip: 'Modifier',
                                              onPressed: () => _showAddOrEditDialog(item),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 18, color: AppConfig.dangerRed),
                                              tooltip: 'Supprimer',
                                              onPressed: () => _deleteItem(item),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
}
