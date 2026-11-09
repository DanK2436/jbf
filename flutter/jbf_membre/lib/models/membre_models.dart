class MembreUser {
  final String id;
  final String fullName;
  final String email;
  final String matricule;
  final String poste;
  final String sectionNom;
  final String province;
  int soldeConges;
  final String avatar;
  final String token;

  MembreUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.matricule,
    required this.poste,
    required this.sectionNom,
    this.province = 'Haut-Katanga (Lubumbashi)',
    this.soldeConges = 18,
    required this.avatar,
    required this.token,
  });

  factory MembreUser.fromJson(Map<String, dynamic> json) {
    return MembreUser(
      id: json['id']?.toString() ?? 'mbr-1',
      fullName: json['name'] ?? json['full_name'] ?? 'Jean-Pierre Mulamba',
      email: json['email'] ?? 'jp.mulamba@jbf-services.cd',
      matricule: json['matricule'] ?? 'JBF-M-2026-012',
      poste: json['poste'] ?? 'Chef d\'Équipe Soudure & Tuyauterie',
      sectionNom: json['section_nom'] ?? 'Maintenance & Soudure',
      province: json['province'] ?? 'Lualaba (Kolwezi)',
      soldeConges: int.tryParse(json['solde_conges']?.toString() ?? '18') ?? 18,
      avatar: json['avatar'] ?? 'JM',
      token: json['token'] ?? 'token-membre',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': fullName,
        'email': email,
        'matricule': matricule,
        'poste': poste,
        'section_nom': sectionNom,
        'province': province,
        'solde_conges': soldeConges,
        'avatar': avatar,
        'token': token,
      };
}

class MembreMission {
  final String id;
  final String titre;
  final String client;
  final String siteIntervention;
  final String serviceNom;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final String description;
  String statut; // planifiee, en_cours, terminee
  final String chefEquipe;
  final int effectif;
  String rapport;

  MembreMission({
    required this.id,
    required this.titre,
    required this.client,
    required this.siteIntervention,
    required this.serviceNom,
    required this.dateDebut,
    this.dateFin,
    this.description = '',
    this.statut = 'en_cours',
    this.chefEquipe = '',
    this.effectif = 1,
    this.rapport = '',
  });
}

class PointageRecord {
  final String id;
  final DateTime dateHeure;
  final String typePointage; // entree, sortie
  final String siteLieu;
  final double latitude;
  final double longitude;
  final String ipAddress;
  final bool isVpn;
  final String statutValidation; // valide, en_attente, rejete
  final double heuresNormales;
  final double heuresSup;

  PointageRecord({
    required this.id,
    required this.dateHeure,
    required this.typePointage,
    required this.siteLieu,
    this.latitude = -10.7183,
    this.longitude = 25.4729,
    this.ipAddress = '105.101.44.12',
    this.isVpn = false,
    this.statutValidation = 'valide',
    this.heuresNormales = 8.0,
    this.heuresSup = 0.0,
  });
}

class LeaveRequest {
  final String id;
  final String typeConge;
  final DateTime dateDebut;
  final DateTime dateFin;
  final int nombreJours;
  final String motif;
  String statut; // en_attente, approuve, refuse
  String commentaireAdmin;

  LeaveRequest({
    required this.id,
    required this.typeConge,
    required this.dateDebut,
    required this.dateFin,
    required this.nombreJours,
    required this.motif,
    this.statut = 'en_attente',
    this.commentaireAdmin = '',
  });
}

class ChatMessage {
  final String id;
  final String senderName;
  final String avatar;
  final String message;
  final String canal; // general, hse-securite, missions
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.avatar,
    required this.message,
    required this.canal,
    required this.timestamp,
    this.isMe = false,
  });
}

class ResourceDoc {
  final String id;
  final String titre;
  final String categorie;
  final String typeFichier;
  final String taille;
  final String description;
  final String downloadUrl;

  ResourceDoc({
    required this.id,
    required this.titre,
    required this.categorie,
    required this.typeFichier,
    required this.taille,
    required this.description,
    required this.downloadUrl,
  });
}
