# 🎨 SPEC 01 : DESIGN SYSTEM & CHARTE GRAPHIQUE v8.0
**Ratio de Marque**: **90% Rose Vif** (`#E6007E`) / **10% Blanc** (`#FFFFFF`)

---

## 1. PALETTE ET RÉPARTITION DES COULEURS

| Nom Token | Code Hex | Ratio | Rôle & Domaines d'application |
|---|---|---|---|
| `--rose` / `--primary` | `#E6007E` | **90%** Rose Vif Dominant | **Couleur dominante de tout l'écosystème** (Heros, boutons d'action majeurs, barres de navigation, cartes actives, badges d'état, highlights, bordures, étoiles d'avis) |
| `--primary-light` | `#FF2E99` | Nuance Rose Éclatant | État survol (hover) des boutons et liens interactifs, accents lumineux |
| `--primary-mid` | `#C8006E` | Nuance Rose Structurant | En-têtes, dégradés d'accentuation, bordures actives |
| `--primary-deep` | `#8B004A` | Nuance Rose Sombre | Pied de page (Footer), contrastes d'icônes |
| `--white` | `#FFFFFF` | **10%** Blanc Pur | **Respiration & Éléments épurés** (Fond de cartes, conteneurs de contenu, lisibilité parfaite du texte) |
| `--primary-tint` | `#FFF0F7` | Teinte Rose Pâle | Arrière-plan des sections claires et surfaces de cartes |

---

## 2. DIRECTIVES UI ET LOGO
1. **Suppression des quadrillages** : Aucun motif de grille n'est présent sur aucune plateforme.
2. **Logo officiel** : Affiché dans son apparence naturelle sans filtre destructeur.
3. **Application Multiplateforme** :
   - Web (`JBF Public`, `JBF Membre`, `JBF Admin`) : Déclaré dans `css/main.css` (`:root`).
   - Flutter (Desktop & Mobile) : Déclaré dans `ThemeData` (Dart `ColorScheme.light(primary: Color(0xFFE6007E), secondary: Color(0xFFC8006E))`).
