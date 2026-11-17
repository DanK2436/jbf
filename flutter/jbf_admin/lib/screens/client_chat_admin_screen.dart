import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ClientChatItem {
  final String id;
  final String clientName;
  final String clientEmail;
  final String company;
  final String lastMessage;
  final DateTime lastDate;
  final int unreadCount;

  ClientChatItem({
    required this.id,
    required this.clientName,
    required this.clientEmail,
    required this.company,
    required this.lastMessage,
    required this.lastDate,
    this.unreadCount = 0,
  });
}

class ClientChatAdminScreen extends StatefulWidget {
  final String? preselectedClientId;
  final String? preselectedClientName;
  final String? preselectedClientEmail;
  final String? preselectedCompany;

  const ClientChatAdminScreen({
    super.key,
    this.preselectedClientId,
    this.preselectedClientName,
    this.preselectedClientEmail,
    this.preselectedCompany,
  });

  @override
  State<ClientChatAdminScreen> createState() => _ClientChatAdminScreenState();
}

class _ClientChatAdminScreenState extends State<ClientChatAdminScreen> {
  bool _isLoading = true;
  List<ClientChatItem> _clients = [];
  ClientChatItem? _selectedClient;
  List<Map<String, dynamic>> _messages = [];
  final _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/profiles?role=eq.client&select=*'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final mapped = list.map((c) => ClientChatItem(
              id: c['id']?.toString() ?? '',
              clientName: c['full_name'] ?? c['nom_complet'] ?? 'Partenaire Client',
              clientEmail: c['email'] ?? '',
              company: c['company'] ?? c['entreprise'] ?? 'Société B2B',
              lastMessage: 'Demande d\'assistance ou devis en cours',
              lastDate: DateTime.now().subtract(const Duration(minutes: 30)),
              unreadCount: 1,
            )).toList();

        // Si un client spécifique a été demandé (ex: suite à l'acceptation d'un devis)
        if (widget.preselectedClientId != null && widget.preselectedClientId!.isNotEmpty) {
          final alreadyThere = mapped.any((c) => c.id == widget.preselectedClientId || c.clientEmail == widget.preselectedClientEmail);
          if (!alreadyThere) {
            mapped.insert(
              0,
              ClientChatItem(
                id: widget.preselectedClientId!,
                clientName: widget.preselectedClientName ?? 'Client Partenaire',
                clientEmail: widget.preselectedClientEmail ?? '',
                company: widget.preselectedCompany ?? 'Demandeur de Devis',
                lastMessage: 'Devis accepté — Début des échanges',
                lastDate: DateTime.now(),
                unreadCount: 0,
              ),
            );
          }
        }

        if (mounted) {
          setState(() {
            _clients = mapped;
            if (_clients.isNotEmpty) {
              if (widget.preselectedClientId != null) {
                _selectedClient = _clients.firstWhere(
                  (c) => c.id == widget.preselectedClientId || c.clientEmail == widget.preselectedClientEmail,
                  orElse: () => _clients.first,
                );
              } else {
                _selectedClient = _clients.first;
              }
              _loadClientMessages(_selectedClient!);
            }
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        if (widget.preselectedClientId != null && widget.preselectedClientId!.isNotEmpty) {
          _clients = [
            ClientChatItem(
              id: widget.preselectedClientId!,
              clientName: widget.preselectedClientName ?? 'Client Partenaire',
              clientEmail: widget.preselectedClientEmail ?? '',
              company: widget.preselectedCompany ?? 'Demandeur de Devis',
              lastMessage: 'Devis accepté — Début des échanges',
              lastDate: DateTime.now(),
              unreadCount: 0,
            ),
          ];
          _selectedClient = _clients.first;
          _loadClientMessages(_selectedClient!);
        } else {
          _clients = [];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _loadClientMessages(ClientChatItem client) async {
    List<Map<String, dynamic>> realMessages = [];

    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/messages_chat?canal_type=in.(client_${client.id},client_${client.clientEmail})&order=created_at.asc'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        for (var row in list) {
          final dt = DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now();
          final isAdmin = row['expediteur_id'] == 'admin' || (row['expediteur_nom'] ?? '').toString().contains('Direction');
          realMessages.add({
            'id': row['id']?.toString() ?? '',
            'sender': row['expediteur_nom'] ?? (isAdmin ? 'Direction Générale JBF' : client.clientName),
            'company': isAdmin ? 'JBF Services SARL' : client.company,
            'text': row['message'] ?? '',
            'time': '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
            'isAdmin': isAdmin,
          });
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _messages = realMessages;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _selectedClient == null) return;
    _msgCtrl.clear();

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final tempId = 'm-${now.millisecondsSinceEpoch}';

    setState(() {
      _messages.add({
        'id': tempId,
        'sender': 'Direction Générale JBF',
        'company': 'JBF Services SARL',
        'text': text,
        'time': timeStr,
        'isAdmin': true,
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
          'canal_type': 'client_${_selectedClient!.id}',
          'section_nom': _selectedClient!.company,
          'message': text,
          'created_at': now.toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  Future<void> _deleteMessage(int index) async {
    if (index >= _messages.length) return;
    final msg = _messages[index];
    final msgId = msg['id']?.toString() ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce message'),
        content: const Text('Voulez-vous supprimer ce message de la discussion client ?'),
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
      setState(() => _messages.removeAt(index));

      if (msgId.isNotEmpty && !msgId.startsWith('m-')) {
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
          const SnackBar(content: Text('Message supprimé.')),
        );
      }
    }
  }

  Future<void> _deleteConversation() async {
    if (_selectedClient == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la conversation'),
        content: Text('Voulez-vous effacer l\'historique avec ${_selectedClient!.company} ?'),
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
      setState(() => _messages.clear());

      try {
        await http.delete(
          Uri.parse('${AppConfig.supabaseUrl}/rest/v1/messages_chat?canal_type=in.(client_${_selectedClient!.id},client_${_selectedClient!.clientEmail})'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          },
        );
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fil de discussion effacé avec succès.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('Messagerie Dédiée — Clients & Partenaires B2B',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConfig.blackText)),
                  Text('Échanges directs exclusifs avec les donneurs d\'ordre industriels et miniers',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppConfig.brandPink),
                tooltip: 'Actualiser',
                onPressed: _loadClients,
              ),
            ],
          ),
          const SizedBox(height: 18),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Liste gauche : Clients
                Container(
                  width: 320,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.apartment, color: AppConfig.brandPink, size: 20),
                            const SizedBox(width: 8),
                            Text('Entreprises Clientes (${_clients.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: AppConfig.brandPink))
                            : ListView.separated(
                                itemCount: _clients.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final cl = _clients[i];
                                  final isSel = _selectedClient?.id == cl.id;

                                  return ListTile(
                                    selected: isSel,
                                    selectedTileColor: AppConfig.brandPinkTint,
                                    leading: CircleAvatar(
                                      backgroundColor: isSel ? AppConfig.brandPink : Colors.grey.shade200,
                                      foregroundColor: isSel ? Colors.white : AppConfig.blackText,
                                      child: Text(cl.company.substring(0, 2).toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    title: Text(cl.company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: Text(cl.lastMessage, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    trailing: cl.unreadCount > 0
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: AppConfig.brandPink, borderRadius: BorderRadius.circular(10)),
                                            child: Text('${cl.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          )
                                        : null,
                                    onTap: () {
                                      setState(() => _selectedClient = cl);
                                      _loadClientMessages(cl);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),

                // Panneau droit : Conversation
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _selectedClient == null
                        ? const Center(child: Text('Sélectionnez un client pour ouvrir le fil de discussion.'))
                        : Column(
                            children: [
                              // Chat Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppConfig.brandPink,
                                      foregroundColor: Colors.white,
                                      radius: 18,
                                      child: Text(_selectedClient!.company.substring(0, 2).toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_selectedClient!.company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text('${_selectedClient!.clientName} • ${_selectedClient!.clientEmail}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_sweep_outlined, color: AppConfig.dangerRed),
                                      tooltip: 'Vider cette discussion client',
                                      onPressed: _deleteConversation,
                                    ),
                                  ],
                                ),
                              ),

                              // Message Feed
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _messages.length,
                                  itemBuilder: (context, idx) {
                                    final m = _messages[idx];
                                    final isAdmin = m['isAdmin'] == true;

                                    return Align(
                                      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        constraints: const BoxConstraints(maxWidth: 480),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isAdmin ? AppConfig.brandPink : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  m['sender'] ?? '',
                                                  style: TextStyle(
                                                    color: isAdmin ? Colors.white70 : AppConfig.brandPinkDark,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                InkWell(
                                                  onTap: () => _deleteMessage(idx),
                                                  child: Icon(Icons.close, size: 12, color: isAdmin ? Colors.white60 : Colors.grey),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              m['text'] ?? '',
                                              style: TextStyle(
                                                color: isAdmin ? Colors.white : AppConfig.blackText,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              m['time'] ?? '',
                                              style: TextStyle(
                                                color: isAdmin ? Colors.white60 : Colors.grey.shade600,
                                                fontSize: 9.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Input
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _msgCtrl,
                                        decoration: const InputDecoration(
                                          hintText: 'Écrire une réponse officielle au client...',
                                          border: InputBorder.none,
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppConfig.brandPink),
                                      onPressed: _sendMessage,
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
          ),
        ],
      ),
    );
  }
}
