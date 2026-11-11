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
  String? lastError;

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
        final items = list.map((json) => ClientDevis.fromJson(json)).toList();
        _cachedDevis = items;
        lastError = null;
        return items;
      }
      lastError = 'Lecture des devis refusée (${res.statusCode}).';
    } catch (_) {
      lastError = 'Service des devis injoignable.';
    }
    return [];
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
      final res = await http.post(
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
      if (res.statusCode < 200 || res.statusCode >= 300) {
        lastError = 'Enregistrement du devis refusé (${res.statusCode}).';
        return false;
      }
    } catch (_) {
      lastError = 'Service des devis injoignable. La demande n\'est pas enregistrée.';
      return false;
    }

    lastError = null;
    _cachedDevis ??= [];
    _cachedDevis!.insert(0, newDevis);
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
        final items = list.map((json) => ClientMission.fromJson(json)).toList();
        _cachedMissions = items;
        lastError = null;
        return items;
      }
      lastError = 'Lecture des missions refusée (${res.statusCode}).';
    } catch (_) {
      lastError = 'Service des missions injoignable.';
    }
    return [];
  }

  Future<List<ClientFacture>> fetchFactures() async {
    lastError = 'Aucune table de factures n\'est branchée. Aucun montant n\'est affiché.';
    return [];
  }

  // 5. CHARGEMENT DES AVIS CLIENTS
  Future<List<ClientAvis>> fetchAvis() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/avis?select=*&order=created_at.desc'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final items = list.map((json) => ClientAvis.fromJson(json)).toList();
        _cachedAvis = items;
        lastError = null;
        return items;
      }
      lastError = 'Lecture des avis refusée (${res.statusCode}).';
    } catch (_) {
      lastError = 'Service des avis injoignable.';
    }
    return [];
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
      final res = await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/avis'),
        headers: {
          'apikey': AppConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode({
          'auteur': auteur,
          'entreprise': entreprise,
          'note': note,
          'commentaire': commentaire,
          'statut': 'publie',
        }),
      ).timeout(const Duration(seconds: 6));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        lastError = 'Enregistrement de l\'avis refusé (${res.statusCode}).';
        return false;
      }
    } catch (_) {
      lastError = 'Service des avis injoignable. L\'avis n\'est pas enregistré.';
      return false;
    }

    lastError = null;
    _cachedAvis ??= [];
    _cachedAvis!.insert(0, newAvis);
    return true;
  }
}
