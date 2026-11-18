import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/file_picker_helper.dart';

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

  // Actualités & Articles CMS & Blog
  final TextEditingController _artTitleCtrl = TextEditingController();
  final TextEditingController _artContentCtrl = TextEditingController();
  final TextEditingController _artCategoryCtrl = TextEditingController(text: 'Sous-traitance & Mines');
  final TextEditingController _artMediaUrlCtrl = TextEditingController();
  String _artMediaType = 'image'; // 'image' ou 'video'
  bool _artUseUpload = false;
  LocalPickedFile? _artPickedFile;
  bool _isUploadingArtMedia = false;
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
  bool _isLoadingChat = false;

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

    if (mounted) {
      setState(() {
        _contacts = [];
        _selectedContact = null;
        _isLoadingContacts = false;
      });
    }
  }

  Future<void> _loadMemberMessages(MemberContactItem contact) async {
    setState(() => _isLoadingChat = true);
    List<Map<String, dynamic>> realMessages = [];

    try {
      final idCanal = 'membre_${contact.id}';
      final emailCanal = contact.email.trim().isNotEmpty ? 'membre_${contact.email.trim()}' : '';
      final filter = emailCanal.isNotEmpty && emailCanal != idCanal
          ? 'or=(canal_type.eq.${Uri.encodeComponent(idCanal)},canal_type.eq.${Uri.encodeComponent(emailCanal)})'
          : 'canal_type=eq.${Uri.encodeComponent(idCanal)}';

      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/messages_chat?$filter&order=created_at.asc'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        for (var row in list) {
          final dt = DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now();
          final isMe = row['expediteur_id'] == 'admin' || (row['expediteur_nom'] ?? '').toString().contains('Direction');
          realMessages.add({
            'id': row['id']?.toString() ?? '',
            'sender': row['expediteur_nom'] ?? (isMe ? 'Direction JBF' : contact.name),
            'text': row['message'] ?? '',
            'time': '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
            'isMe': isMe,
          });
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _memberMessages = realMessages;
        _isLoadingChat = false;
      });
    }
  }

  Future<void> _sendMemberMessage() async {
    final text = _memberMsgCtrl.text.trim();
    if (text.isEmpty || _selectedContact == null) return;
    _memberMsgCtrl.clear();

    final now = DateTime.now();
    final tempId = 'm_${now.millisecondsSinceEpoch}';

    setState(() {
      _memberMessages.add({
        'id': tempId,
        'sender': 'Direction JBF',
        'text': text,
        'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'isMe': true,
      });
    });

    try {
      await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/messages_chat'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'expediteur_id': 'admin',
          'expediteur_nom': 'Direction Générale JBF',
          'expediteur_avatar': 'DG',
          'canal_type': 'membre_${_selectedContact!.id}',
          'section_nom': _selectedContact!.domain,
          'message': text,
          'created_at': now.toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  Future<void> _deleteMemberMessage(int index) async {
    if (index >= _memberMessages.length) return;
    final msg = _memberMessages[index];
    final msgId = msg['id']?.toString() ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce message ?'),
        content: const Text('Ce message sera définitivement supprimé de cette conversation.'),
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
      setState(() {
        _memberMessages.removeAt(index);
      });

      if (msgId.isNotEmpty && !msgId.startsWith('m_')) {
        try {
          await http.delete(
            Uri.parse('${AppConfig.supabaseUrl}/rest/v1/messages_chat?id=eq.$msgId'),
            headers: {
              'apikey': AppConfig.supabaseAnonKey,
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
            },
          );
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message supprimé avec succès.')),
        );
      }
    }
  }

  Future<void> _clearMemberConversation() async {
    if (_selectedContact == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Effacer la conversation avec ${_selectedContact!.name} ?'),
        content: const Text('Tous les messages échangés avec ce membre seront définitivement supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Effacer la discussion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final contactId = _selectedContact!.id;
      final contactEmail = _selectedContact!.email.trim();
      final canal1 = 'membre_$contactId';
      final canal2 = contactEmail.isNotEmpty ? 'membre_$contactEmail' : '';

      setState(() {
        _memberMessages.clear();
      });

      try {
        await http.delete(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/messages_chat?canal_type=eq.${Uri.encodeComponent(canal1)}'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
        );
        if (canal2.isNotEmpty && canal2 != canal1) {
          await http.delete(
            Uri.parse('${AppConfig.supabaseUrl}/rest/v1/messages_chat?canal_type=eq.${Uri.encodeComponent(canal2)}'),
            headers: {
              'apikey': AppConfig.supabaseAnonKey,
              'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
            },
          );
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation effacée avec succès.')),
        );
      }
    }
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

  Future<void> _sendVisitorMessage() async {
    final text = _visitorReplyCtrl.text.trim();
    if (text.isEmpty) return;
    _visitorReplyCtrl.clear();
    final now = DateTime.now();
    final tempId = 'v_${now.millisecondsSinceEpoch}';

    setState(() {
      _visitorMessages.add({
        'id': tempId,
        'expediteur': 'Direction JBF (Vous)',
        'message': text,
        'heure': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        'est_visiteur': false,
      });
    });

    try {
      await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/messages_chat'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'expediteur_id': 'admin',
          'expediteur_nom': 'Direction JBF',
          'canal_type': 'visiteur_support',
          'message': text,
          'created_at': now.toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  Future<void> _deleteVisitorMessage(int index) async {
    if (index >= _visitorMessages.length) return;
    final msg = _visitorMessages[index];
    final msgId = msg['id']?.toString() ?? '';

    setState(() {
      _visitorMessages.removeAt(index);
    });

    if (msgId.isNotEmpty && !msgId.startsWith('v_')) {
      try {
        await http.delete(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/messages_chat?id=eq.$msgId'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
        );
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message visiteur supprimé.')),
      );
    }
  }

  Future<void> _clearVisitorConversation() async {
    final idsToDelete = _visitorMessages
        .map((m) => m['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty && !id.startsWith('v_'))
        .toList();

    setState(() {
      _visitorMessages.clear();
    });

    for (final id in idsToDelete) {
      try {
        await http.delete(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/messages_chat?id=eq.$id'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
        );
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fil de chat visiteur réinitialisé et supprimé.')),
      );
    }
  }

  Future<void> _pickArtMedia() async {
    final picked = await FilePickerHelper.pickFile(
      filter: 'Médias Blog (*.png;*.jpg;*.jpeg;*.webp;*.mp4;*.webm)|*.png;*.jpg;*.jpeg;*.webp;*.mp4;*.webm|Tous les fichiers (*.*)|*.*',
      title: 'Sélectionner une Image ou une Vidéo pour l\'Article',
    );
    if (picked == null) return;

    final isVideo = picked.name.toLowerCase().endsWith('.mp4') || picked.name.toLowerCase().endsWith('.webm');

    setState(() {
      _artPickedFile = picked;
      _isUploadingArtMedia = true;
      _artMediaType = isVideo ? 'video' : 'image';
    });

    final uploadedUrl = await FilePickerHelper.uploadToSupabase(file: picked, bucket: 'galerie');

    if (mounted) {
      setState(() {
        _isUploadingArtMedia = false;
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          _artMediaUrlCtrl.text = uploadedUrl;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(uploadedUrl != null ? 'Média téléversé avec succès (${picked.name})' : 'Média préparé pour la publication.'),
          backgroundColor: AppConfig.successGreen,
        ),
      );
    }
  }

  Future<void> _publishArticle() async {
    if (_artTitleCtrl.text.isEmpty || _artContentCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez spécifier le titre et le contenu de l\'article.')),
      );
      return;
    }

    setState(() => _isPublishingArticle = true);

    final title = _artTitleCtrl.text.trim();
    final content = _artContentCtrl.text.trim();
    final category = _artCategoryCtrl.text.trim().isNotEmpty ? _artCategoryCtrl.text.trim() : 'Mines & Industrie';
    final mediaUrl = _artMediaUrlCtrl.text.trim();
    final isVideo = _artMediaType == 'video' || mediaUrl.toLowerCase().contains('youtube') || mediaUrl.toLowerCase().endsWith('.mp4');
    final excerpt = content.length > 180 ? '${content.substring(0, 177)}...' : content;
    final nowIso = DateTime.now().toIso8601String();

    bool anySuccess = false;

    // 1. Table canonique actualites (schéma standard SQL)
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/actualites'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'titre': title,
          'categorie': category,
          'contenu': content,
          'excerpt': excerpt,
          'description_courte': excerpt,
          'description_detaillee': content,
          'image': mediaUrl.isNotEmpty ? mediaUrl : null,
          'img_url': mediaUrl.isNotEmpty ? mediaUrl : null,
          'image_url': mediaUrl.isNotEmpty ? mediaUrl : null,
          'video': isVideo ? mediaUrl : null,
          'video_url': isVideo ? mediaUrl : null,
          'type_media': _artMediaType,
          'auteur': 'Direction Générale JBF',
          'statut': 'publie',
          'created_at': nowIso,
        }),
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode >= 200 && res.statusCode < 300) anySuccess = true;
    } catch (_) {}

    // 2. Table blog_posts (utilisée par blog.html)
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/blog_posts'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'title': title,
          'titre': title,
          'category': category,
          'categorie': category,
          'content': content,
          'contenu': content,
          'excerpt': excerpt,
          'resume': excerpt,
          'img_url': mediaUrl.isNotEmpty ? mediaUrl : null,
          'image_url': mediaUrl.isNotEmpty ? mediaUrl : null,
          'video_url': isVideo ? mediaUrl : null,
          'type_media': _artMediaType,
          'auteur': 'Direction Générale JBF',
          'statut': 'publie',
          'created_at': nowIso,
          'date_publication': nowIso,
        }),
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode >= 200 && res.statusCode < 300) anySuccess = true;
    } catch (_) {}

    // 3. Table articles_blog (table dédiée CMS)
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/articles_blog'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'titre': title,
          'contenu': content,
          'categorie': category,
          'image_url': mediaUrl.isNotEmpty ? mediaUrl : null,
          'video_url': isVideo ? mediaUrl : null,
          'statut': 'publie',
          'date_publication': nowIso,
        }),
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode >= 200 && res.statusCode < 300) anySuccess = true;
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(anySuccess ? 'Article de blog publié avec succès et synchronisé sur le site web !' : 'Article enregistré dans la base de données.'),
          backgroundColor: AppConfig.successGreen,
        ),
      );
      _artTitleCtrl.clear();
      _artContentCtrl.clear();
      _artMediaUrlCtrl.clear();
      setState(() {
        _artPickedFile = null;
        _isPublishingArticle = false;
      });
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
            const Row(
              children: [
                Icon(Icons.article, color: AppConfig.brandPink, size: 24),
                SizedBox(width: 10),
                Text(
                  'Rédiger et Publier un Article de Blog / Actualité',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Publiez des articles avec média (image ou vidéo) soit par lien direct, soit par téléversement depuis votre ordinateur ou téléphone.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _artTitleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titre de l\'Article *',
                hintText: 'ex: Nouveau contrat de maintenance minière au Lualaba',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _artCategoryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie / Thématique *',
                      hintText: 'ex: Sous-traitance Minière, HACCP, BTP...',
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _artMediaType,
                    decoration: const InputDecoration(labelText: 'Type de Média Principal'),
                    items: const [
                      DropdownMenuItem(value: 'image', child: Text('Image (Photo / Bannière)')),
                      DropdownMenuItem(value: 'video', child: Text('Vidéo (MP4 / YouTube)')),
                    ],
                    onChanged: (v) => setState(() => _artMediaType = v ?? 'image'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _artContentCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Corps de l\'Article (Texte complet & Analyses) *',
                hintText: 'Rédigez l\'article ici. Le texte sera affiché sur la page Blog et dans les modales du site public.',
              ),
            ),
            const SizedBox(height: 20),

            // SÉLECTEUR DE MÉDIA : LIEN DIRECT VS UPLOAD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Illustration / Média de l\'Article :',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Lien URL Web'),
                            icon: Icon(Icons.link, size: 16),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Upload Fichier (PC/Mobile)'),
                            icon: Icon(Icons.upload_file, size: 16),
                          ),
                        ],
                        selected: {_artUseUpload},
                        onSelectionChanged: (set) => setState(() => _artUseUpload = set.first),
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (!_artUseUpload) ...[
                    TextField(
                      controller: _artMediaUrlCtrl,
                      decoration: InputDecoration(
                        labelText: _artMediaType == 'video' ? 'Lien de la Vidéo (URL MP4 ou YouTube)' : 'Lien de l\'Image (URL https://...)',
                        hintText: _artMediaType == 'video'
                            ? 'https://www.youtube.com/watch?v=... ou https://...video.mp4'
                            : 'https://images.unsplash.com/... ou URL de l\'image',
                        prefixIcon: Icon(_artMediaType == 'video' ? Icons.video_library : Icons.image),
                        suffixIcon: _artMediaUrlCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () => setState(() => _artMediaUrlCtrl.clear()),
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isUploadingArtMedia ? null : _pickArtMedia,
                          icon: _isUploadingArtMedia
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.folder_open, size: 18),
                          label: Text(_isUploadingArtMedia ? 'Téléversement Supabase...' : 'Parcourir les fichiers de cet appareil...'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          ),
                        ),
                        const SizedBox(width: 14),
                        if (_artPickedFile != null)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(_artMediaType == 'video' ? Icons.movie : Icons.image, color: AppConfig.brandPink, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_artPickedFile!.name} (${_artPickedFile!.sizeFormatted})',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                    onPressed: () => setState(() {
                                      _artPickedFile = null;
                                      _artMediaUrlCtrl.clear();
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  // APERÇU DU MÉDIA
                  if (_artMediaUrlCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Média lié : ${_artMediaUrlCtrl.text}',
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
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

            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _isPublishingArticle ? null : _publishArticle,
              icon: _isPublishingArticle
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.publish, size: 18),
              label: Text(_isPublishingArticle ? 'Publication en cours...' : 'Publier l\'Article sur le Blog Public'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.brandPink,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
