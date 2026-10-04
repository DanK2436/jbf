-- ==============================================================================
-- JBF SERVICES — SCHÉMA COMPLET SUPABASE POSTGRESQL (v9.5)
-- Exécuter ce script dans le SQL Editor du tableau de bord Supabase :
-- https://supabase.com/dashboard/project/dvzwqxcaiagczyonrhsg/sql
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABLE : PROFILES (Utilisateurs, Clients, Collaborateurs, Admins)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE,
  email TEXT UNIQUE NOT NULL,
  nom TEXT,
  prenom TEXT,
  nom_complet TEXT,
  telephone TEXT,
  entreprise TEXT,
  fonction TEXT,
  role TEXT DEFAULT 'client', -- 'superadmin', 'admin', 'membre', 'client'
  secteur TEXT,
  site_assignation TEXT,
  solde_conges INTEGER DEFAULT 30,
  statut TEXT DEFAULT 'actif', -- 'actif', 'suspendu'
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TABLE : DEMANDES DE DEVIS (Demandes de cotation 15 prestations)
CREATE TABLE IF NOT EXISTS public.demandes_devis (
  id TEXT PRIMARY KEY,
  client_id TEXT,
  client_nom TEXT NOT NULL,
  client_societe TEXT,
  client_email TEXT,
  client_telephone TEXT NOT NULL,
  prestation TEXT NOT NULL,
  prestations_associees TEXT[],
  details_besoin TEXT,
  site_intervention TEXT,
  province TEXT,
  ville TEXT,
  statut TEXT DEFAULT 'nouveau', -- 'nouveau', 'en_etude', 'valide', 'rejete'
  fichiers JSONB DEFAULT '[]'::JSONB,
  montant_estime NUMERIC,
  remarques_admin TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABLE : MISSIONS (Chantiers & Interventions terrain)
CREATE TABLE IF NOT EXISTS public.missions (
  id TEXT PRIMARY KEY,
  titre TEXT NOT NULL,
  code_mission TEXT,
  client_id TEXT,
  client_nom TEXT,
  societe TEXT,
  prestation TEXT,
  site_lieu TEXT,
  province TEXT,
  date_debut DATE,
  date_fin_estimee DATE,
  responsable_jbf TEXT,
  statut TEXT DEFAULT 'en_cours', -- 'planifiee', 'en_cours', 'terminee', 'suspendue'
  progression_pct INTEGER DEFAULT 0,
  observations TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TABLE : FACTURES (Facturation et Règlements clients)
CREATE TABLE IF NOT EXISTS public.factures (
  id TEXT PRIMARY KEY,
  numero_facture TEXT UNIQUE NOT NULL,
  client_id TEXT,
  client_nom TEXT NOT NULL,
  devis_id TEXT,
  mission_id TEXT,
  montant_ht NUMERIC NOT NULL DEFAULT 0,
  montant_tva NUMERIC DEFAULT 0,
  montant_ttc NUMERIC NOT NULL DEFAULT 0,
  devise TEXT DEFAULT 'USD',
  statut TEXT DEFAULT 'en_attente', -- 'en_attente', 'payee', 'en_retard', 'annulee'
  date_emission DATE DEFAULT CURRENT_DATE,
  date_echeance DATE,
  date_paiement DATE,
  mode_paiement TEXT,
  pdf_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. TABLE : TICKETS DE SUPPORT (Assistance & Service Client)
CREATE TABLE IF NOT EXISTS public.tickets_support (
  id TEXT PRIMARY KEY,
  client_id TEXT,
  client_nom TEXT NOT NULL,
  client_email TEXT,
  client_telephone TEXT,
  societe TEXT,
  sujet TEXT NOT NULL,
  categorie TEXT DEFAULT 'Assistance générale',
  priorite TEXT DEFAULT 'normale', -- 'basse', 'normale', 'haute', 'urgente'
  message TEXT NOT NULL,
  statut TEXT DEFAULT 'ouvert', -- 'ouvert', 'en_traitement', 'resolu', 'ferme'
  reponse_admin TEXT,
  canal TEXT DEFAULT 'web',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. TABLE : AVIS CLIENTS (Modération et publication sur le site)
CREATE TABLE IF NOT EXISTS public.avis_clients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nom TEXT NOT NULL,
  prenom TEXT,
  fonction TEXT,
  entreprise TEXT NOT NULL,
  ville TEXT,
  province TEXT,
  note INTEGER CHECK (note >= 1 AND note <= 5),
  stars INTEGER CHECK (stars >= 1 AND stars <= 5),
  categorie TEXT,
  commentaire TEXT NOT NULL,
  approuve BOOLEAN DEFAULT false,
  date_avis DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. TABLE : GALERIE ITEMS (Photos & Vidéos administrables)
CREATE TABLE IF NOT EXISTS public.galerie_items (
  id TEXT PRIMARY KEY,
  titre TEXT NOT NULL,
  categorie TEXT NOT NULL,
  type TEXT DEFAULT 'photo', -- 'photo', 'video'
  url TEXT NOT NULL,
  video_url TEXT,
  description TEXT,
  localite TEXT DEFAULT 'RDC',
  publie BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Synonyme / Table de secours
CREATE TABLE IF NOT EXISTS public.gallery_images (
  id TEXT PRIMARY KEY,
  titre TEXT NOT NULL,
  categorie TEXT,
  localite TEXT,
  img_url TEXT,
  description TEXT,
  periode TEXT,
  impact TEXT,
  publie BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. TABLE : ACTUALITÉS & BLOG (Articles et publications officielles)
CREATE TABLE IF NOT EXISTS public.actualites (
  id TEXT PRIMARY KEY,
  titre TEXT NOT NULL,
  categorie TEXT NOT NULL,
  excerpt TEXT,
  description_courte TEXT,
  contenu TEXT NOT NULL,
  description_detaillee TEXT,
  image TEXT,
  video TEXT,
  auteur TEXT DEFAULT 'Direction Générale JBF',
  statut TEXT DEFAULT 'publie', -- 'brouillon', 'publie', 'archive'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Synonyme / Table de secours
CREATE TABLE IF NOT EXISTS public.blog_posts (
  id TEXT PRIMARY KEY,
  titre TEXT NOT NULL,
  categorie TEXT,
  resume TEXT,
  contenu TEXT,
  image_url TEXT,
  date_publication TIMESTAMPTZ DEFAULT NOW(),
  publie BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. TABLE : DEMANDES DE CONGÉS (Collaborateurs)
CREATE TABLE IF NOT EXISTS public.demandes_conges (
  id TEXT PRIMARY KEY,
  membre_id TEXT,
  membre_nom TEXT NOT NULL,
  date_debut DATE NOT NULL,
  date_fin DATE NOT NULL,
  motif TEXT,
  jours_ouvrables INTEGER,
  statut TEXT DEFAULT 'en_attente', -- 'en_attente', 'valide', 'refuse'
  remarques TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. TABLE : AUDIT LOGS (Journalisation des actions d'administration)
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_nom TEXT,
  action TEXT NOT NULL,
  target TEXT,
  details JSONB,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demandes_devis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.factures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets_support ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avis_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.galerie_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gallery_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.actualites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demandes_conges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Politiques de lecture et d'écriture publiques (clés client-side avec gestion par portail)
DO $$
BEGIN
  -- PROFILES
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public select on profiles') THEN
    CREATE POLICY "Allow public select on profiles" ON public.profiles FOR SELECT USING (true);
    CREATE POLICY "Allow public insert on profiles" ON public.profiles FOR INSERT WITH CHECK (true);
    CREATE POLICY "Allow public update on profiles" ON public.profiles FOR UPDATE USING (true);
  END IF;

  -- DEMANDES DE DEVIS
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public on devis') THEN
    CREATE POLICY "Allow public on devis" ON public.demandes_devis FOR ALL USING (true) WITH CHECK (true);
  END IF;

  -- MISSIONS
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public on missions') THEN
    CREATE POLICY "Allow public on missions" ON public.missions FOR ALL USING (true) WITH CHECK (true);
  END IF;

  -- FACTURES
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public on factures') THEN
    CREATE POLICY "Allow public on factures" ON public.factures FOR ALL USING (true) WITH CHECK (true);
  END IF;

  -- TICKETS SUPPORT
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public on tickets') THEN
    CREATE POLICY "Allow public on tickets" ON public.tickets_support FOR ALL USING (true) WITH CHECK (true);
  END IF;

  -- AVIS CLIENTS
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public on avis') THEN
    CREATE POLICY "Allow public on avis" ON public.avis_clients FOR ALL USING (true) WITH CHECK (true);
  END IF;

  -- GALERIE
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public on galerie') THEN
    CREATE POLICY "Allow public on galerie" ON public.galerie_items FOR ALL USING (true) WITH CHECK (true);
    CREATE POLICY "Allow public on gallery_images" ON public.gallery_images FOR ALL USING (true) WITH CHECK (true);
  END IF;

  -- ACTUALITES
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public on actualites') THEN
    CREATE POLICY "Allow public on actualites" ON public.actualites FOR ALL USING (true) WITH CHECK (true);
    CREATE POLICY "Allow public on blog_posts" ON public.blog_posts FOR ALL USING (true) WITH CHECK (true);
  END IF;

  -- CONGES
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public on conges') THEN
    CREATE POLICY "Allow public on conges" ON public.demandes_conges FOR ALL USING (true) WITH CHECK (true);
  END IF;

  -- AUDIT LOGS
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow public on audit_logs') THEN
    CREATE POLICY "Allow public on audit_logs" ON public.audit_logs FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;
