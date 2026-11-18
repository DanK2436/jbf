import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../models/admin_models.dart';
import '../services/supabase_service.dart';

class MembresScreen extends StatefulWidget {
  const MembresScreen({super.key});

  @override
  State<MembresScreen> createState() => _MembresScreenState();
}

class _MembresScreenState extends State<MembresScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  List<MembreItem> _membres = [];

  @override
  void initState() {
    super.initState();
    _loadMembres();
  }

  Future<void> _loadMembres() async {
    setState(() => _isLoading = true);
    final list = await _supabase.fetchMembres();
    if (!mounted) return;
    setState(() {
      _membres = list;
      _isLoading = false;
    });
  }

  void _showAddMembreDialog() {
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+243');
    final passCtrl = TextEditingController(text: 'JBF2026!');
    final matCtrl = TextEditingController(text: 'JBF-M-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final posteCtrl = TextEditingController(text: 'Technicien / Chef d\'équipe');
    String selectedSection = 'Catering Industriel & Base-Vie';
    String selectedProvince = 'Haut-Katanga';

    final sections = [
      'Catering Industriel & Base-Vie',
      'Sous-traitance Minière & Extraction',
      'BTP, Génie Civil & Fondations',
      'Maintenance Industrielle & Soudure',
      'Sécurité Industrielle & Gardiennage',
      'Énergie MT/HT & Groupes Électrogènes',
      'Transport Personnel & Location Engins',
      'Climatisation Industrielle & Froid',
      'Télécoms & Fibre Optique',
      'Informatique & Cyber-Sécurité',
      'Audit HSE & Contrôle Qualité',
    ];

    final provinces = [
      'Haut-Katanga',
      'Lualaba',
      'Kinshasa',
      'Kongo Central',
      'Nord-Kivu',
      'Autre',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add, color: AppConfig.brandPink),
              SizedBox(width: 10),
              Text('Créer un Collaborateur Membre (Supabase)'),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nom Complet *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: nomCtrl, decoration: const InputDecoration(hintText: 'ex: Kasongo Mutombo')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Matricule JBF *', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(controller: matCtrl),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Téléphone Mobile *', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(controller: phoneCtrl),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Adresse Email de Connexion *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(hintText: 'ex: k.mutombo@jbf-service.com')),
                  const SizedBox(height: 12),
                  const Text('Mot de Passe Initial de Connexion *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                      hintText: 'ex: JBF2026!',
                      helperText: 'Ce mot de passe servira à l\'employé pour se connecter sur l\'application Membre.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Poste & Qualification *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: posteCtrl, decoration: const InputDecoration(hintText: 'ex: Technicien Chaudronnerie / Chef de Chantier')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pôle / Service *', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedSection,
                              isExpanded: true,
                              items: sections.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setDlgState(() => selectedSection = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Province Affectation', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedProvince,
                              items: provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (v) => setDlgState(() => selectedProvince = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                if (nomCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez renseigner les champs obligatoires (nom, email, mot de passe).')),
                  );
                  return;
                }
                Navigator.of(ctx).pop();

                final m = MembreItem(
                  id: '',
                  nom: nomCtrl.text.trim(),
                  email: emailCtrl.text.trim().toLowerCase(),
                  phone: phoneCtrl.text.trim(),
                  matricule: matCtrl.text.trim(),
                  poste: posteCtrl.text.isNotEmpty ? posteCtrl.text.trim() : 'Agent de Terrain',
                  sectionNom: selectedSection,
                  province: selectedProvince,
                  soldeConges: 18,
                  password: passCtrl.text.trim(),
                );

                final ok = await _supabase.createMembre(m, password: passCtrl.text.trim());
                _loadMembres();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Collaborateur créé et synchronisé (Auth + Profiles + RH) !' : 'Enregistrement terminé.'),
                      backgroundColor: ok ? AppConfig.successGreen : Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Créer le Membre'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMembreDetailsDialog(MembreItem m) {
    bool showPassword = false;
    final passToDisplay = (m.password != null && m.password!.isNotEmpty) ? m.password! : 'JBF2026!';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppConfig.brandPink,
                foregroundColor: Colors.white,
                child: Text(m.nom.substring(0, m.nom.length >= 2 ? 2 : 1).toUpperCase()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'MEMBRE COLLABORATEUR',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.blue.shade800),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ACTIF',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppConfig.successGreen),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMembreDetailItem('Matricule JBF', m.matricule, Icons.badge_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMembreDetailItem('Province Affectation', m.province, Icons.location_on_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMembreDetailItem('Pôle / Section', m.sectionNom, Icons.business_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMembreDetailItem('Poste / Fonction', m.poste, Icons.work_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMembreDetailItem('Email de Connexion', m.email, Icons.email_outlined, canCopy: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMembreDetailItem('Téléphone Mobile', m.phone, Icons.phone_android_outlined, canCopy: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // MOT DE PASSE (AVEC AFFICHAGE & COPIE)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, color: AppConfig.brandPink, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mot de Passe Membre :',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                showPassword ? passToDisplay : '••••••••••••',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, letterSpacing: 0.8),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, size: 18),
                          tooltip: showPassword ? 'Masquer' : 'Afficher',
                          onPressed: () => setDlgState(() => showPassword = !showPassword),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copier le mot de passe',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: passToDisplay));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mot de passe copié !')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMembreDetailItem('Solde Congés Payés', '${m.soldeConges} jours ouvrables', Icons.beach_access_outlined),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fermer')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Modifier cette fiche'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _showEditMembreDialog(m);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembreDetailItem(String label, String value, IconData icon, {bool canCopy = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canCopy)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label copié !')),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.copy, size: 14, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditMembreDialog(MembreItem item) {
    final nomCtrl = TextEditingController(text: item.nom);
    final emailCtrl = TextEditingController(text: item.email);
    final phoneCtrl = TextEditingController(text: item.phone);
    final matCtrl = TextEditingController(text: item.matricule);
    final posteCtrl = TextEditingController(text: item.poste);
    final passCtrl = TextEditingController(text: item.password ?? 'JBF2026!');
    final soldeCtrl = TextEditingController(text: item.soldeConges.toString());

    final sections = [
      'Catering Industriel & Base-Vie',
      'Sous-traitance Minière & Extraction',
      'BTP, Génie Civil & Fondations',
      'Maintenance Industrielle & Soudure',
      'Sécurité Industrielle & Gardiennage',
      'Énergie MT/HT & Groupes Électrogènes',
      'Transport Personnel & Location Engins',
      'Climatisation Industrielle & Froid',
      'Télécoms & Fibre Optique',
      'Informatique & Cyber-Sécurité',
      'Audit HSE & Contrôle Qualité',
      'Direction Exécutive',
    ];

    String selectedSection = item.sectionNom.isNotEmpty ? item.sectionNom : sections.first;
    if (!sections.contains(selectedSection)) {
      selectedSection = sections.first;
    }

    final provinces = [
      'Haut-Katanga',
      'Lualaba',
      'Kinshasa',
      'Kongo Central',
      'Nord-Kivu',
      'Autre',
    ];
    String selectedProvince = item.province.isNotEmpty ? item.province : provinces.first;
    if (!provinces.contains(selectedProvince)) {
      selectedProvince = provinces.first;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Éditer Collaborateur — ${item.nom}'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nom Complet *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: nomCtrl),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Matricule JBF *', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(controller: matCtrl),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Téléphone Mobile *', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(controller: phoneCtrl),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Adresse Email de Connexion *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(controller: emailCtrl),
                  const SizedBox(height: 12),
                  const Text('Mot de Passe de Connexion (Modifiable) *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.key, color: AppConfig.brandPink, size: 18),
                      helperText: 'Définissez le mot de passe pour la connexion sur l\'application Membre.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pôle / Section *', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedSection,
                              isExpanded: true,
                              items: sections.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setDlgState(() => selectedSection = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Province Affectation', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedProvince,
                              items: provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (v) => setDlgState(() => selectedProvince = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Poste & Qualification *', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(controller: posteCtrl),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Solde Congés (Jours)', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(controller: soldeCtrl, keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                    ],
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
                if (nomCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez renseigner le nom, l\'email et le mot de passe.')),
                  );
                  return;
                }
                Navigator.of(ctx).pop();

                item.email = emailCtrl.text.trim().toLowerCase();
                item.nom = nomCtrl.text.trim();
                item.phone = phoneCtrl.text.trim();
                item.matricule = matCtrl.text.trim();
                item.poste = posteCtrl.text.trim();
                item.sectionNom = selectedSection;
                item.province = selectedProvince;
                item.password = passCtrl.text.trim();
                item.soldeConges = int.tryParse(soldeCtrl.text) ?? item.soldeConges;

                await _supabase.updateMembre(item, password: passCtrl.text.trim());
                _loadMembres();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Toutes les informations et le mot de passe du membre ont été mis à jour !'),
                      backgroundColor: AppConfig.successGreen,
                    ),
                  );
                }
              },
              child: const Text('Enregistrer les Modifications'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppConfig.brandPink));
    }

    return RefreshIndicator(
      onRefresh: _loadMembres,
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
                    const Text('Annuaire des Membres & Collaborateurs (BDD)',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Données réelles de la table profiles Supabase avec email OTP modifiable',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                      tooltip: 'Actualiser',
                      onPressed: _loadMembres,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Ajouter Collaborateur'),
                      onPressed: _showAddMembreDialog,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _membres.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('Aucun collaborateur trouvé dans la table profiles.'),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.person_add),
                                label: const Text('Ajouter le premier collaborateur'),
                                onPressed: _showAddMembreDialog,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _membres.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final m = _membres[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              leading: CircleAvatar(
                                backgroundColor: AppConfig.brandPink,
                                foregroundColor: Colors.white,
                                child: Text(m.nom.substring(0, m.nom.length >= 2 ? 2 : 1).toUpperCase()),
                              ),
                              title: Row(
                                children: [
                                  Text(m.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppConfig.brandPinkTint,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(m.matricule,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConfig.brandPinkDark)),
                                  ),
                                ],
                              ),
                              subtitle: Text('${m.poste} • ${m.province}\nEmail OTP : ${m.email} • Tél : ${m.phone}'),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Solde : ${m.soldeConges}j',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.badge_outlined, color: Color(0xFF1E293B)),
                                    tooltip: 'Aperçu Identité & Fiche Complète',
                                    onPressed: () => _showMembreDetailsDialog(m),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppConfig.brandPink),
                                    tooltip: 'Modifier Informations & Mot de passe',
                                    onPressed: () => _showEditMembreDialog(m),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
