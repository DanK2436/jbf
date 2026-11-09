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

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = SupabaseService();
  bool _isLoading = true;
  String _currentCanal = 'general';
  List<ChatMessage> _messages = [];
  final _msgController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
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

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  const Text('Messagerie Interne & Canaux d\'Équipes (BDD)',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Messages temps réel synchronisés dans la table messages_chat Supabase',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                    tooltip: 'Actualiser le chat',
                    onPressed: _loadMessages,
                  ),
                  const SizedBox(width: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'general', label: Text('# Général')),
                      ButtonSegment(value: 'hse-securite', label: Text('# HSE & Sécurité')),
                      ButtonSegment(value: 'missions', label: Text('# Missions & Chantiers')),
                    ],
                    selected: {_currentCanal},
                    onSelectionChanged: (val) {
                      setState(() => _currentCanal = val.first);
                      _loadMessages();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          Expanded(
            child: Card(
              child: Column(
                children: [
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
                        : _messages.isEmpty
                            ? Center(
                                child: Text('Aucun message sur le canal #$_currentCanal dans la base de données.'),
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
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isMe ? AppConfig.brandPink : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            msg.senderName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: isMe ? Colors.white70 : AppConfig.brandPinkDark,
                                            ),
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
                              hintText: 'Écrire un message dans #$_currentCanal (sauvegarde Supabase)...',
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
