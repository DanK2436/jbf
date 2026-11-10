# Applications Flutter JBF SERVICES

Trois applications natives **Material 3** officielles rose JBF (`#E6007E`) connectées en temps réel à Supabase et à l'API de messagerie transactionnelle Brevo :

| Application | Dossier | Desktop (Windows / macOS) | Mobile (Android / iOS) | Rôle & Authentification |
|-------------|---------|---------------------------|-------------------------|--------------------------|
| **Admin** | `jbf_admin` | Oui | Oui | Direction Générale : Super Dashboard, chiffrages devis, missions, pointages anti-VPN, congés, avis, sous-admins, **Sécurité OTP configurée à l'intérieur du logiciel** |
| **Membre** | `jbf_membre` | Oui | Oui | Collaborateurs & terrain : Pointages, missions, congés, chat direct (Connexion directe sans OTP) |
| **Client** | `jbf_client` | Oui | Oui | Partenaires & donneurs d'ordres : Dashboard KPIs, devis en ligne, suivi des chantiers GPS, factures, avis et support WhatsApp 24/7 |

## Règles d'authentification & Sécurité OTP (Mise à jour)

1. **Membres & Collaborateurs** :
   - L'exigence de code OTP a été totalement retirée.
   - Les collaborateurs se connectent directement avec leur matricule ou email professionnel et leur mot de passe.

2. **Administrateur Principal** :
   - À la première connexion (ou si aucun email OTP n'a encore été enregistré dans le logiciel) : le logiciel ne demande pas de code OTP et accorde un accès immédiat.
   - La saisie et modification de l'adresse email OTP s'effectuent **à l'intérieur du logiciel** (menu *Sécurité OTP Direction* ou depuis le rappel sur le Dashboard).
   - Dès qu'un email est enregistré, toute future connexion exigera un code OTP à 6 chiffres expédié par email via Brevo.
   - L'administrateur peut modifier ou retirer cet email à tout moment à l'intérieur du logiciel.

3. **Espace Client Partenaire** :
   - Application native complète riche en contenus (Dashboard, Devis interactifs, Chantiers en cours, Factures proforma, Avis clients, Hotline WhatsApp 24/7).
   - Accès démo partenaire en 1 clic ou inscription directe d'entreprise.

## URL du portail

Par défaut : `https://dank2436.github.io/jbf`. Pour un autre hébergement :

```bash
flutter run --dart-define=JBF_PORTAL_BASE=https://votre-domaine.com/jbf
```

## Développement local

```bash
cd flutter/jbf_admin   # ou jbf_membre / jbf_client
flutter pub get
flutter run -d chrome    # test rapide (WebView limitée sur web)
flutter run -d windows     # si SDK desktop installé
```

## Compilation CI & Installateurs Windows

Les builds release sont déclenchés par [`.github/workflows/flutter-build.yml`](../.github/workflows/flutter-build.yml) (push sur `flutter/**` ou `workflow_dispatch`).

### Installateurs Windows (.exe) générés automatiquement :
1. **`JBF-Admin-Setup-x64.exe`** : Installateur officiel pour l'espace Direction Générale
2. **`JBF-Membre-Setup-x64.exe`** : Installateur officiel pour les collaborateurs & équipes de terrain
3. **`JBF-Client-Setup-x64.exe`** : Installateur officiel pour les partenaires & clients miniers

### Fonctionnalités intégrées aux installateurs Windows :
* **Raccourci sur le Bureau** créé automatiquement avec l'icône officielle du logo JBF.
* **Raccourci dans le Menu Démarrer** groupé sous le dossier `JBF Services`.
* **Autorisation Pare-feu Windows (In/Out)** configurée automatiquement pour garantir les communications sans blocage vers Supabase, Brevo et les API de données.
* **Accès aux Notifications Windows Toast (Action Center)** : Déclaration et enregistrement officiel de l'identifiant `AppUserModelID` (`JBFServices.JBFAdmin.App`, `JBFServices.JBFMembre.App`, `JBFServices.JBFClient.App`) dans le Registre Windows.
* **Désinstalleur complet** nettoyant les raccourcis et règles de pare-feu.
* Versions d'archives portables `.zip` également produites.

### Prérequis postes utilisateurs

- **Windows** : [WebView2 Runtime](https://developer.microsoft.com/microsoft-edge/webview2/)
- **macOS** : 11+ ; autoriser l’ouverture si app non signée (build CI `--no-codesign`)
- **iOS** : build CI non signé — signature App Store via certificats Apple (secrets à configurer plus tard)

## Évolution

Les specs détaillées (UI native Supabase, offline, etc.) restent dans `specs/05_DESKTOP_FLUTTER_SPEC.md` et `specs/06_MOBILE_FLUTTER_SPEC.md`. La coque WebView permet une mise en production immédiate alignée sur le site actuel.
