# 🖥️ SPEC 05 : SPÉCIFICATION LOGICIELS DESKTOP FLUTTER
**Emplacement**: `C:\Users\is mlckl\Desktop\Logiciels\JBF Desktop`  
**Technologie**: Flutter Desktop (Dart) pour Windows, macOS, Linux

---

## 1. COMPOSANTS DESKTOP

### A. `JBF Admin Desktop` (Logiciel Administration & Supervision)
- **Fonctionnalités Clés** :
  - **Tableau de bord exécutif** : Métriques en temps réel sur les 15 prestations à travers la RDC.
  - **Gestion des demandes de devis** : Validation, tarification et émission des offres commerciales.
  - **Gestion des contrats & facturation** : Suivi des contrats miniers, catering et BTP.
  - **Supervision HSE & Certifications** : Suivi du respect des normes de sécurité sur les chantiers.
  - **Modération des avis clients** : Approbation et publication des avis soumis sur la plateforme.
- **Interface UI** : Thème 90% Rose Vif (`#E6007E`) / 10% Blanc (`#FFFFFF`), navigation latérale *Fluent Sidebar*.

### B. `JBF Membre Desktop` (Logiciel Collaborateur)
- **Fonctionnalités Clés** :
  - **Espace de pointage & Timesheet** : Saisie et validation des heures travaillées.
  - **Suivi des missions** : Attribution des chantiers et ordre de mission.
  - **Gestion des congés** : Soumission et suivi des demandes de congés.
  - **Messagerie interne & Chat** : Communication sécurisée avec les équipes.
  - **Bibliothèque de ressources** : Procédures opérationnelles, formulaires et normes JBF.

---

## 2. DÉPENDANCES ET ARCHITECTURE DART / FLUTTER
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.5.0
  provider: ^6.1.2
  fluent_ui: ^4.9.0
  bitsdojo_window: ^0.1.6
  http: ^1.2.1
  shared_preferences: ^2.2.3
  intl: ^0.19.0
```
- **Intégration Supabase** : Utilisation du SDK `supabase_flutter` initialisé avec la clé publique `Anon Key` fournie par le serveur API Node.js.
- **Sécurité des jetons** : Stockage chiffré des jetons de session d'authentification utilisateur (`Secure Storage`).
