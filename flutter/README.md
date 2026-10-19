# Applications Flutter JBF SERVICES

Trois applications embarquant les portails web existants (GitHub Pages) dans une coque native **Material 3** rose JBF (`#E6007E`), avec WebView sécurisée (`flutter_inappwebview`).

| Application | Dossier | Desktop (Windows / macOS) | Mobile (Android / iOS) |
|-------------|---------|---------------------------|-------------------------|
| **Admin** | `jbf_admin` | Oui | Oui |
| **Membre** | `jbf_membre` | Oui | Oui |
| **Client** | `jbf_client` | Non | Oui |

Package partagé : `packages/jbf_portal_shell`.

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

## Compilation CI

Les builds release sont déclenchés par [`.github/workflows/flutter-build.yml`](../.github/workflows/flutter-build.yml) (push sur `flutter/**` ou `workflow_dispatch`).

Artefacts : APK Android, IPA (sans signature store), `.exe`/zip Windows, `.app`/zip macOS.

### Prérequis postes utilisateurs

- **Windows** : [WebView2 Runtime](https://developer.microsoft.com/microsoft-edge/webview2/)
- **macOS** : 11+ ; autoriser l’ouverture si app non signée (build CI `--no-codesign`)
- **iOS** : build CI non signé — signature App Store via certificats Apple (secrets à configurer plus tard)

## Évolution

Les specs détaillées (UI native Supabase, offline, etc.) restent dans `specs/05_DESKTOP_FLUTTER_SPEC.md` et `specs/06_MOBILE_FLUTTER_SPEC.md`. La coque WebView permet une mise en production immédiate alignée sur le site actuel.
