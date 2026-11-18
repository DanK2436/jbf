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
      final codeMission = 'MSN-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final Map<String, dynamic> body = {
        'titre': m.titre,
        'code_mission': codeMission,
        'client': m.client,
        'client_nom': m.client,
        'societe': m.client,
        'site_intervention': m.siteIntervention,
        'site_lieu': m.siteIntervention,
        'prestation': m.serviceNom,
        'service': m.serviceNom,
        'description': m.description,
        'statut': m.statut.isNotEmpty ? m.statut : 'en_cours',
        'responsable_jbf': m.assignedTo,
        'agents_assignes': [m.assignedTo],
        'progression_pct': 0,
        'observations': 'Budget: ${m.budgetUsd.toStringAsFixed(0)} USD • Effectif: ${m.effectif} agent(s)',
        'budget_alloue': m.budgetUsd,
        'devise': 'USD',
        'created_at': DateTime.now().toIso8601String(),
      };

      body['date_debut'] = m.dateDebut.toIso8601String();
      if (m.dateFin != null) {
        body['date_fin'] = m.dateFin!.toIso8601String();
      }
      if (m.assignedToId != null && m.assignedToId!.length > 30) {
        body['valide_par_membre_id'] = m.assignedToId;
      }

      var res = await http.post(
        Uri.parse('$_baseUrl/missions'),
        headers: {
          ..._headers,
          'Prefer': 'return=representation',
        },
        body: jsonEncode(body),
      );

      // Si rejeté, repli robuste avec colonnes minimales garanties
      if (res.statusCode < 200 || res.statusCode >= 300) {
        final minimalBody = {
          'titre': m.titre,
          'code_mission': codeMission,
          'client': m.client,
          'client_nom': m.client,
          'site_intervention': m.siteIntervention,
          'service': m.serviceNom,
          'statut': m.statut.isNotEmpty ? m.statut : 'en_cours',
          'responsable_jbf': m.assignedTo,
          'progression_pct': 0,
          'description': m.description,
          'created_at': DateTime.now().toIso8601String(),
        };
        res = await http.post(
          Uri.parse('$_baseUrl/missions'),
          headers: _headers,
          body: jsonEncode(minimalBody),
        );
      }

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

  Future<bool> createMembre(MembreItem m, {String? password}) async {
    final cleanPass = (password ?? m.password ?? 'JBF2026!').trim();
    final cleanEmail = m.email.trim().toLowerCase();
    final cleanNom = m.nom.trim();

    // 1. Supabase Auth signup silencieux
    try {
      await http.post(
        Uri.parse('$AppConfig.supabaseUrl/auth/v1/signup'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': cleanEmail,
          'password': cleanPass,
          'data': {'full_name': cleanNom, 'role': 'membre'}
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    // 2. Profil dans table profiles
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/profiles'),
        headers: {
          ..._headers,
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode({
          'email': cleanEmail,
          'full_name': cleanNom,
          'nom_complet': cleanNom,
          'nom': cleanNom.split(' ').first,
          'phone': m.phone.trim(),
          'telephone': m.phone.trim(),
          'matricule': m.matricule.trim(),
          'poste': m.poste.trim(),
          'fonction': m.poste.trim(),
          'section_nom': m.sectionNom.trim(),
          'province': m.province.trim(),
          'solde_conges': m.soldeConges,
          'role': 'membre',
          'company': 'JBF Service SARL',
          'entreprise': 'JBF Service SARL',
          'statut': 'actif',
          'statut_compte': 'actif',
          'is_disabled': false,
          'password': cleanPass,
          'permissions_detaillees': {
            'password': cleanPass,
            'role_service': m.poste.trim(),
            'service_assigne': m.sectionNom.trim(),
            'all': false,
          },
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );

      // 3. Fiche dans rh_collaborateurs
      try {
        await http.post(
          Uri.parse('$_baseUrl/rh_collaborateurs'),
          headers: {
            ..._headers,
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode({
            'matricule': m.matricule.trim(),
            'type_contrat': 'CDI',
            'poste': m.poste.trim(),
            'service': m.sectionNom.trim(),
            'statut': 'actif',
            'created_at': DateTime.now().toIso8601String(),
          }),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}

      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur createMembre: $e');
      return false;
    }
  }

  Future<bool> updateMembre(MembreItem m, {String? password}) async {
    final cleanPass = (password ?? m.password)?.trim();
    try {
      final body = <String, dynamic>{
        'email': m.email.trim().toLowerCase(),
        'full_name': m.nom.trim(),
        'nom_complet': m.nom.trim(),
        'nom': m.nom.trim().split(' ').first,
        'phone': m.phone.trim(),
        'telephone': m.phone.trim(),
        'matricule': m.matricule.trim(),
        'poste': m.poste.trim(),
        'fonction': m.poste.trim(),
        'section_nom': m.sectionNom.trim(),
        'province': m.province.trim(),
        'solde_conges': m.soldeConges,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (cleanPass != null && cleanPass.isNotEmpty) {
        body['password'] = cleanPass;
        body['permissions_detaillees'] = {
          'password': cleanPass,
          'role_service': m.poste.trim(),
          'service_assigne': m.sectionNom.trim(),
          'all': false,
        };
      }

      final targetUrl = m.id.isNotEmpty
          ? '$_baseUrl/profiles?id=eq.${m.id}'
          : '$_baseUrl/profiles?email=eq.${m.email.trim().toLowerCase()}';

      final res = await http.patch(
        Uri.parse(targetUrl),
        headers: _headers,
        body: jsonEncode(body),
      );

      // Mettre à jour dans rh_collaborateurs
      if (m.matricule.isNotEmpty) {
        try {
          await http.patch(
            Uri.parse('$_baseUrl/rh_collaborateurs?matricule=eq.${m.matricule.trim()}'),
            headers: _headers,
            body: jsonEncode({
              'poste': m.poste.trim(),
              'service': m.sectionNom.trim(),
            }),
          );
        } catch (_) {}
      }

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

  Future<bool> createSousAdmin(SousAdminItem sa, {String? password}) async {
    final cleanPass = (password ?? sa.password ?? 'Services+243JBF').trim();
    final cleanEmail = sa.email.trim().toLowerCase();
    final cleanNom = sa.fullName.trim();

    // 1. Supabase Auth signup silencieux
    try {
      await http.post(
        Uri.parse('$AppConfig.supabaseUrl/auth/v1/signup'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': cleanEmail,
          'password': cleanPass,
          'data': {'full_name': cleanNom, 'role': 'sous_admin'}
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/admin_accounts'),
        headers: {
          ..._headers,
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode({
          'full_name': cleanNom,
          'email': cleanEmail,
          'role': 'sous_admin',
          'permissions': sa.permissions,
          'password': cleanPass,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );

      // Enregistrer également dans la table profiles
      try {
        await http.post(
          Uri.parse('$_baseUrl/profiles'),
          headers: {
            ..._headers,
            'Prefer': 'resolution=merge-duplicates',
          },
          body: jsonEncode({
            'full_name': cleanNom,
            'nom_complet': cleanNom,
            'nom': cleanNom.split(' ').first,
            'email': cleanEmail,
            'role': 'sous_admin',
            'poste': 'Sous-Administrateur Gestionnaire',
            'fonction': 'Sous-Administrateur',
            'company': 'Direction JBF Services',
            'entreprise': 'Direction JBF Services',
            'statut_compte': 'actif',
            'statut': 'actif',
            'is_disabled': false,
            'password': cleanPass,
            'permissions_detaillees': {
              'permissions': sa.permissions,
              'password': cleanPass,
              'all': false,
            },
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }),
        );
      } catch (_) {}

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

  Future<bool> updateSousAdmin(SousAdminItem sa, {String? password}) async {
    final cleanPass = (password ?? sa.password)?.trim();
    final cleanEmail = sa.email.trim().toLowerCase();
    try {
      final adminAccountBody = <String, dynamic>{
        'full_name': sa.fullName.trim(),
        'email': cleanEmail,
        'permissions': sa.permissions,
        'is_active': sa.isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (cleanPass != null && cleanPass.isNotEmpty) {
        adminAccountBody['password'] = cleanPass;
      }

      final targetUrl = sa.id.isNotEmpty
          ? '$_baseUrl/admin_accounts?id=eq.${sa.id}'
          : '$_baseUrl/admin_accounts?email=eq.$cleanEmail';

      final res = await http.patch(
        Uri.parse(targetUrl),
        headers: _headers,
        body: jsonEncode(adminAccountBody),
      );

      // Également dans profiles
      try {
        final profileBody = <String, dynamic>{
          'full_name': sa.fullName.trim(),
          'nom_complet': sa.fullName.trim(),
          'nom': sa.fullName.trim().split(' ').first,
          'email': cleanEmail,
          'is_disabled': !sa.isActive,
          'statut_compte': sa.isActive ? 'actif' : 'desactive',
          'statut': sa.isActive ? 'actif' : 'desactive',
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (cleanPass != null && cleanPass.isNotEmpty) {
          profileBody['password'] = cleanPass;
          profileBody['permissions_detaillees'] = {
            'password': cleanPass,
            'permissions': sa.permissions,
            'all': false,
          };
        }
        await http.patch(
          Uri.parse('$_baseUrl/profiles?email=eq.$cleanEmail'),
          headers: _headers,
          body: jsonEncode(profileBody),
        );
      } catch (_) {}

      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('Erreur updateSousAdmin: $e');
      return false;
    }
  }
}
