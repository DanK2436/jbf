import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MateriauItem {
  final String id;
  final String designation;
  final String unite; // kg, mètre, sac, pièce, litre, tonne
  final double prixUnitaire;
  final String categorie;

  MateriauItem({
    required this.id,
    required this.designation,
    required this.unite,
    required this.prixUnitaire,
    this.categorie = 'Général',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'designation': designation,
        'unite': unite,
        'prix_unitaire': prixUnitaire,
        'categorie': categorie,
      };

  factory MateriauItem.fromJson(Map<String, dynamic> json) => MateriauItem(
        id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        designation: json['designation'] ?? '',
        unite: json['unite'] ?? 'pièce',
        prixUnitaire: (json['prix_unitaire'] as num?)?.toDouble() ?? 0.0,
        categorie: json['categorie'] ?? 'Général',
      );
}

class MateriauxLocalService {
  static const String _storageKey = 'jbf_membre_materiaux_catalog_v1';

  static final List<MateriauItem> _defaultPreseed = [
    MateriauItem(id: 'mat-1', designation: 'Sac de Ciment Gris 42.5R (50kg)', unite: 'sac', prixUnitaire: 14.50, categorie: 'BTP & Maçonnerie'),
    MateriauItem(id: 'mat-2', designation: 'Barre de Fer à Béton Ø12mm (12m)', unite: 'barre', prixUnitaire: 11.20, categorie: 'BTP & Armature'),
    MateriauItem(id: 'mat-3', designation: 'Barre de Fer à Béton Ø10mm (12m)', unite: 'barre', prixUnitaire: 8.50, categorie: 'BTP & Armature'),
    MateriauItem(id: 'mat-4', designation: 'Sable Lavé de Carrière (Benne 15m³)', unite: 'benne', prixUnitaire: 220.00, categorie: 'BTP & Granulats'),
    MateriauItem(id: 'mat-5', designation: 'Gravier Concasseur 15/25 (Benne 15m³)', unite: 'benne', prixUnitaire: 280.00, categorie: 'BTP & Granulats'),
    MateriauItem(id: 'mat-6', designation: 'Paquet Électrodes Basiques E7018 (5kg)', unite: 'paquet', prixUnitaire: 26.00, categorie: 'Soudure & Tuyauterie'),
    MateriauItem(id: 'mat-7', designation: 'Tube Acier Sch40 2 Pouces (6m)', unite: 'barre', prixUnitaire: 48.00, categorie: 'Soudure & Tuyauterie'),
    MateriauItem(id: 'mat-8', designation: 'Bride à Collerette PN16 DN50', unite: 'pièce', prixUnitaire: 32.50, categorie: 'Soudure & Tuyauterie'),
    MateriauItem(id: 'mat-9', designation: 'Câble Électrique Cuivre Armé 4x10mm²', unite: 'mètre', prixUnitaire: 7.80, categorie: 'Électricité Industrielle'),
    MateriauItem(id: 'mat-10', designation: 'Disjoncteur Tétrapolaire 63A Schneider', unite: 'pièce', prixUnitaire: 85.00, categorie: 'Électricité Industrielle'),
    MateriauItem(id: 'mat-11', designation: 'Peinture Antirouille Époxy Primaire (20L)', unite: 'seau', prixUnitaire: 110.00, categorie: 'Finitions'),
    MateriauItem(id: 'mat-12', designation: 'Casque de Sécurité Agréé Minier + Jugulaire', unite: 'pièce', prixUnitaire: 18.00, categorie: 'EPI Sécurité'),
  ];

  Future<List<MateriauItem>> getMateriaux() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr == null || jsonStr.isEmpty) {
        await saveMateriaux(_defaultPreseed);
        return _defaultPreseed;
      }
      final List list = jsonDecode(jsonStr);
      return list.map((e) => MateriauItem.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return _defaultPreseed;
    }
  }

  Future<void> saveMateriaux(List<MateriauItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
  }

  Future<void> addMateriau(MateriauItem item) async {
    final list = await getMateriaux();
    list.add(item);
    await saveMateriaux(list);
  }

  Future<void> deleteMateriau(String id) async {
    final list = await getMateriaux();
    list.removeWhere((item) => item.id == id);
    await saveMateriaux(list);
  }
}
