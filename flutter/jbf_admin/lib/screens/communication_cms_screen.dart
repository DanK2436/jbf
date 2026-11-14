import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class CommunicationCmsScreen extends StatefulWidget {
  const CommunicationCmsScreen({super.key});

  @override
  State<CommunicationCmsScreen> createState() => _CommunicationCmsScreenState();
}

class _CommunicationCmsScreenState extends State<CommunicationCmsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _newsTitleCtrl = TextEditingController();
  final TextEditingController _newsMsgCtrl = TextEditingController();
  String _targetAudience = 'tous'; // 'tous', 'clients', 'membres'
  bool _isSendingNotification = false;

  // Chat
  final TextEditingController _chatReplyCtrl = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [
    {
      'expediteur': 'Visiteur Web (Lubumbashi)',
      'message': 'Bonjour, quel est le délai moyen pour une cotation de soudure industrielle haute pression ?',
      'heure': '14:22',
      'est_visiteur': true,
    },
    {
      'expediteur': 'Chef de Projet JBF (Opérateur)',
      'message': 'Bonjour ! Nos devis de chaudronnerie et soudure certifiée sont émis sous 24h ouvrées.',
      'heure': '14:25',
      'est_visiteur': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _sendBroadcastNotification() async {
    if (_newsTitleCtrl.text.isEmpty || _newsMsgCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner un titre et un contenu de message.')),
      );
      return;
    }

    setState(() => _isSendingNotification = true);

    try {
      // Envoi broadcast via backend ou Supabase notifications_diffusees
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

  void _sendLiveChatMessage() {
    if (_chatReplyCtrl.text.isEmpty) return;
    setState(() {
      _chatMessages.add({
        'expediteur': 'Direction JBF (Vous)',
        'message': _chatReplyCtrl.text.trim(),
        'heure': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'est_visiteur': false,
      });
      _chatReplyCtrl.clear();
    });
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
                        'Communication, CMS & Live Chat',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText),
                      ),
                      Text(
                        'Gestion des articles du blog, diffusion de newsletters/alertes ciblées et réponses en direct aux visiteurs',
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
                    Tab(icon: Icon(Icons.article_outlined), text: 'CMS & Blog'),
                    Tab(icon: Icon(Icons.campaign_outlined), text: 'Diffusion Newsletters & Push'),
                    Tab(icon: Icon(Icons.chat_outlined), text: 'Console Live Chat Direct'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: CMS & Blog
                _buildCmsTab(),

                // TAB 2: Newsletters & Notifications
                _buildBroadcastTab(),

                // TAB 3: Live Chat
                _buildChatTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCmsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                const TextField(
                  decoration: InputDecoration(labelText: 'Titre de l\'Article *', hintText: 'ex: Nouveau contrat de maintenance minière au Lualaba'),
                ),
                const SizedBox(height: 14),
                const TextField(
                  maxLines: 4,
                  decoration: InputDecoration(labelText: 'Contenu / Résumé exécutif (Markdown & HTML supportés) *'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.image, size: 16),
                      label: const Text('Joindre une Image / Vidéo'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Article publié sur le site web public !'), backgroundColor: AppConfig.successGreen),
                        );
                      },
                      icon: const Icon(Icons.publish, size: 16),
                      label: const Text('Publier sur le Site Web'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildChatTab() {
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
            // Chat header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: AppConfig.successGreen),
                  SizedBox(width: 8),
                  Text('Console Opérateur Live Chat (Visiteurs en ligne)', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Message list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _chatMessages.length,
                itemBuilder: (context, i) {
                  final msg = _chatMessages[i];
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
                          Text(msg['expediteur'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
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

            // Message input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatReplyCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Saisissez votre réponse au visiteur en direct...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendLiveChatMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppConfig.brandPink),
                    onPressed: _sendLiveChatMessage,
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
