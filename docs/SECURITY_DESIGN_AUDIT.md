# Contrôle sécurité & design

## Inscription : une seule route, après un OTP d'usage « register »

L'ancienne `POST /api/auth/register` créait un compte `email_confirm: true` sans code et était déclarée avant la route protégée, donc elle capturait toutes les requêtes. Elle est supprimée. La route restante n'appelle `createUser` qu'après un OTP délivré pour l'usage `register` du même email. Un code de connexion ou de réinitialisation ne crée pas de compte. Les routes ouvertes `POST /api/admin/membres` et `POST /api/admin/sous-admins` ne créent plus de compte confirmé : elles n'authentifiaient pas l'appelant.

Les codes viennent de `crypto.randomInt`. Chaque usage a sa clé, une expiration, un plafond d'envois et de tentatives, et une consommation unique. Le quota est réservé dans `prepare`, avant l'attente du fournisseur : des requêtes simultanées ne peuvent pas toutes passer. Un échec d'envoi consomme quand même le créneau, qui se libère à la fin de la fenêtre (pas de blocage permanent). Si deux réponses arrivent dans le désordre, seul le dernier code demandé reste actif ; l'ancien est refusé.

## OTP : Brevo et Resend, pas l'OTP Auth Supabase

Le code confirme que Brevo (`POST https://api.brevo.com/v3/smtp/email`) et Resend (`POST https://api.resend.com/emails`) ne servent qu'à transporter le message. Le serveur Node génère le code à 6 chiffres, le garde en mémoire, et le compare lui-même. Ce n'est pas une vérification d'identité faite par ces fournisseurs.

Le parcours `supabase.auth.verifyOtp`, `supabase.auth.resend({ type: 'signup' })` et `resetPasswordForEmail` (lien magique Supabase) est retiré des pages et de `auth-client.js`. Supabase reste utilisé pour le mot de passe (`signInWithPassword`), la session, les profils et le stockage. Aucun utilisateur, aucune table et aucun projet n'ont été modifiés.

Sans `BREVO_API_KEY` ni `RESEND_API_KEY` sur le serveur, l'envoi répond 503 et aucun code n'est actif. Un échec fournisseur n'enregistre pas de code. Le sujet du message ne contient plus le code. La fonction Edge de réinitialisation, si elle est déployée plus tard par le propriétaire, suit le même schéma Brevo puis Resend et refuse aussi l'envoi sans clé. Elle n'est pas déployée par ce changement.

## Lot bee1ef9 — messagerie, relais et en-têtes

Les clés de messagerie ne sont plus dans l'arbre de travail, mais elles restent dans l'historique Git antérieur à leur retrait. Ce dépôt ne les révoque pas et n'en affiche pas les valeurs. Le propriétaire doit les faire tourner ou révoquer chez les fournisseurs (Brevo, Resend) depuis leurs consoles.

Le navigateur ne lit plus `window.ENV_BREVO_API_KEY` ni `window.ENV_RESEND_API_KEY`, et n'appelle plus les API de ces fournisseurs. L'envoi d'un code passe par `POST /api/auth/otp/send` ou `POST /api/auth/reset-otp/send` : le serveur génère le code, ne le renvoie pas, et répond 503 s'il n'a aucune clé fournisseur. La vérification `POST /api/auth/otp/verify` n'accepte qu'un code ainsi délivré.

`POST /api/mail/send` est fermé (403) sur Express et sur `serve.py`. Origin, `Sec-Fetch-Site` et l'adresse loopback ne sont pas une authentification : ces en-têtes se falsifient, et un reverse proxy peut faire passer un client distant pour un client local. Rouvrir ce relais de contenu libre suppose un contrôle serveur qui n'existe pas encore (session ou jeton connu seulement du serveur, pas du navigateur). Jusque-là le comportement est fail-closed.

Conséquence : la connexion par mot de passe Supabase ne change pas. Le code email et la réinitialisation exigent le backend Node joignable (`127.0.0.1:3001` en local) avec `BREVO_API_KEY` ou `RESEND_API_KEY` dans l'environnement du serveur, ou la fonction Edge déployée avec sa clé. GitHub Pages seul ne peut plus émettre de code. Un code affiché ou stocké dans le navigateur, y compris l'ancien mode WhatsApp de démonstration, n'ouvre plus de session.

Les en-têtes CSP et `X-Frame-Options` sont posés par `applySecurityHeaders` dès la création de l'application Express, avant les routes. Ils couvrent donc les réponses 200, 401, 403, 404 et 500 de ce processus. Ils ne décrivent pas un proxy de production qui terminerait la requête avant Node.

## Contre-revue statique (baseline dc44014, vérifiée sur la branche redesign)

Les points ci-dessous étaient un rapport de lecture du baseline, pas des tests dynamiques déjà acquis. Ils ont été rejoués ensuite avec des secrets factices.

| Constat baseline | État sur la branche | Suite |
|---|---|---|
| `serve.py` servait la racine du dépôt, y compris `backend/.env`, et écoutait `0.0.0.0` | Confirmé avant correctif | Allowlist (`JBF Public`, `JBF Client`, `assets`, `js`, `index.html`, `supabase/*.js`). Refus des dotfiles, de `..` et des chemins réencodés. Écoute `127.0.0.1` par défaut (`JBF_BIND_HOST` pour déroger). |
| Mot de passe admin de repli | Déjà retiré du code exécutable. Le fichier `backend/.env.example` le proposait encore | Exemple vidé. Comparaison fail-closed si absent, vide ou incorrect. |
| OTP en clair dans les logs `serve.py` et `backend/server.js` | Confirmé | Les journaux indiquent qu'un code a été traité, sans sa valeur. |
| `POST /api/mail/send` anonyme | Confirmé sur `serve.py` et sur Express | Refus si l'appelant n'est pas en loopback avec `Sec-Fetch-Site: same-origin` ou une origine `localhost` / `127.0.0.1`. Le navigateur du site local passe encore. Pas d'envoi réel dans les tests (mock). |
| CSP et anti-iframe absents du code lu | Confirmé dans le dépôt | En-têtes ajoutés sur `serve.py` et Express (`frame-ancestors 'none'`, `X-Frame-Options: DENY`). Les pages ont encore des scripts inline, donc `script-src` inclut `'unsafe-inline'` et le CDN jsDelivr. Ce n'est pas une preuve que l'hébergement de production (proxy, GitHub Pages) envoie ces en-têtes. |

Le mode démonstration WhatsApp renvoie toujours le code dans la réponse affichée à l'utilisateur quand l'API n'est pas configurée. Ce n'est plus écrit dans `console.log`.

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
