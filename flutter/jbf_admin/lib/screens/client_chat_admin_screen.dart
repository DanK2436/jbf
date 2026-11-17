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
  const ClientChatAdminScreen({super.key});

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

        if (mounted) {
          setState(() {
            _clients = mapped;
            if (_clients.isNotEmpty) {
              _selectedClient = _clients.first;
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
        if (_clients.isEmpty) {
          _clients = [
            ClientChatItem(
              id: 'c-1',
              clientName: 'Directeur Approvisionnements',
              clientEmail: 'procurement@tenke.cd',
              company: 'Tenke Fungurume Mining S.A.',
              lastMessage: 'Ajustement effectif équipe soudure site Fungurume',
              lastDate: DateTime.now().subtract(const Duration(minutes: 15)),
              unreadCount: 2,
            ),
            ClientChatItem(
              id: 'c-2',
              clientName: 'Responsable Base-Vie',
              clientEmail: 'catering@kamoa.cd',
              company: 'Kamoa Copper SA',
              lastMessage: 'Validation du planning des repas HACCP semaine prochaine',
              lastDate: DateTime.now().subtract(const Duration(hours: 2)),
              unreadCount: 0,
            ),
            ClientChatItem(
              id: 'c-3',
              clientName: 'Chef de Chantier Génie Civil',
              clientEmail: 'contact@btp-lualaba.cd',
              company: 'Enterprise Mining Kolwezi',
              lastMessage: 'Besoin de 2 camions bennes 8x4 supplémentaires',
              lastDate: DateTime.now().subtract(const Duration(days: 1)),
              unreadCount: 0,
            ),
          ];
          _selectedClient = _clients.first;
          _loadClientMessages(_selectedClient!);
        }
        _isLoading = false;
      });
    }
  }

  void _loadClientMessages(ClientChatItem client) {
    setState(() {
      _messages = [
        {
          'id': 'm-1',
          'sender': client.clientName,
          'company': client.company,
          'text': 'Bonjour Direction JBF. Nous aimerions faire un point sur nos prestations en cours.',
          'time': '10:15',
          'isAdmin': false,
        },
        {
          'id': 'm-2',
          'sender': 'Direction Générale JBF',
          'company': 'JBF Services SARL',
          'text': 'Bonjour Monsieur. Notre directeur technique et nos équipes sont mobilisés. Quel point souhaitez-vous aborder ?',
          'time': '10:20',
          'isAdmin': true,
        },
        {
          'id': 'm-3',
          'sender': client.clientName,
          'company': client.company,
          'text': client.lastMessage,
          'time': '10:28',
          'isAdmin': false,
        },
      ];
    });
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _selectedClient == null) return;

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add({
        'id': 'm-${DateTime.now().millisecondsSinceEpoch}',
        'sender': 'Direction Générale JBF',
        'company': 'JBF Services SARL',
        'text': text,
        'time': timeStr,
        'isAdmin': true,
      });
      _msgCtrl.clear();
    });
  }

  Future<void> _deleteMessage(int index) async {
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message supprimé.')),
      );
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fil de discussion effacé avec succès.')),
      );
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
