class ClientUser {
  final String id;
  final String fullName;
  final String companyName;
  final String email;
  final String phone;
  final String sector;
  final String site;
  final String role;
  final String? token;

  ClientUser({
    required this.id,
    required this.fullName,
    required this.companyName,
    required this.email,
    required this.phone,
    this.sector = 'Mines & Industrie',
    this.site = 'Haut-Katanga / Lualaba',
    this.role = 'client',
    this.token,
  });

  factory ClientUser.fromJson(Map<String, dynamic> json) {
    return ClientUser(
      id: json['id']?.toString() ?? 'cli-${DateTime.now().millisecondsSinceEpoch}',
      fullName: json['full_name'] ?? json['nom'] ?? json['contact_name'] ?? 'Partenaire JBF',
      companyName: json['company_name'] ?? json['entreprise'] ?? json['societe'] ?? 'Société Partenaire',
      email: json['email'] ?? '',
      phone: json['phone'] ?? json['telephone'] ?? '+243',
      sector: json['sector'] ?? json['secteur'] ?? 'Mines & Industrie',
      site: json['site'] ?? json['localite'] ?? 'Haut-Katanga / Lualaba',
      role: json['role'] ?? 'client',
      token: json['token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'company_name': companyName,
        'email': email,
        'phone': phone,
        'sector': sector,
        'site': site,
        'role': role,
        'token': token,
      };
}

class ClientDevis {
  final String id;
  final String reference;
  final String service;
  final String site;
  final double montantEstime;
  final String statut; // nouveau, en_etude, valide, refuse
  final String date;
  final String description;

  ClientDevis({
    required this.id,
    required this.reference,
    required this.service,
    required this.site,
    required this.montantEstime,
    required this.statut,
    required this.date,
    required this.description,
  });

  factory ClientDevis.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final shortRef = rawId.length > 5 ? rawId.substring(rawId.length - 5) : rawId;
    return ClientDevis(
      id: rawId,
      reference: json['reference'] ?? 'DEV-$shortRef',
      service: (json['services'] is List && (json['services'] as List).isNotEmpty)
          ? (json['services'] as List).first.toString()
          : (json['service'] ?? json['prestation'] ?? 'Sous-traitance Minière'),
      site: json['site'] ?? json['localite'] ?? 'Kolwezi / Lubumbashi',
      montantEstime: double.tryParse(json['montant']?.toString() ?? json['montant_estime']?.toString() ?? '0') ?? 0.0,
      statut: json['statut'] ?? 'en_etude',
      date: json['date'] ?? json['created_at']?.toString().split('T').first ?? '2026-03-01',
      description: json['message'] ?? json['description'] ?? 'Demande d\'intervention JBF Service',
    );
  }
}

class ClientMission {
  final String id;
  final String reference;
  final String titre;
  final String site;
  final String chef;
  final int avancement;
  final String statut; // en_cours, termine, planifie
  final String dateDebut;
  final String dateFin;

  ClientMission({
    required this.id,
    required this.reference,
    required this.titre,
    required this.site,
    required this.chef,
    required this.avancement,
    required this.statut,
    required this.dateDebut,
    required this.dateFin,
  });

  factory ClientMission.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final shortRef = rawId.length > 5 ? rawId.substring(rawId.length - 5) : rawId;
    return ClientMission(
      id: rawId,
      reference: 'MSN-$shortRef',
      titre: json['titre'] ?? json['service_nom'] ?? json['service'] ?? 'Chantier Minier',
      site: json['site_intervention'] ?? json['site'] ?? 'Lualaba Mining Zone',
      chef: json['chef'] ?? 'Superviseur JBF',
      avancement: int.tryParse(json['avancement']?.toString() ?? '50') ?? 50,
      statut: json['statut'] ?? 'en_cours',
      dateDebut: json['date_debut'] ?? '2026-02-15',
      dateFin: json['date_fin'] ?? '2026-05-30',
    );
  }
}

class ClientFacture {
  final String id;
  final String reference;
  final String libelle;
  final double montantUsd;
  final String date;
  final String echeance;
  final String statut; // payee, en_attente, echeance

  ClientFacture({
    required this.id,
    required this.reference,
    required this.libelle,
    required this.montantUsd,
    required this.date,
    required this.echeance,
    required this.statut,
  });

  factory ClientFacture.fromJson(Map<String, dynamic> json) {
    return ClientFacture(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] ?? 'FACT-2026-001',
      libelle: json['libelle'] ?? 'Prestation Sous-traitance',
      montantUsd: double.tryParse(json['montant_usd']?.toString() ?? '0') ?? 0.0,
      date: json['date'] ?? '2026-03-01',
      echeance: json['echeance'] ?? '2026-03-31',
      statut: json['statut'] ?? 'en_attente',
    );
  }
}

class ClientAvis {
  final String id;
  final String auteur;
  final String entreprise;
  final int note;
  final String commentaire;
  final String date;

  ClientAvis({
    required this.id,
    required this.auteur,
    required this.entreprise,
    required this.note,
    required this.commentaire,
    required this.date,
  });

  factory ClientAvis.fromJson(Map<String, dynamic> json) {
    return ClientAvis(
      id: json['id']?.toString() ?? '',
      auteur: json['auteur'] ?? json['nom'] ?? 'Responsable Achats',
      entreprise: json['entreprise'] ?? json['societe'] ?? 'Compagnie Minière',
      note: int.tryParse(json['note']?.toString() ?? '5') ?? 5,
      commentaire: json['commentaire'] ?? json['avis'] ?? 'Excellente prestation avec respect rigoureux des standards HSE.',
      date: json['date'] ?? json['created_at']?.toString().split('T').first ?? '2026-03-05',
    );
  }
}
