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

  Future<List<MateriauItem>> getMateriaux() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr == null || jsonStr.isEmpty) {
        return [];
      }
      final List list = jsonDecode(jsonStr);
      return list.map((e) => MateriauItem.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
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
