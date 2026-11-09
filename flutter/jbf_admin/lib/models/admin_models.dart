class AdminUser {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String site;
  final String avatar;
  final List<String> permissions;
  final String token;

  AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.site = 'Lubumbashi (Siège)',
    this.avatar = 'DG',
    this.permissions = const ['*'],
    required this.token,
  });

  bool hasPermission(String module) {
    if (permissions.contains('*')) return true;
    return permissions.contains(module);
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? 'admin-1',
      fullName: json['name'] ?? json['full_name'] ?? 'Direction Générale JBF',
      email: json['email'] ?? 'services@admin.jbf',
      role: json['role'] ?? 'Super Administrateur',
      site: json['site'] ?? 'Lubumbashi (Siège)',
      avatar: json['avatar'] ?? 'DG',
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['*'],
      token: json['token'] ?? 'token-admin',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': fullName,
        'email': email,
        'role': role,
        'site': site,
        'avatar': avatar,
        'permissions': permissions,
        'token': token,
      };
}

class DevisItem {
  final String id;
  final String nom;
  final String societe;
  final String telephone;
  final String email;
  final List<String> services;
  final String localite;
  final String message;
  String statut; // nouveau, en_cours, traite, rejete
  double montantUsd;
  String chefEquipe;
  int effectif;
  final DateTime createdAt;

  DevisItem({
    required this.id,
    required this.nom,
    required this.societe,
    required this.telephone,
    required this.email,
    required this.services,
    required this.localite,
    required this.message,
    this.statut = 'nouveau',
    this.montantUsd = 0.0,
    this.chefEquipe = '',
    this.effectif = 0,
    required this.createdAt,
  });

  factory DevisItem.fromJson(Map<String, dynamic> json) {
    List<String> serv = [];
    if (json['services'] is List) {
      serv = (json['services'] as List).map((e) => e.toString()).toList();
    } else if (json['services'] != null) {
      serv = [json['services'].toString()];
    }

    return DevisItem(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      nom: json['nom'] ?? 'Client Inconnu',
      societe: json['societe'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'] ?? '',
      services: serv,
      localite: json['localite'] ?? 'Lubumbashi',
      message: json['message'] ?? '',
      statut: json['statut'] ?? 'nouveau',
      montantUsd: (json['montant_usd'] != null)
          ? double.tryParse(json['montant_usd'].toString()) ?? 0.0
          : 0.0,
      chefEquipe: json['chef_equipe'] ?? '',
      effectif: int.tryParse(json['effectif']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class MissionItem {
  final String id;
  String titre;
  String client;
  String siteIntervention;
  String serviceNom;
  DateTime dateDebut;
  DateTime? dateFin;
  String description;
  String assignedTo;
  String statut; // planifiee, en_cours, terminee, suspendue
  double budgetUsd;
  int effectif;
  String rapport;

  MissionItem({
    required this.id,
    required this.titre,
    required this.client,
    required this.siteIntervention,
    required this.serviceNom,
    required this.dateDebut,
    this.dateFin,
    this.description = '',
    this.assignedTo = '',
    this.statut = 'en_cours',
    this.budgetUsd = 0.0,
    this.effectif = 1,
    this.rapport = '',
  });

  factory MissionItem.fromJson(Map<String, dynamic> json) {
    return MissionItem(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      titre: json['titre'] ?? 'Mission Terrain',
      client: json['client'] ?? 'Partenaire JBF',
      siteIntervention: json['site_intervention'] ?? 'Haut-Katanga',
      serviceNom: json['service_nom'] ?? 'Sous-traitance Minière',
      dateDebut: json['date_debut'] != null
          ? DateTime.tryParse(json['date_debut'].toString()) ?? DateTime.now()
          : DateTime.now(),
      dateFin: json['date_fin'] != null
          ? DateTime.tryParse(json['date_fin'].toString())
          : null,
      description: json['description'] ?? '',
      assignedTo: json['assigned_to'] ?? '',
      statut: json['statut'] ?? 'en_cours',
      budgetUsd: (json['budget_usd'] != null)
          ? double.tryParse(json['budget_usd'].toString()) ?? 0.0
          : 0.0,
      effectif: int.tryParse(json['effectif']?.toString() ?? '1') ?? 1,
      rapport: json['rapport'] ?? '',
    );
  }
}

class PointageLog {
  final String id;
  final String agentNom;
  final String matricule;
  final String siteLieu;
  final String typePointage; // entree, sortie
  final DateTime dateHeure;
  final double latitude;
  final double longitude;
  final bool isVpn;
  final String ipAddress;
  String statutValidation; // valide, en_attente, rejete

  PointageLog({
    required this.id,
    required this.agentNom,
    required this.matricule,
    required this.siteLieu,
    required this.typePointage,
    required this.dateHeure,
    this.latitude = -11.66089,
    this.longitude = 27.47938,
    this.isVpn = false,
    this.ipAddress = '105.101.44.12',
    this.statutValidation = 'valide',
  });
}

class CongeItem {
  final String id;
  final String agentNom;
  final String typeConge;
  final DateTime dateDebut;
  final DateTime dateFin;
  final int nombreJours;
  final String motif;
  String statut; // en_attente, approuve, refuse
  String commentaireAdmin;

  CongeItem({
    required this.id,
    required this.agentNom,
    required this.typeConge,
    required this.dateDebut,
    required this.dateFin,
    required this.nombreJours,
    required this.motif,
    this.statut = 'en_attente',
    this.commentaireAdmin = '',
  });
}

class AvisItem {
  final String id;
  final String nom;
  final String entreprise;
  final String service;
  final int note;
  final String commentaire;
  bool approuve;
  final DateTime createdAt;

  AvisItem({
    required this.id,
    required this.nom,
    required this.entreprise,
    required this.service,
    required this.note,
    required this.commentaire,
    this.approuve = true,
    required this.createdAt,
  });
}

class MembreItem {
  final String id;
  String nom;
  String email;
  String phone;
  String matricule;
  String poste;
  String sectionNom;
  String province;
  int soldeConges;
  String role;
  bool isActive;

  MembreItem({
    required this.id,
    required this.nom,
    required this.email,
    required this.phone,
    required this.matricule,
    required this.poste,
    required this.sectionNom,
    this.province = 'Haut-Katanga',
    this.soldeConges = 18,
    this.role = 'membre',
    this.isActive = true,
  });
}

class SousAdminItem {
  final String id;
  String fullName;
  String email;
  List<String> permissions;
  bool isActive;

  SousAdminItem({
    required this.id,
    required this.fullName,
    required this.email,
    required this.permissions,
    this.isActive = true,
  });
}

class KpiStats {
  final int totalDevis;
  final int devisNouveaux;
  final int missionsActives;
  final int effectifDeploye;
  final double caEstimeUsd;
  final int alertesVpn;

  KpiStats({
    required this.totalDevis,
    required this.devisNouveaux,
    required this.missionsActives,
    required this.effectifDeploye,
    required this.caEstimeUsd,
    required this.alertesVpn,
  });
}

// Dummy unique key helper if needed
class UniqueKey {
  @override
  String toString() => 'k_${DateTime.now().microsecondsSinceEpoch}';
}
