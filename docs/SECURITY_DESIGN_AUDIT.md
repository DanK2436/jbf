# Contrôle sécurité & design

## Revue de novembre 2026 (redesign web)

Correctifs appliqués dans le dépôt, sans test d'intrusion sur la production et sans mutation de données :

| Sévérité | Sujet | Fichiers | Remède appliqué |
|---|---|---|---|
| Haute | Clés Brevo et Resend reconstruites dans le JavaScript public, et lecture navigateur de `config_cles_api` | `supabase/mail-service.js`, `JBF Client/js/config.js` | Clés retirées. L'envoi direct n'utilise plus de secret versionné ni le stockage local. Les fonctions `sendClientLoginOtp` et `sendClientPasswordReset` restent disponibles et passent par le relais backend si aucune variable `window.ENV_*` n'est définie hors dépôt. |
| Haute | Mot de passe administrateur de repli en clair, et journalisation du mot de passe | `backend/server.js`, `backend/scripts/init-admin.js`, `serve.py` | Plus de mot de passe par défaut. Un mot de passe vide ne valide pas la connexion. Le provisionnement est ignoré tant que `ADMIN_OFFICIAL_PASSWORD` n'est pas défini. |
| Haute | Création de comptes staff sans identité appelante, et copie libre de `extraProfile` | `supabase/functions/staff-provision/index.ts` | Jeton utilisateur obligatoire et rôle admin, direction ou sous-admin. Le corps libre n'est plus recopié dans `profiles`. |
| Moyenne | Injection HTML depuis le fragment d'URL et contenus d'articles ou de galerie | `JBF Public/auth/login.html`, `blog.html`, `gallery.html` | Échappement des textes et retrait des balises et attributs d'événement avant affichage HTML d'article. |
| Moyenne | `body-parser` et `qs` signalés par `npm audit` | `backend/package.json` | Contrainte `overrides` vers les versions corrigées, sans changer les routes Express. |
| Basse | Préfixe de clé dans un schéma d'architecture | `specs/00_SYSTEM_ARCHITECTURE.md` | Mention remplacée par un libellé sans secret. |
| Basse | Export de diagnostic de compte messagerie | `brevo_diag.json` | Contenu de compte retiré du fichier versionné. |

Risques restants, non corrigés ici parce qu'ils changeraient le contrat d'accès ou exigent la configuration Supabase en production :

| Sévérité | Risque | Fichiers | Remède recommandé |
|---|---|---|---|
| Haute | La clé anon Supabase est publique, ce qui est normal, mais toute politique RLS permissive expose les tables. | Pages et `supabase/supabase_config.js`, `JBF Client/js/config.js` | Vérifier les politiques en lecture seule côté projet, sans les modifier depuis cet environnement. |
| Haute | OTP de connexion encore décidable dans le navigateur si l'envoi réel échoue : le mode simulation local existant répond succès. | `supabase/mail-service.js`, pages de connexion client | Désactiver la simulation hors développement et n'émettre les codes que depuis une fonction Edge. |
| Moyenne | CORS `*` sur l'API Express et les fonctions Edge. | `backend/server.js`, `supabase/functions/_shared/cors.ts` | Restreindre les origines aux domaines JBF lorsque la liste de déploiements est figée. |
| Moyenne | Sessions portail stockées dans `localStorage`. | `supabase/auth-client.js`, pages client | Cookies httpOnly posés par le backend. |
| Moyenne | Réinitialisation de mot de passe par code à 6 chiffres. | `supabase/functions/client-reset-password/index.ts` | Limiter les essais et lier le code à une session serveur. |
| Basse | Le workflow de ping planifié contient la clé anon. | `.github/workflows/keep-supabase-alive.yml` | La déplacer vers un secret de dépôt. La rotation de la clé anon reste une action manuelle. |

Aucun essai d'intrusion ni aucune écriture n'a été fait sur le projet Supabase de production.

## Contrôle d'octobre 2026

## Verdict global

**Design** : cohérent avec la charte rose JBF sur les portails web ; formulaire avis refait (plus de témoignages fictifs).  
**Sécurité** : pas de régression critique dans les derniers changements ; points structurels à traiter côté Supabase / admin statique (voir ci‑dessous).

## Points validés

| Zone | Statut |
|------|--------|
| Avis publics | Uniquement `approuve = true` ; soumission en modération |
| XSS avis (affichage) | Échappement HTML sur les cartes avis |
| Apps Flutter | Coque WebView ; pas de clé `service_role` embarquée ; URL configurable via `--dart-define` |
| CI Flutter | Analyse + tests unitaires avant builds |

## Risques connus (existants, hors scope Flutter)

1. **Admin GitHub Pages** : authentification partiellement côté navigateur (`localStorage`, comptes locaux). Ne remplace pas un contrôle serveur pour des données sensibles.
2. **Clé Supabase anon** dans le JS public : normale pour Supabase ; **RLS** doit rester strict en production (éviter les politiques `FOR ALL USING (true)` sur tables sensibles si possible).
3. **Identifiants admin par défaut** dans `login.html` : réservés au déploiement statique ; à changer en production et privilégier Supabase Auth / backend.
4. **WebView mobile/desktop** : même surface d’attaque qu’un navigateur (XSS sur le site embarqué = impact session). Maintenir l’hygiène XSS sur les portails HTML.

## Recommandations prochaines étapes

- Activer Supabase Auth pour admin / membres / clients et retirer les mots de passe en dur.
- Restreindre RLS (insert public avis OK, update/delete admin via rôle authentifié).
- Signer les binaires iOS/macOS (secrets Apple dans GitHub Actions) avant App Store / notarisation.
