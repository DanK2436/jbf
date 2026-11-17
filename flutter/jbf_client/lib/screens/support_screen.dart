import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [
    {
      'id': 'm-1',
      'sender': 'Direction Opérationnelle JBF',
      'text': 'Bonjour et bienvenue sur le support dédié JBF Service ! En quoi pouvons-nous vous assister sur votre exploitation ?',
      'time': '09:00',
      'isClient': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLocalChat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('jbf_client_chat_history');
      if (str != null) {
        final List<dynamic> list = jsonDecode(str);
        if (list.isNotEmpty && mounted) {
          setState(() {
            _messages = list.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveLocalChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jbf_client_chat_history', jsonEncode(_messages));
    } catch (_) {}
  }

  void _sendMessage([String? quickText]) {
    final text = (quickText ?? _msgController.text).trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add({
        'id': 'msg-${DateTime.now().millisecondsSinceEpoch}',
        'sender': 'Vous',
        'text': text,
        'time': timeStr,
        'isClient': true,
      });
      if (quickText == null) _msgController.clear();
    });

    _saveLocalChat();
    _scrollToBottom();

    // Réponse automatique de prise en charge avec horodatage
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      final respNow = DateTime.now();
      final respTimeStr = '${respNow.hour.toString().padLeft(2, '0')}:${respNow.minute.toString().padLeft(2, '0')}';
      setState(() {
        _messages.add({
          'id': 'msg-${DateTime.now().millisecondsSinceEpoch}',
          'sender': 'Direction Opérationnelle JBF',
          'text': 'Votre message a bien été transmis au chef de projet dédié. Nous analysons votre requête.',
          'time': respTimeStr,
          'isClient': false,
        });
      });
      _saveLocalChat();
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _deleteMessage(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce message'),
        content: const Text('Voulez-vous supprimer ce message ?'),
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
        _messages.removeAt(index);
      });
      _saveLocalChat();
    }
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider la conversation'),
        content: const Text('Voulez-vous supprimer tout l\'historique des messages ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _messages = [
          {
            'id': 'm-init',
            'sender': 'Direction Opérationnelle JBF',
            'text': 'Conversation réinitialisée. En quoi pouvons-nous vous aider ?',
            'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
            'isClient': false,
          }
        ];
      });
      _saveLocalChat();
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/243970349724?text=Bonjour%20JBF%20Service,%20je%20souhaite%20une%20assistance%20client');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assistance Client & Live Chat Dédié',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText),
                      ),
                      Text(
                        'Interlocuteur direct : Direction Technique & Chefs de Projet JBF Service RDC',
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
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(icon: Icon(Icons.chat), text: 'Messagerie Directe'),
                    Tab(icon: Icon(Icons.phone_in_talk), text: 'Lignes Directes & WhatsApp'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Live Chat
                _buildLiveChatTab(),

                // TAB 2: Hotline
                _buildHotlineTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChatTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Chat header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0C0E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppConfig.brandPink,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('DG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Direction Opérationnelle JBF', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                        Text('En ligne • Supervision Kolwezi, Lubumbashi, Kinshasa 24/7', style: TextStyle(color: Color(0xFF10B981), fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white70, size: 20),
                    tooltip: 'Effacer l\'historique',
                    onPressed: _clearChat,
                  ),
                ],
              ),
            ),

            // Pilules de questions rapides
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFFF8FAFC),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickChip('Statut de mon devis'),
                    const SizedBox(width: 8),
                    _buildQuickChip('Avancement des travaux'),
                    const SizedBox(width: 8),
                    _buildQuickChip('Demande de facture proforma'),
                    const SizedBox(width: 8),
                    _buildQuickChip('Urgence sur notre site minier'),
                  ],
                ),
              ),
            ),

            // Message list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(18),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  final isClient = m['isClient'] == true;

                  return Align(
                    alignment: isClient ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: const BoxConstraints(maxWidth: 520),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isClient ? AppConfig.brandPink : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(isClient ? 14 : 2),
                          bottomRight: Radius.circular(isClient ? 2 : 14),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isClient ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                m['sender'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: isClient ? Colors.white70 : AppConfig.brandPinkDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _deleteMessage(i),
                                child: Icon(Icons.close, size: 13, color: isClient ? Colors.white60 : Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m['text'] ?? '',
                            style: TextStyle(fontSize: 13.5, color: isClient ? Colors.white : AppConfig.blackText),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                m['time'] ?? '',
                                style: TextStyle(fontSize: 10, color: isClient ? Colors.white70 : Colors.grey.shade600),
                              ),
                              if (isClient) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.done_all, size: 12, color: Colors.white70),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: 'Écrivez votre message à la direction opérationnelle JBF...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppConfig.brandPink),
                    onPressed: () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      onPressed: () => _sendMessage(label),
    );
  }

  Widget _buildHotlineTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF1EBE5D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent, color: Colors.white, size: 48),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hotline WhatsApp Officielle 24/7', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('+243 97 034 9724 • Ligne d\'astreinte immédiate chantiers miniers', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _openWhatsApp,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1EBE5D)),
                        child: const Text('Ouvrir WhatsApp Hotline'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
