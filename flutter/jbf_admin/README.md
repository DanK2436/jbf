# JBF Admin — application bureau & mobile

Application native **JBF Admin** (Windows, macOS, Android, iOS) qui embarque le portail web d’administration avec :

- **Logo JBF** dans la barre de navigation
- **Clés Supabase** injectées au build (`--dart-define`) et dans la WebView (`ENV_SUPABASE_*`)
- **Notifications bureau** pour les nouveaux messages directs des chefs d’équipe (polling Supabase `messages_chat`)
- Accès rapide à **Messagerie équipes** depuis l’icône cloche dans la barre

## Compilation locale

```bash
cd flutter/packages/jbf_portal_shell && flutter pub get
cd ../../jbf_admin && flutter pub get
flutter run -d windows   # ou macos
```

Variables optionnelles :

```bash
flutter run -d macos \
  --dart-define=JBF_PORTAL_BASE=https://dank2436.github.io/jbf \
  --dart-define=JBF_SUPABASE_URL=https://dvzwqxcaiagczyonrhsg.supabase.co \
  --dart-define=JBF_SUPABASE_ANON_KEY=votre_cle_anon
```

## CI GitHub Actions

Workflow [`.github/workflows/flutter-build.yml`](../../.github/workflows/flutter-build.yml) :

- **Windows** : artefact `JBF-Admin-Windows-x64.zip`
- **macOS** : artefact `JBF-Admin-macOS.zip` (`JBF Admin.app`)

Déclenchement : push sur `flutter/**`, branche `main` / `cursor/**`, ou **Actions → Run workflow**.

### Secrets GitHub (optionnels)

| Secret | Usage |
|--------|--------|
| `JBF_SUPABASE_ANON_KEY` | Surcharge la clé anon au build (sinon défaut = site web) |

## Prérequis utilisateur

- **Windows** : [WebView2 Runtime](https://developer.microsoft.com/microsoft-edge/webview2/)
- **macOS** : 11+ ; autoriser l’app si build CI non signé
