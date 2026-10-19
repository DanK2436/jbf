# Déployer les tables Supabase (JBF)

Projet configuré dans le code : `https://dvzwqxcaiagczyonrhsg.supabase.co`  
Remplacez par **votre** URL si votre ref projet est différente.

## Méthode 1 — SQL Editor (recommandé, 2 min)

1. Ouvrir [Supabase SQL](https://supabase.com/dashboard/project/dvzwqxcaiagczyonrhsg/sql/new).
2. Coller le contenu de **`supabase/FULL_SCHEMA_APPLY.sql`** (toutes les tables + RLS).
3. Cliquer **Run**.

## Méthode 2 — Script Node (URL + clés API + mot de passe DB)

1. Copier `backend/.env.example` → `backend/.env`.
2. Renseigner :
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY` (Settings → API → service_role)
   - `SUPABASE_DB_PASSWORD` (Settings → Database → password)
3. Exécuter :

```bash
cd backend
npm ci
npm run db:apply
```

Données de démo optionnelles : `npm run db:apply:seed`

## Méthode 3 — GitHub Actions

Ajouter les secrets du repo : `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_DB_PASSWORD`  
Puis lancer le workflow **Apply Supabase Schema**.

## Connexion Espace Membre (obligatoire si « Invalid login credentials »)

Exécuter aussi **`supabase/migrations/20261019_member_portal_login.sql`** dans le SQL Editor (RPC login, sync, **suppression** membre, colonne **`statut_equipe`** `membre` | `chef_equipe`), puis **recréer ou resynchroniser** le collaborateur depuis Admin → Collaborateurs.

Si la migration a déjà été appliquée une première fois, ré-exécutez **uniquement** les blocs `ALTER TABLE … statut_equipe`, `admin_sync_member_account` (11 paramètres) et `admin_delete_member_account` du même fichier.

Déployer l’Edge Function **`staff-provision`** (optionnel, comptes Auth natifs) :

```bash
supabase functions deploy staff-provision --project-ref dvzwqxcaiagczyonrhsg
```

## Tables créées

`profiles`, `demandes_devis`, `missions`, `factures`, `tickets_support`, `avis_clients`, `galerie_items`, `gallery_images`, `actualites`, `demandes_conges`, `pointages`, `messages_chat`, `admin_accounts`, `config_cles_api`, `audit_logs`, `documents_registry`, `password_reset_challenges`, `blog_posts`, `member_portal_accounts` (+ bucket Storage `documents`).
