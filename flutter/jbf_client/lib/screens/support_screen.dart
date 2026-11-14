import 'package:flutter/material.dart';
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

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'Chef de Projet JBF (Lubumbashi)',
      'text': 'Bonjour et bienvenue sur le support dédié JBF Service ! En quoi pouvons-nous vous assister aujourd\'hui ?',
      'time': '10:00',
      'isClient': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;

    final text = _msgController.text.trim();
    setState(() {
      _messages.add({
        'sender': 'Vous',
        'text': text,
        'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'isClient': true,
      });
      _msgController.clear();
    });

    // Réponse automatique de prise en charge
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'sender': 'Service Client JBF',
          'text': 'Votre message a bien été transmis au chef de projet assigné. Nous vous répondons dans les plus brefs délais.',
          'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          'isClient': false,
        });
      });
    });
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
                        'Assistance & Live Chat Client 24/7',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConfig.blackText),
                      ),
                      Text(
                        'Échangez en direct avec votre chef de projet ou joignez nos astreintes sur site minier',
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
                    Tab(icon: Icon(Icons.chat), text: 'Live Chat Dédié'),
                    Tab(icon: Icon(Icons.phone_in_talk), text: 'Hotline & Astreintes 24/7'),
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
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            // Chat header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: AppConfig.successGreen),
                  SizedBox(width: 8),
                  Text('Équipe Support & Direction des Projets (En ligne)', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Message list
            Expanded(
              child: ListView.builder(
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
                        color: isClient ? AppConfig.brandPinkTint : const Color(0xFFF1F2F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isClient ? AppConfig.brandPink.withOpacity(0.3) : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isClient ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(m['sender'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
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
                        hintText: 'Posez votre question à votre chef de projet JBF...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppConfig.brandPink),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
