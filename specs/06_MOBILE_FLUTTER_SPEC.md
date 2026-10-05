# 📱 SPEC 06 : SPÉCIFICATION APPLICATIONS MOBILES FLUTTER
**Emplacement**: `A:\App_Mobiles\JBF App`  
**Technologie**: Flutter Mobile (Dart) pour Android & iOS

---

## 1. COMPOSANTS MOBILES

### A. `JBF Public Mobile App` (App Client)
- **Cible** : Entreprises et particuliers à la recherche de prestations JBF en RDC.
- **Fonctionnalités Clés** :
  - **Catalogue interactif des 15 prestations** avec recherche rapide.
  - **Demande de devis en 1 clic** avec pièces jointes techniques (jusqu'à 3 fichiers ou photos de chantier).
  - **Suivi des devis** : Historique en temps réel des propositions commerciales avec calcul des KPI.
  - **Module d'Avis Clients** : Consultation immédiate des avis approuvés et soumission d'évaluations certifiées avec notation par étoiles.
  - **Authentification Sécurisée** : Connexion par OTP Email transmis exclusivement via Brevo & Resend (sans passer par les SMS ou WhatsApp).

### B. `JBF Membre Mobile App` (App Agent / Équipe Terrain)
- **Cible** : Agents et techniciens déployés sur les chantiers miniers, bases de vie et sites industriels.
- **Fonctionnalités Clés** :
  - **Pointage par QR Code & Géolocalisation GPS** au début et à la fin de chaque mission.
  - **Rapports d'intervention terrain** avec prise de photos via appareil mobile ou sélection de lien.
  - **Demande & Suivi des Congés** : Calcul instantané des jours ouvrés, consultation du solde restant et suivi de la décision de la DRH (*En attente*, *Approuvé*, *Refusé*).
  - **Ressources & Directives HSE** : Téléchargement direct des manuels et procédures opérationnelles.
  - **Mode Hors-Ligne (*Offline Sync*)** : Stockage local (Hive/SQLite) des données de pointage pour les zones sans réseau minier, avec synchronisation automatique dès le retour de la connexion.

### C. `JBF Admin Mobile App` (App Direction & Superviseur)
- **Cible** : Directeurs d'opérations et chefs de secteur.
- **Fonctionnalités Clés** :
  - **Tableau de bord de supervision mobile** (chantiers actifs, effectifs déployés, alertes HSE réelles Supabase).
  - **Validation des Devis et Ordres de Mission** : Traitement et affectation des effectifs miniers.
  - **Validation des Congés en 1 Clic** : Approbation ou refus immédiat des demandes d'absence.
  - **Notifications PUSH prioritaires** en cas d'incident sur le terrain.

---

## 2. ARCHITECTURE TECHNIQUE MOBILE
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.5.0
  hive_flutter: ^1.1.0
  geolocator: ^11.0.0
  qr_code_scanner: ^1.0.1
  flutter_local_notifications: ^17.1.0
  camera: ^0.10.5+9
  file_picker: ^8.0.0
  http: ^1.2.1
```
- **Sécurité & Auth** : Intégration de l'OTP Email Brevo/Resend avec expiration stricte à 10 minutes.
- **Sync Offline** : Les données enregistrées hors-ligne sont mises en file d'attente et transmises via Supabase dès le rétablissement de la connectivité.
