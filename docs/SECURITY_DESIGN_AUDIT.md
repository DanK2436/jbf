# Contrôle sécurité & design (oct. 2026)

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
