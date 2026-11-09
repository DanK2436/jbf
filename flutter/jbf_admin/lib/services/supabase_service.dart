import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/admin_models.dart';

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
  // DEMANDES DE DEVIS
  // -------------------------------------------------------------
  Future<List<DevisItem>> fetchDevis() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/demandes_devis?select=*&order=created_at.desc'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((json) => DevisItem.fromJson(json)).toList();
      }
    } catch (e) {
      print('Erreur fetchDevis: $e');
    }
    return [];
  }

  Future<bool> updateDevisStatut(String id, String statut, {double? montant, String? chef, int? effectif}) async {
    try {
      final Map<String, dynamic> body = {'statut': statut};
      if (montant != null) body['montant_usd'] = montant;
      if (chef != null) body['chef_equipe'] = chef;
      if (effectif != null) body['effectif'] = effectif;

      final res = await http.patch(
        Uri.parse('$_baseUrl/demandes_devis?id=eq.$id'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur updateDevis: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // MISSIONS
  // -------------------------------------------------------------
  Future<List<MissionItem>> fetchMissions() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/missions?select=*&order=created_at.desc'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((json) => MissionItem.fromJson(json)).toList();
      }
    } catch (e) {
      print('Erreur fetchMissions: $e');
    }
    return [];
  }

  Future<bool> createMission(MissionItem m) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/missions'),
        headers: _headers,
        body: jsonEncode({
          'titre': m.titre,
          'client': m.client,
          'site_intervention': m.siteIntervention,
          'service_nom': m.serviceNom,
          'date_debut': m.dateDebut.toIso8601String(),
          'date_fin': m.dateFin?.toIso8601String(),
          'description': m.description,
          'statut': m.statut,
          'budget_usd': m.budgetUsd,
          'effectif': m.effectif,
          'rapport': m.rapport,
        }),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur createMission: $e');
      return false;
    }
  }

  Future<bool> updateMissionStatut(String id, String statut) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/missions?id=eq.$id'),
        headers: _headers,
        body: jsonEncode({'statut': statut}),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur updateMissionStatut: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // POINTAGES & CONTRÔLE ANTI-VPN
  // -------------------------------------------------------------
  Future<List<PointageLog>> fetchPointages() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/pointages?select=*&order=date_heure.desc'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((j) => PointageLog(
              id: j['id']?.toString() ?? '',
              agentNom: j['agent_nom'] ?? 'Agent',
              matricule: j['matricule'] ?? 'JBF-M',
              siteLieu: j['site_lieu'] ?? 'RDC',
              typePointage: j['type_pointage'] ?? 'entree',
              dateHeure: DateTime.tryParse(j['date_heure'] ?? '') ?? DateTime.now(),
              latitude: (j['latitude'] as num?)?.toDouble() ?? -11.66,
              longitude: (j['longitude'] as num?)?.toDouble() ?? 27.47,
              isVpn: j['is_vpn'] == true,
              ipAddress: j['ip_address'] ?? '127.0.0.1',
              statutValidation: j['statut_validation'] ?? 'valide',
            )).toList();
      }
    } catch (e) {
      print('Erreur fetchPointages: $e');
    }
    return [];
  }

  Future<bool> updatePointageStatut(String id, String statut) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/pointages?id=eq.$id'),
        headers: _headers,
        body: jsonEncode({'statut_validation': statut}),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur updatePointage: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // DEMANDES DE CONGÉS
  // -------------------------------------------------------------
  Future<List<CongeItem>> fetchConges() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/demandes_conges?select=*&order=created_at.desc'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((j) => CongeItem(
              id: j['id']?.toString() ?? '',
              agentNom: j['agent_nom'] ?? 'Collaborateur',
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
      print('Erreur fetchConges: $e');
    }
    return [];
  }

  Future<bool> decideConge(String id, String statut, String commentaire) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/demandes_conges?id=eq.$id'),
        headers: _headers,
        body: jsonEncode({
          'statut': statut,
          'commentaire_admin': commentaire,
        }),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur decideConge: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // AVIS CLIENTS
  // -------------------------------------------------------------
  Future<List<AvisItem>> fetchAvis() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/avis_clients?select=*&order=created_at.desc'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((j) => AvisItem(
              id: j['id']?.toString() ?? '',
              nom: j['nom'] ?? 'Client',
              entreprise: j['entreprise'] ?? '',
              service: j['service'] ?? 'Prestation',
              note: int.tryParse(j['note']?.toString() ?? '5') ?? 5,
              commentaire: j['commentaire'] ?? '',
              approuve: j['approuve'] == true,
              createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
            )).toList();
      }
    } catch (e) {
      print('Erreur fetchAvis: $e');
    }
    return [];
  }

  Future<bool> toggleAvisApprouve(String id, bool approuve) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/avis_clients?id=eq.$id'),
        headers: _headers,
        body: jsonEncode({'approuve': approuve}),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur toggleAvis: $e');
      return false;
    }
  }

  Future<bool> deleteAvis(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/avis_clients?id=eq.$id'),
        headers: _headers,
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur deleteAvis: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // MEMBRES (PROFILES SUPABASE)
  // -------------------------------------------------------------
  Future<List<MembreItem>> fetchMembres() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/profiles?select=*&order=created_at.desc'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((j) => MembreItem(
              id: j['id']?.toString() ?? '',
              nom: j['full_name'] ?? j['email']?.toString().split('@')[0] ?? 'Collaborateur',
              email: j['email'] ?? '',
              phone: j['phone'] ?? '',
              matricule: j['matricule'] ?? 'JBF-M-${j['id']?.toString().substring(0, 4) ?? ""}',
              poste: j['poste'] ?? 'Collaborateur',
              sectionNom: j['section_nom'] ?? 'Services Divers',
              province: j['province'] ?? 'Haut-Katanga',
              soldeConges: int.tryParse(j['solde_conges']?.toString() ?? '18') ?? 18,
              role: j['role'] ?? 'membre',
              isActive: true,
            )).toList();
      }
    } catch (e) {
      print('Erreur fetchMembres: $e');
    }
    return [];
  }

  Future<bool> createMembre(MembreItem m) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/profiles'),
        headers: _headers,
        body: jsonEncode({
          'email': m.email,
          'full_name': m.nom,
          'phone': m.phone,
          'matricule': m.matricule,
          'poste': m.poste,
          'section_nom': m.sectionNom,
          'province': m.province,
          'solde_conges': m.soldeConges,
          'role': 'membre',
        }),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur createMembre: $e');
      return false;
    }
  }

  Future<bool> updateMembre(MembreItem m) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/profiles?id=eq.${m.id}'),
        headers: _headers,
        body: jsonEncode({
          'email': m.email,
          'full_name': m.nom,
          'phone': m.phone,
          'matricule': m.matricule,
          'poste': m.poste,
          'section_nom': m.sectionNom,
          'province': m.province,
          'solde_conges': m.soldeConges,
        }),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur updateMembre: $e');
      return false;
    }
  }

  // -------------------------------------------------------------
  // SOUS-ADMINS (TABLE ADMIN_ACCOUNTS)
  // -------------------------------------------------------------
  Future<List<SousAdminItem>> fetchSousAdmins() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/admin_accounts?select=*&order=created_at.desc'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((j) {
          List<String> perms = ['*'];
          if (j['permissions'] is List) {
            perms = (j['permissions'] as List).map((e) => e.toString()).toList();
          }
          return SousAdminItem(
            id: j['id']?.toString() ?? '',
            fullName: j['full_name'] ?? 'Administrateur',
            email: j['email'] ?? '',
            permissions: perms,
            isActive: j['is_active'] == true,
          );
        }).toList();
      }
    } catch (e) {
      print('Erreur fetchSousAdmins: $e');
    }
    return [];
  }

  Future<bool> createSousAdmin(SousAdminItem sa) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/admin_accounts'),
        headers: _headers,
        body: jsonEncode({
          'full_name': sa.fullName,
          'email': sa.email,
          'role': 'sous_admin',
          'permissions': sa.permissions,
          'is_active': true,
        }),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur createSousAdmin: $e');
      return false;
    }
  }

  Future<bool> toggleSousAdmin(String id, bool active) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/admin_accounts?id=eq.$id'),
        headers: _headers,
        body: jsonEncode({'is_active': active}),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur toggleSousAdmin: $e');
      return false;
    }
  }
}
