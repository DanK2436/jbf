# 🖥️ SPEC 05 : SPÉCIFICATION LOGICIELS DESKTOP FLUTTER
**Emplacement**: `C:\Users\is mlckl\Desktop\Logiciels\JBF Desktop`  
**Technologie**: Flutter Desktop (Dart) pour Windows, macOS, Linux

---

## 1. COMPOSANTS DESKTOP

### A. `JBF Admin Desktop` (Logiciel Administration & Supervision)
- **Fonctionnalités Clés** :
  - **Tableau de bord exécutif** : Métriques en temps réel issues de Supabase sur les 15 prestations à travers la RDC.
  - **Gestion des demandes de devis** : Validation, tarification et émission des offres commerciales.
  - **Gestion des utilisateurs & Membres** : Création libre sans restriction de domaine email (`@jbf-services.cd` supprimé), avec téléphone et ville obligatoires, et modification de mot de passe intégrée.
  - **Gestion des Sous-Administrateurs** : Saisie du mot de passe directement à la création et assignation granulaire des accès.
  - **Missions & Galerie Multimédia** : Double mode d'ajout de médias (téléversement de fichier local ou lien URL externe/stream) avec prévisualisation.
  - **Actualités & Blog** : Accroches, images de couverture et vidéos avec double source (upload direct ou URL).
  - **Validation des Congés RH** : Décision directe (Approuver / Rejeter) sur les demandes d'absence avec mise à jour instantanée.
  - **Ressources & Fiches Métiers** : Téléversement direct (PDF, Word, Excel, MP4) ou lien externe avec statut de publication.
- **Interface UI** : Thème 90% Rose Vif (`#E6007E`) / 10% Blanc (`#FFFFFF`), navigation latérale *Fluent Sidebar* (sans lien vers une page isolée de mot de passe).

### B. `JBF Membre Desktop` (Logiciel Collaborateur)
- **Fonctionnalités Clés** :
  - **Espace de pointage & Timesheet** : Saisie et validation des heures travaillées.
  - **Suivi des missions** : Attribution des chantiers et ordre de mission.
  - **Gestion des congés** : Soumission de demandes et consultation du tableau historique avec statuts RH (*En attente*, *Approuvé*, *Refusé*).
  - **Messagerie interne & Chat** : Communication sécurisée avec les équipes.
  - **Bibliothèque de ressources** : Consultation et téléchargement des documents certifiés, avec possibilité de partage direct (upload ou lien).

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
  file_picker: ^8.0.0
```
- **Intégration Supabase & OTP** : Authentification par OTP Email gérée via le service transactionnel Brevo (primaire) et Resend (fallback).
- **Sécurité des jetons** : Stockage chiffré des jetons de session d'authentification utilisateur (`Secure Storage`).
- **Gestion des Fichiers** : Prise en charge universelle du sélecteur de fichier (`file_picker`) et des URL distantes.
