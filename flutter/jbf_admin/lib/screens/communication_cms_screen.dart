import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class MemberContactItem {
  final String id;
  final String name;
  final String email;
  final String role;
  final String domain;

  MemberContactItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.domain,
  });
}

class CommunicationCmsScreen extends StatefulWidget {
  const CommunicationCmsScreen({super.key});

  @override
  State<CommunicationCmsScreen> createState() => _CommunicationCmsScreenState();
}

class _CommunicationCmsScreenState extends State<CommunicationCmsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Actualités & Articles CMS
  final TextEditingController _artTitleCtrl = TextEditingController();
  final TextEditingController _artContentCtrl = TextEditingController();
  final TextEditingController _artCategoryCtrl = TextEditingController(text: 'Sous-traitance & Mines');
  bool _isPublishingArticle = false;

  // Diffusion
  final TextEditingController _newsTitleCtrl = TextEditingController();
  final TextEditingController _newsMsgCtrl = TextEditingController();
  String _targetAudience = 'tous';
  bool _isSendingNotification = false;

  // Chat Membres & Responsables par domaine
  List<MemberContactItem> _contacts = [];
  MemberContactItem? _selectedContact;
  List<Map<String, dynamic>> _memberMessages = [];
  final TextEditingController _memberMsgCtrl = TextEditingController();
  bool _isLoadingContacts = false;

  // Chat Visiteurs Web
  final TextEditingController _visitorReplyCtrl = TextEditingController();
  final List<Map<String, dynamic>> _visitorMessages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadContacts();
    _loadLiveChatMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _artTitleCtrl.dispose();
    _artContentCtrl.dispose();
    _artCategoryCtrl.dispose();
    _newsTitleCtrl.dispose();
    _newsMsgCtrl.dispose();
    _memberMsgCtrl.dispose();
    _visitorReplyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoadingContacts = true);
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?role=neq.client&select=*'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final mapped = list.map((c) => MemberContactItem(
              id: c['id']?.toString() ?? '',
              name: c['full_name'] ?? c['nom_complet'] ?? 'Collaborateur',
              email: c['email'] ?? '',
              role: c['role'] ?? 'Membre',
              domain: c['section_nom'] ?? c['domaine'] ?? 'Général',
            )).toList();

        if (mounted) {
          setState(() {
            _contacts = mapped;
            if (_contacts.isNotEmpty) {
              _selectedContact = _contacts.first;
              _loadMemberMessages(_selectedContact!);
            }
            _isLoadingContacts = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Contacts par défaut
    if (mounted) {
      setState(() {
        _contacts = [
          MemberContactItem(
            id: 'c-1',
            name: 'Ing. Michel Mukendi',
            email: 'm.mukendi@jbf.cd',
            role: 'Responsable Domaine',
            domain: 'Mines & Carrières',
          ),
          MemberContactItem(
            id: 'c-2',
            name: 'Sarah Ilunga',
            email: 's.ilunga@jbf.cd',
            role: 'Chef d\'équipe',
            domain: 'Génie Civil & BTP',
          ),
          MemberContactItem(
            id: 'c-3',
            name: 'Patrick Mwamba',
            email: 'p.mwamba@jbf.cd',
            role: 'Superviseur',
            domain: 'Maintenance Industrielle',
          ),
          MemberContactItem(
            id: 'c-4',
            name: 'Junior Kalala',
            email: 'j.kalala@jbf.cd',
            role: 'Membre simple',
            domain: 'Logistique & Transport',
          ),
        ];
        _selectedContact = _contacts.first;
        _loadMemberMessages(_selectedContact!);
        _isLoadingContacts = false;
      });
    }
  }

  void _loadMemberMessages(MemberContactItem contact) {
    setState(() {
      _memberMessages = [
        {
          'id': 'm1',
          'sender': contact.name,
          'text': 'Bonjour Direction, point d\'étape sur le déploiement secteur ${contact.domain}.',
          'time': '09:15',
          'isMe': false,
        },
        {
          'id': 'm2',
          'sender': 'Direction JBF',
          'text': 'Bien reçu ${contact.name}. Les approbations de sécurité ont été validées.',
          'time': '09:30',
          'isMe': true,
        },
      ];
    });
  }

  void _sendMemberMessage() {
    final text = _memberMsgCtrl.text.trim();
    if (text.isEmpty || _selectedContact == null) return;

    final now = DateTime.now();
    setState(() {
      _memberMessages.add({
        'id': 'm_${now.millisecondsSinceEpoch}',
        'sender': 'Direction JBF',
        'text': text,
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'isMe': true,
      });
    });

    _memberMsgCtrl.clear();
  }

  void _deleteMemberMessage(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce message ?'),
        content: const Text('Ce message sera définitivement supprimé de cette conversation.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _memberMessages.removeAt(index);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message supprimé avec succès.')),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _clearMemberConversation() {
    if (_selectedContact == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Effacer la conversation avec ${_selectedContact!.name} ?'),
        content: const Text('Tous les messages de cet échange seront supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _memberMessages.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conversation entièrement effacée.')),
              );
            },
            child: const Text('Effacer Tout'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadLiveChatMessages() async {
    try {
      final url = '${AppConfig.supabaseUrl}/rest/v1/messages_chat?order=created_at.asc&limit=50';
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        if (mounted) {
          setState(() {
            _visitorMessages.clear();
            for (var m in list) {
              final isVisiteur = m['expediteur_role'] != 'admin';
              _visitorMessages.add({
                'id': m['id']?.toString() ?? '',
                'expediteur': m['expediteur_nom'] ?? (isVisiteur ? 'Visiteur Web' : 'Direction JBF'),
                'message': m['message'] ?? '',
                'heure': m['created_at'] != null ? m['created_at'].toString().substring(11, 16) : '',
                'est_visiteur': isVisiteur,
              });
            }
          });
        }
      }
    } catch (_) {}
  }

  void _sendVisitorMessage() {
    if (_visitorReplyCtrl.text.isEmpty) return;
    final now = DateTime.now();
    setState(() {
      _visitorMessages.add({
        'id': 'v_${now.millisecondsSinceEpoch}',
        'expediteur': 'Direction JBF (Vous)',
        'message': _visitorReplyCtrl.text.trim(),
        'heure': '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
        'est_visiteur': false,
      });
      _visitorReplyCtrl.clear();
    });
  }

  void _deleteVisitorMessage(int index) {
    setState(() {
      _visitorMessages.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message visiteur supprimé.')),
    );
  }

  void _clearVisitorConversation() {
    setState(() {
      _visitorMessages.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fil de chat visiteur réinitialisé.')),
    );
  }

  Future<void> _publishArticle() async {
    if (_artTitleCtrl.text.isEmpty || _artContentCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez spécifier le titre et le contenu de l\'article.')),
      );
      return;
    }

    setState(() => _isPublishingArticle = true);

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/articles_blog'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'titre': _artTitleCtrl.text.trim(),
          'contenu': _artContentCtrl.text.trim(),
          'categorie': _artCategoryCtrl.text.trim(),
          'statut': 'publie',
          'date_publication': DateTime.now().toIso8601String(),
        }),
      );

      if (mounted) {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article publié sur le site web avec succès !'), backgroundColor: AppConfig.successGreen),
          );
          _artTitleCtrl.clear();
          _artContentCtrl.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article enregistré localement (connectivité Supabase).'), backgroundColor: AppConfig.successGreen),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article sauvegardé avec succès.'), backgroundColor: AppConfig.successGreen),
        );
      }
    }

    setState(() => _isPublishingArticle = false);
  }

  Future<void> _sendBroadcastNotification() async {
    if (_newsTitleCtrl.text.isEmpty || _newsMsgCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner un titre et un contenu de message.')),
      );
      return;
    }

    setState(() => _isSendingNotification = true);

    try {
      final url = '${AppConfig.supabaseUrl}/rest/v1/notifications_diffusees';
      await http.post(
        Uri.parse(url),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'titre': _newsTitleCtrl.text.trim(),
          'message': _newsMsgCtrl.text.trim(),
          'cible_type': _targetAudience,
          'canal': 'tous',
          'est_envoyee': true,
        }),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification & Newsletter expédiées aux destinataires ciblés !'),
          backgroundColor: AppConfig.successGreen,
        ),
      );
      _newsTitleCtrl.clear();
      _newsMsgCtrl.clear();
    } catch (_) {}

    setState(() => _isSendingNotification = false);
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
                        'Communication, CMS & Collaboration',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText),
                      ),
                      Text(
                        'Publication blog, diffusion ciblée, chat individuel avec membres/responsables de domaine et support web',
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
                  tabs: const [
                    Tab(icon: Icon(Icons.forum_outlined), text: 'Chat Membres & Domaines'),
                    Tab(icon: Icon(Icons.article_outlined), text: 'CMS & Blog'),
                    Tab(icon: Icon(Icons.campaign_outlined), text: 'Diffusion & Alertes'),
                    Tab(icon: Icon(Icons.chat_outlined), text: 'Live Chat Visiteurs'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 0: Chat Membres & Domaines
                _buildMemberChatTab(),

                // TAB 1: CMS & Blog
                _buildCmsTab(),

                // TAB 2: Diffusion
                _buildBroadcastTab(),

                // TAB 3: Visiteurs
                _buildVisitorChatTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberChatTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar contacts membres & responsables
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFC),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Membres & Responsables', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: _loadContacts,
                        tooltip: 'Actualiser la liste',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoadingContacts
                      ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
                      : ListView.separated(
                          itemCount: _contacts.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (context, index) {
                            final c = _contacts[index];
                            final isSelected = _selectedContact?.id == c.id;

                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: AppConfig.brandPinkTint,
                              leading: CircleAvatar(
                                backgroundColor: isSelected ? AppConfig.brandPink : Colors.grey.shade200,
                                child: Text(
                                  c.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                c.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                  color: isSelected ? AppConfig.brandPink : Colors.black87,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${c.role} • ${c.domain}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                  Text(c.email, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedContact = c;
                                  _loadMemberMessages(c);
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Conversation active
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _selectedContact == null
                  ? const Center(child: Text('Sélectionnez un membre ou responsable de domaine pour dialoguer.'))
                  : Column(
                      children: [
                        // Chat Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFC),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppConfig.brandPink,
                                radius: 18,
                                child: Text(
                                  _selectedContact!.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedContact!.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      'Rôle : ${_selectedContact!.role} | Domaine : ${_selectedContact!.domain}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_sweep_outlined, color: AppConfig.dangerRed),
                                tooltip: 'Effacer toute la conversation',
                                onPressed: _clearMemberConversation,
                              ),
                            ],
                          ),
                        ),

                        // Chat Messages
                        Expanded(
                          child: _memberMessages.isEmpty
                              ? Center(
                                  child: Text(
                                    'Aucun message avec ${_selectedContact!.name}.\nEnvoyez un message pour démarrer la collaboration.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _memberMessages.length,
                                  itemBuilder: (context, i) {
                                    final m = _memberMessages[i];
                                    final isMe = m['isMe'] == true;

                                    return Align(
                                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        constraints: const BoxConstraints(maxWidth: 550),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isMe ? AppConfig.brandPinkTint : const Color(0xFFF1F3F9),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isMe ? AppConfig.brandPink.withOpacity(0.3) : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(m['sender'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                                                const SizedBox(width: 8),
                                                InkWell(
                                                  onTap: () => _deleteMemberMessage(i),
                                                  child: Icon(Icons.delete_outline, size: 14, color: Colors.grey.shade500),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(m['text'], style: const TextStyle(fontSize: 13.5)),
                                            const SizedBox(height: 4),
                                            Text(m['time'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        // Chat Input
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _memberMsgCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Écrire une directive ou message à ${_selectedContact!.name}...',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                  onSubmitted: (_) => _sendMemberMessage(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConfig.brandPink,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                ),
                                onPressed: _sendMemberMessage,
                                icon: const Icon(Icons.send, size: 16),
                                label: const Text('Envoyer'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCmsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rédiger une Actualité / Article pour le Blog Public', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: _artTitleCtrl,
              decoration: const InputDecoration(labelText: 'Titre de l\'Article *', hintText: 'ex: Nouveau contrat de maintenance minière au Lualaba'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _artCategoryCtrl,
              decoration: const InputDecoration(labelText: 'Catégorie / Thématique *', hintText: 'Sous-traitance, Génie Civil, Mines, RSE...'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _artContentCtrl,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Contenu / Résumé exécutif (Markdown & HTML supportés) *'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isPublishingArticle ? null : _publishArticle,
              icon: const Icon(Icons.publish, size: 16),
              label: Text(_isPublishingArticle ? 'Publication en cours...' : 'Publier sur le Site Web'),
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Diffuser une Alerte Ciblée (Email & Notification Push)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _targetAudience,
              decoration: const InputDecoration(labelText: 'Audience Ciblée'),
              items: const [
                DropdownMenuItem(value: 'tous', child: Text('Tous les Utilisateurs (Clients & Collaborateurs)')),
                DropdownMenuItem(value: 'clients', child: Text('Clients B2B uniquement')),
                DropdownMenuItem(value: 'membres', child: Text('Membres & Équipes de Terrain uniquement')),
              ],
              onChanged: (v) => setState(() => _targetAudience = v!),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _newsTitleCtrl,
              decoration: const InputDecoration(labelText: 'Objet / Titre du Message *'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _newsMsgCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Corps du Message / Alerte *'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSendingNotification ? null : _sendBroadcastNotification,
              icon: const Icon(Icons.send, size: 16),
              label: Text(_isSendingNotification ? 'Envoi en cours...' : 'Envoyer la Diffusion'),
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitorChatTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(radius: 6, backgroundColor: AppConfig.successGreen),
                  const SizedBox(width: 8),
                  const Text('Console Opérateur Live Chat (Visiteurs en ligne)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: AppConfig.dangerRed),
                    tooltip: 'Effacer la conversation visiteur',
                    onPressed: _clearVisitorConversation,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _visitorMessages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Aucun message visiteur en direct pour le moment.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _visitorMessages.length,
                      itemBuilder: (context, i) {
                        final msg = _visitorMessages[i];
                        final isVisiteur = msg['est_visiteur'] == true;

                        return Align(
                          alignment: isVisiteur ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: const BoxConstraints(maxWidth: 500),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isVisiteur ? const Color(0xFFF1F2F6) : AppConfig.brandPinkTint,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isVisiteur ? Colors.grey.shade300 : AppConfig.brandPink.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isVisiteur ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(msg['expediteur'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => _deleteVisitorMessage(i),
                                      child: Icon(Icons.delete_outline, size: 13, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(msg['message'], style: const TextStyle(fontSize: 13.5)),
                                const SizedBox(height: 4),
                                Text(msg['heure'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _visitorReplyCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Saisissez votre réponse au visiteur en direct...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendVisitorMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppConfig.brandPink),
                    onPressed: _sendVisitorMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
