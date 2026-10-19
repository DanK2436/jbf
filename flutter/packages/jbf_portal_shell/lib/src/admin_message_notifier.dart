import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'portal_runtime.dart';

const _prefLastMessageId = 'jbf_admin_last_chat_message_id';
const _adminUserId = 'admin-jbf';
const _signalPrefix = '[CALL_SIGNAL]';

/// Filtre les messages entrants pertinents pour l’admin (DM chefs → direction).
List<Map<String, dynamic>> filterIncomingAdminMessages(
  List<dynamic> rows,
) {
  final out = <Map<String, dynamic>>[];
  for (final raw in rows) {
    if (raw is! Map) continue;
    final map = Map<String, dynamic>.from(raw);
    final canal = (map['canal_type'] ?? '').toString();
    if (canal != 'direct') continue;
    final uid = (map['user_id'] ?? '').toString();
    if (uid == _adminUserId) continue;
    final body = (map['message'] ?? '').toString();
    if (body.isEmpty || body.startsWith(_signalPrefix)) continue;
    out.add(map);
  }
  return out;
}

class AdminMessageNotifier {
  AdminMessageNotifier(this.runtime);

  final PortalRuntime runtime;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Timer? _pollTimer;
  String? _lastSeenId;
  bool _initialized = false;

  Future<void> initialize() async {
    if (!runtime.messageNotifications || !runtime.hasSupabase) return;
    if (kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const init = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: (_) {},
    );

    final prefs = await SharedPreferences.getInstance();
    _lastSeenId = prefs.getString(_prefLastMessageId);
    _initialized = true;
  }

  void startPolling({Duration interval = const Duration(seconds: 45)}) {
    if (!_initialized) return;
    _pollTimer?.cancel();
    unawaited(_pollOnce());
    _pollTimer = Timer.periodic(interval, (_) => _pollOnce());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> dispose() async {
    stopPolling();
  }

  Future<void> _pollOnce() async {
    if (!runtime.hasSupabase) return;
    try {
      final uri = Uri.parse('${runtime.supabaseUrl}/rest/v1/messages_chat').replace(
        queryParameters: {
          'select': 'id,created_at,expediteur_nom,message,canal_type,user_id',
          'order': 'created_at.desc',
          'limit': '20',
        },
      );
      final res = await http.get(
        uri,
        headers: {
          'apikey': runtime.supabaseAnonKey,
          'Authorization': 'Bearer ${runtime.supabaseAnonKey}',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode < 200 || res.statusCode >= 300) return;

      final decoded = jsonDecode(res.body);
      if (decoded is! List) return;
      final incoming = filterIncomingAdminMessages(decoded);
      if (incoming.isEmpty) return;

      incoming.sort((a, b) {
        final ta = DateTime.tryParse('${a['created_at']}') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = DateTime.tryParse('${b['created_at']}') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });

      final latest = incoming.first;
      final latestId = (latest['id'] ?? latest['created_at']).toString();
      if (_lastSeenId == null) {
        _lastSeenId = latestId;
        await _persistLastId(latestId);
        return;
      }
      if (latestId == _lastSeenId) return;

      final newOnes = <Map<String, dynamic>>[];
      for (final m in incoming) {
        final id = (m['id'] ?? m['created_at']).toString();
        if (id == _lastSeenId) break;
        newOnes.add(m);
      }
      if (newOnes.isEmpty) {
        _lastSeenId = latestId;
        await _persistLastId(latestId);
        return;
      }

      for (final m in newOnes.reversed) {
        await _showNotification(m);
      }
      _lastSeenId = latestId;
      await _persistLastId(latestId);
    } catch (e, st) {
      debugPrint('[JBF Admin notify] $e\n$st');
    }
  }

  Future<void> _persistLastId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLastMessageId, id);
  }

  Future<void> _showNotification(Map<String, dynamic> msg) async {
    final from = (msg['expediteur_nom'] ?? 'Chef d\'équipe').toString();
    var body = (msg['message'] ?? '').toString();
    if (body.length > 180) body = '${body.substring(0, 177)}…';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'jbf_admin_messages',
        'Messages équipes',
        channelDescription: 'Nouveaux messages des chefs d\'équipe',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      msg.hashCode,
      'Nouveau message — $from',
      body,
      details,
    );
  }
}
