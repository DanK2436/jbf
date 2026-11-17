import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/membre_models.dart';
import '../services/supabase_service.dart';

class ChatScreen extends StatefulWidget {
  final MembreUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final _supabase = SupabaseService();
  late TabController _tabController;
  bool _isLoading = true;

  // Canaux
  String _currentCanal = 'direction_generale';
  String _subCanalCollaboration = 'chef_avec_membres';

  List<ChatMessage> _messages = [];
  final _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          if (_tabController.index == 0) {
            _currentCanal = 'direction_generale';
          } else {
            _currentCanal = _subCanalCollaboration;
          }
        });
        _loadMessages();
      }
    });
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final list = await _supabase.fetchChatMessages(_currentCanal, myName: widget.user.fullName);
    if (!mounted) return;
    setState(() {
      _messages = list;
      _isLoading = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    await _supabase.sendChatMessage(
      senderName: widget.user.fullName,
      avatar: widget.user.avatar,
      message: text,
      canal: _currentCanal,
    );

    _loadMessages();
  }

  Future<void> _deleteMessage(ChatMessage msg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce message'),
        content: const Text('Voulez-vous supprimer définitivement ce message pour tout le monde ?'),
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
        _messages.removeWhere((m) => m.id == msg.id);
      });
      try {
        await _supabase.deleteChatMessage(msg.id);
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message supprimé avec succès.')),
      );
    }
  }

  Future<void> _clearConversation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider la conversation'),
        content: Text('Êtes-vous sûr de vouloir effacer l\'historique du canal #$_currentCanal ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.dangerRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Tout effacer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _messages.clear();
      });
      try {
        await _supabase.clearChatCanal(_currentCanal);
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation vidée avec succès.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête & Onglets de Différenciation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Messagerie Collaborative JBF (BDD)',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(
                    _tabController.index == 0
                        ? 'Échanges officiels & confidentiels avec la Direction Générale RDC'
                        : 'Sous-page de collaboration entre Chefs de section et Membres',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                    tooltip: 'Actualiser',
                    onPressed: _loadMessages,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: AppConfig.dangerRed),
                    tooltip: 'Vider cette conversation',
                    onPressed: _clearConversation,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Double Onglet : Direction vs Collaboration Membres
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppConfig.brandPink,
              labelColor: AppConfig.brandPink,
              unselectedLabelColor: Colors.grey.shade700,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.shield),
                  text: 'Direction Générale (Échanges Hiérarchiques)',
                ),
                Tab(
                  icon: Icon(Icons.groups),
                  text: 'Collaboration Inter-Membres & Chefs de Section',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Sous-sélecteur de canal pour la collaboration
          if (_tabController.index == 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Text('Sous-canal :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'chef_avec_membres', label: Text('Chef avec ses Membres')),
                        ButtonSegment(value: 'entre_chefs_section', label: Text('Entre Chefs de Section')),
                        ButtonSegment(value: 'technique_chantiers', label: Text('Chantiers & Terrain')),
                      ],
                      selected: {_subCanalCollaboration},
                      onSelectionChanged: (val) {
                        setState(() {
                          _subCanalCollaboration = val.first;
                          _currentCanal = _subCanalCollaboration;
                        });
                        _loadMessages();
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Liste des messages & Zone d'écriture
          Expanded(
            child: Card(
              child: Column(
                children: [
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
                        : _messages.isEmpty
                            ? Center(
                                child: Text('Aucun message sur ce fil (#$_currentCanal). Écrivez le premier message.'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final msg = _messages[index];
                                  final isMe = msg.isMe || msg.senderName == widget.user.fullName;

                                  return Align(
                                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isMe ? AppConfig.brandPink : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                msg.senderName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                  color: isMe ? Colors.white70 : AppConfig.brandPinkDark,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: () => _deleteMessage(msg),
                                                child: Icon(
                                                  Icons.delete_outline,
                                                  size: 14,
                                                  color: isMe ? Colors.white54 : Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            msg.message,
                                            style: TextStyle(
                                              color: isMe ? Colors.white : AppConfig.blackText,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isMe ? Colors.white60 : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            decoration: InputDecoration(
                              hintText: _tabController.index == 0
                                  ? 'Écrire un message à la Direction Générale JBF...'
                                  : 'Écrire à l\'équipe (#$_currentCanal)...',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text('Envoyer'),
                          onPressed: _sendMessage,
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
}
