# 📱 SPEC 06 : SPÉCIFICATION APPLICATIONS MOBILES FLUTTER
**Emplacement**: `A:\App_Mobiles\JBF App`  
**Technologie**: Flutter Mobile (Dart) pour Android & iOS

---

## 1. COMPOSANTS MOBILES

### A. `JBF Public Mobile App` (App Client)
- **Cible** : Entreprises et particuliers à la recherche de prestations JBF en RDC.
- **Fonctionnalités Clés** :
  - **Catalogue interactif des 15 prestations** avec recherche rapide.
  - **Demande de devis en 1 clic** avec pièces jointes (photos/cahier des charges).
  - **Suivi des demandes** et notifications Push en temps réel à chaque étape.
  - **Module d'Avis Clients** : Consultation et soumission d'avis certifiés avec notation par étoiles.

### B. `JBF Membre Mobile App` (App Agent / Équipe Terrain)
- **Cible** : Agents et techniciens déployés sur les chantiers miniers, bases de vie et sites industriels.
- **Fonctionnalités Clés** :
  - **Pointage par QR Code & Géolocalisation GPS** au début et à la fin de chaque mission.
  - **Rapports d'intervention terrain** avec prise de photos et signature numérique du client.
  - **Consignes de sécurité HSE & Fiches réflexes**.
  - **Messagerie instantanée d'urgence** avec le centre de contrôle.
  - **Mode Hors-Ligne (*Offline Sync*)** : Stockage local (Hive/SQLite) des données de pointage pour les zones sans réseau minier, avec synchronisation automatique dès le retour de la connexion.

### C. `JBF Admin Mobile App` (App Direction & Superviseur)
- **Cible** : Directeurs d'opérations et chefs de secteur.
- **Fonctionnalités Clés** :
  - **Tableau de bord de supervision mobile** (chantiers actifs, effectifs déployés, alertes HSE).
  - **Validation rapide des demandes de devis et ordres de mission**.
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
```
- **Sync Offline** : Les données enregistrées hors-ligne sont mises en file d'attente et transmises via l'API Node.js / Supabase dès le rétablissement de la connectivité.
