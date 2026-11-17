import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/client_models.dart';

class ClientDataService {
  static final ClientDataService _instance = ClientDataService._internal();
  factory ClientDataService() => _instance;
  ClientDataService._internal();

  // Local caches to guarantee instant display even offline
  List<ClientDevis>? _cachedDevis;
  List<ClientMission>? _cachedMissions;
  List<ClientFacture>? _cachedFactures;
  List<ClientAvis>? _cachedAvis;

  // 1. CHARGEMENT DES DEVIS
  Future<List<ClientDevis>> fetchDevis({String? clientEmail}) async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/demandes_devis?select=*&order=created_at.desc'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final items = list.map((json) => ClientDevis.fromJson(json)).toList();
          _cachedDevis = items;
          return items;
        }
      }
    } catch (_) {}

    // Données réelles : en cas d'absence d'enregistrement, retourne une liste vide (aucune simulation)
    return _cachedDevis ?? [];
  }

  // 2. SOUMISSION NOUVEAU DEVIS
  Future<bool> createDevis({
    required String service,
    required String site,
    required String description,
    required ClientUser client,
    double montantEstime = 0.0,
  }) async {
    final newDevis = ClientDevis(
      id: 'dev-${DateTime.now().millisecondsSinceEpoch}',
      reference: 'DEV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      service: service,
      site: site,
      montantEstime: montantEstime,
      statut: 'nouveau',
      date: DateTime.now().toIso8601String().split('T').first,
      description: description,
    );

    // Tentative Supabase
    try {
      await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/demandes_devis'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'nom': client.fullName,
          'societe': client.companyName,
          'email': client.email,
          'telephone': client.phone,
          'services': [service],
          'localite': site,
          'message': description,
          'statut': 'nouveau',
        }),
      ).timeout(const Duration(seconds: 6));
    } catch (_) {}

    _cachedDevis ??= [];
    _cachedDevis!.insert(0, newDevis);
    return true;
  }

  // 2b. MODIFICATION D'UN DEVIS
  Future<bool> updateDevis({
    required String id,
    required String service,
    required String site,
    required String description,
    double montantEstime = 0.0,
  }) async {
    try {
      await http.patch(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/demandes_devis?id=eq.$id'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'services': [service],
          'localite': site,
          'message': description,
          'montant': montantEstime,
        }),
      ).timeout(const Duration(seconds: 6));
    } catch (_) {}

    if (_cachedDevis != null) {
      final idx = _cachedDevis!.indexWhere((d) => d.id == id);
      if (idx != -1) {
        final old = _cachedDevis![idx];
        _cachedDevis![idx] = ClientDevis(
          id: old.id,
          reference: old.reference,
          service: service,
          site: site,
          montantEstime: montantEstime > 0 ? montantEstime : old.montantEstime,
          statut: old.statut,
          date: old.date,
          description: description,
        );
      }
    }
    return true;
  }

  // 2c. SUPPRESSION D'UN DEVIS
  Future<bool> deleteDevis(String id) async {
    try {
      await http.delete(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/demandes_devis?id=eq.$id'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 6));
    } catch (_) {}

    if (_cachedDevis != null) {
      _cachedDevis!.removeWhere((d) => d.id == id);
    }
    return true;
  }

  // 3. CHARGEMENT DES MISSIONS / CHANTIERS
  Future<List<ClientMission>> fetchMissions() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/missions?select=*&order=created_at.desc'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final items = list.map((json) => ClientMission.fromJson(json)).toList();
          _cachedMissions = items;
          return items;
        }
      }
    } catch (_) {}

    return _cachedMissions ?? [];
  }

  // 4. CHARGEMENT DES FACTURES & PROFORMAS
  Future<List<ClientFacture>> fetchFactures() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/factures?select=*&order=created_at.desc'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final items = list.map((json) => ClientFacture.fromJson(json)).toList();
          _cachedFactures = items;
          return items;
        }
      }
    } catch (_) {}

    return _cachedFactures ?? [];
  }

  // 5. CHARGEMENT DES AVIS CLIENTS
  Future<List<ClientAvis>> fetchAvis() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/avis_clients?select=*&order=created_at.desc'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        if (list.isNotEmpty) {
          final items = list.map((json) => ClientAvis.fromJson(json)).toList();
          _cachedAvis = items;
          return items;
        }
      }
    } catch (_) {}

    return _cachedAvis ?? [];
  }

  // 6. ENREGISTRER UN AVIS
  Future<bool> submitAvis({
    required String auteur,
    required String entreprise,
    required int note,
    required String commentaire,
  }) async {
    final newAvis = ClientAvis(
      id: 'av-${DateTime.now().millisecondsSinceEpoch}',
      auteur: auteur,
      entreprise: entreprise,
      note: note,
      commentaire: commentaire,
      date: DateTime.now().toIso8601String().split('T').first,
    );

    try {
      await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/avis_clients'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'nom': auteur,
          'prenom': auteur.split(' ').first,
          'entreprise': entreprise,
          'note': note,
          'stars': note,
          'service': 'Prestation JBF Client',
          'commentaire': commentaire,
          'approuve': false,
          'created_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 6));
    } catch (_) {}

    _cachedAvis ??= [];
    _cachedAvis!.insert(0, newAvis);
    return true;
  }
}
