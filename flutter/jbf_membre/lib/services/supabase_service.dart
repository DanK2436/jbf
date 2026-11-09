import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/membre_models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String _baseUrl = '${AppConfig.supabaseUrl}/rest/v1';
  static const Map<String, String> _headers = {
    'apikey': AppConfig.supabaseAnonKey,
    'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  // -------------------------------------------------------------
  // MISSIONS DU MEMBRE
  // -------------------------------------------------------------
  Future<List<MembreMission>> fetchMissions({String? agentNom}) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/missions?select=*&order=created_at.desc'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((j) => MembreMission(
              id: j['id']?.toString() ?? '',
              titre: j['titre'] ?? 'Mission Terrain',
              client: j['client'] ?? 'Client Partenaire',
              siteIntervention: j['site_intervention'] ?? 'RDC',
              serviceNom: j['service_nom'] ?? 'Sous-traitance',
              dateDebut: DateTime.tryParse(j['date_debut'] ?? '') ?? DateTime.now(),
              dateFin: DateTime.tryParse(j['date_fin'] ?? ''),
              description: j['description'] ?? '',
              statut: j['statut'] ?? 'en_cours',
              chefEquipe: j['assigned_to'] ?? '',
              effectif: int.tryParse(j['effectif']?.toString() ?? '1') ?? 1,
              rapport: j['rapport'] ?? '',
            )).toList();
      }
    } catch (e) {
      print('Erreur fetchMissions membre: $e');
    }
    return [];
  }

  Future<bool> updateMissionRapport(String id, String rapport, String statut) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/missions?id=eq.$id'),
        headers: _headers,
        body: jsonEncode({
          'rapport': rapport,
          'statut': statut,
        }),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur updateMissionRapport: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // POINTAGES & HORODATAGE GPS
  // -------------------------------------------------------------
  Future<List<PointageRecord>> fetchPointages({String? matricule}) async {
    try {
      String url = '$_baseUrl/pointages?select=*&order=date_heure.desc';
      if (matricule != null && matricule.isNotEmpty) {
        url = '$_baseUrl/pointages?matricule=eq.$matricule&order=date_heure.desc';
      }
      final res = await http.get(Uri.parse(url), headers: _headers);
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((j) => PointageRecord(
              id: j['id']?.toString() ?? '',
              dateHeure: DateTime.tryParse(j['date_heure'] ?? '') ?? DateTime.now(),
              typePointage: j['type_pointage'] ?? 'entree',
              siteLieu: j['site_lieu'] ?? 'RDC',
              latitude: (j['latitude'] as num?)?.toDouble() ?? -10.7183,
              longitude: (j['longitude'] as num?)?.toDouble() ?? 25.4729,
              ipAddress: j['ip_address'] ?? '127.0.0.1',
              isVpn: j['is_vpn'] == true,
              statutValidation: j['statut_validation'] ?? 'valide',
              heuresNormales: (j['heures_normales'] as num?)?.toDouble() ?? 8.0,
              heuresSup: (j['heures_supplementaires'] as num?)?.toDouble() ?? 0.0,
            )).toList();
      }
    } catch (e) {
      print('Erreur fetchPointages membre: $e');
    }
    return [];
  }

  Future<PointageRecord?> recordPointage({
    required String agentNom,
    required String matricule,
    required String siteLieu,
    required String typePointage,
  }) async {
    try {
      final now = DateTime.now();
      final body = {
        'agent_nom': agentNom,
        'matricule': matricule,
        'site_lieu': siteLieu,
        'type_pointage': typePointage,
        'date_heure': now.toIso8601String(),
        'latitude': -10.7183,
        'longitude': 25.4729,
        'precision_gps': 8.5,
        'ip_address': '105.101.44.12 (Airtel RDC)',
        'is_vpn': false,
        'statut_validation': 'valide',
        'heures_normales': typePointage == 'sortie' ? 8.0 : 0.0,
        'heures_supplementaires': 0.0,
      };

      final res = await http.post(
        Uri.parse('$_baseUrl/pointages'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return PointageRecord(
          id: 'PT-NEW',
          dateHeure: now,
          typePointage: typePointage,
          siteLieu: siteLieu,
          latitude: -10.7183,
          longitude: 25.4729,
          ipAddress: '105.101.44.12 (Airtel RDC)',
          isVpn: false,
          statutValidation: 'valide',
        );
      }
    } catch (e) {
      print('Erreur recordPointage: $e');
    }
    return null;
  }

  // -------------------------------------------------------------
  // DEMANDES DE CONGÉS
  // -------------------------------------------------------------
  Future<List<LeaveRequest>> fetchLeaves({String? agentNom}) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/demandes_conges?select=*&order=created_at.desc'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((j) => LeaveRequest(
              id: j['id']?.toString() ?? '',
              typeConge: j['type_conge'] ?? 'Annuel',
              dateDebut: DateTime.tryParse(j['date_debut'] ?? '') ?? DateTime.now(),
              dateFin: DateTime.tryParse(j['date_fin'] ?? '') ?? DateTime.now(),
              nombreJours: int.tryParse(j['nombre_jours']?.toString() ?? '1') ?? 1,
              motif: j['motif'] ?? '',
              statut: j['statut'] ?? 'en_attente',
              commentaireAdmin: j['commentaire_admin'] ?? '',
            )).toList();
      }
    } catch (e) {
      print('Erreur fetchLeaves: $e');
    }
    return [];
  }

  Future<bool> createLeaveRequest({
    required String agentNom,
    required String typeConge,
    required DateTime debut,
    required DateTime fin,
    required int jours,
    required String motif,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/demandes_conges'),
        headers: _headers,
        body: jsonEncode({
          'agent_nom': agentNom,
          'type_conge': typeConge,
          'date_debut': debut.toIso8601String().split('T')[0],
          'date_fin': fin.toIso8601String().split('T')[0],
          'nombre_jours': jours,
          'motif': motif,
          'statut': 'en_attente',
        }),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur createLeaveRequest: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // MESSAGES CHAT
  // -------------------------------------------------------------
  Future<List<ChatMessage>> fetchChatMessages(String canal, {String? myName}) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/messages_chat?canal_type=eq.$canal&order=created_at.asc'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((j) => ChatMessage(
              id: j['id']?.toString() ?? '',
              senderName: j['expediteur_nom'] ?? 'Membre',
              avatar: j['expediteur_avatar'] ?? 'MB',
              message: j['message'] ?? '',
              canal: j['canal_type'] ?? canal,
              timestamp: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
              isMe: j['expediteur_nom'] == myName,
            )).toList();
      }
    } catch (e) {
      print('Erreur fetchChat: $e');
    }
    return [];
  }

  Future<bool> sendChatMessage({
    required String senderName,
    required String avatar,
    required String message,
    required String canal,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/messages_chat'),
        headers: _headers,
        body: jsonEncode({
          'expediteur_nom': senderName,
          'expediteur_avatar': avatar,
          'canal_type': canal,
          'message': message,
        }),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur sendChatMessage: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // RESSOURCES HSE
  // -------------------------------------------------------------
  Future<List<ResourceDoc>> fetchResources() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/ressources_hse?select=*&order=created_at.desc'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((j) => ResourceDoc(
              id: j['id']?.toString() ?? '',
              titre: j['titre'] ?? 'Document Technique',
              categorie: j['categorie'] ?? 'HSE',
              typeFichier: j['type_fichier'] ?? 'PDF',
              taille: j['taille'] ?? '2.0 MB',
              description: j['description'] ?? '',
              downloadUrl: j['fichier_url'] ?? 'https://jbf-service.cd',
            )).toList();
      }
    } catch (e) {
      print('Erreur fetchResources: $e');
    }
    return [];
  }
}
