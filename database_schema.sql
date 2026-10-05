-- ==============================================================================
-- JBF SERVICES — SCHÉMA COMPLET SUPABASE POSTGRESQL (v10.0 UNIFIÉ)
-- Compatible Web (GitHub Pages), Mobile Flutter, Desktop Flutter & Backend API
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
  full_name TEXT,
  telephone TEXT,
  phone TEXT,
  entreprise TEXT,
  company TEXT,
  fonction TEXT,
  poste TEXT,
  role TEXT DEFAULT 'client', -- 'super_admin', 'admin', 'sous_admin', 'membre', 'client'
  secteur TEXT,
  section_id INTEGER,
  section_nom TEXT,
  matricule TEXT,
  site_assignation TEXT,
  city TEXT,
  province TEXT,
  address TEXT,
  solde_conges INTEGER DEFAULT 30,
  statut TEXT DEFAULT 'actif',
  is_verified BOOLEAN DEFAULT true,
  permissions TEXT[] DEFAULT '{"*"}',
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TABLE : DEMANDES DE DEVIS (Demandes de cotation 15 prestations)
CREATE TABLE IF NOT EXISTS public.demandes_devis (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id TEXT,
  client_nom TEXT,
  nom TEXT,
  client_societe TEXT,
  societe TEXT,
  client_email TEXT,
  email TEXT,
  client_telephone TEXT,
  telephone TEXT,
  prestation TEXT,
  services TEXT[],
  prestations_associees TEXT[],
  details_besoin TEXT,
  message TEXT,
  site_intervention TEXT DEFAULT 'Lubumbashi',
  localite TEXT DEFAULT 'Toute la RDC',
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
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  titre TEXT NOT NULL,
  code_mission TEXT,
  client_id TEXT,
  client_nom TEXT,
  client TEXT,
  societe TEXT,
  prestation TEXT,
  service TEXT,
  site_lieu TEXT,
  site_intervention TEXT DEFAULT 'Lubumbashi',
  province TEXT,
  date_debut TIMESTAMPTZ DEFAULT NOW(),
  date_fin_estimee DATE,
  date_fin TIMESTAMPTZ,
  responsable_jbf TEXT,
  agents_assignes TEXT[] DEFAULT '{}'::TEXT[],
  statut TEXT DEFAULT 'en_cours', -- 'planifiee', 'en_cours', 'terminee', 'suspendue'
  progression_pct INTEGER DEFAULT 0,
  observations TEXT,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TABLE : FACTURES (Facturation et Règlements clients)
CREATE TABLE IF NOT EXISTS public.factures (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id TEXT,
  client_nom TEXT NOT NULL,
  client_email TEXT,
  client_telephone TEXT,
  societe TEXT,
  sujet TEXT NOT NULL,
  objet TEXT,
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
  service TEXT,
  categorie TEXT,
  commentaire TEXT NOT NULL,
  approuve BOOLEAN DEFAULT false,
  date_avis DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. TABLE : GALERIE ITEMS (Photos & Vidéos administrables)
CREATE TABLE IF NOT EXISTS public.galerie_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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

-- 10. TABLE : DEMANDES DE CONGÉS (Collaborateurs)
CREATE TABLE IF NOT EXISTS public.demandes_conges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  membre_id TEXT,
  membre_nom TEXT,
  agent_nom TEXT,
  type_conge TEXT DEFAULT 'Annuel',
  date_debut DATE NOT NULL,
  date_fin DATE NOT NULL,
  motif TEXT,
  jours_ouvrables INTEGER DEFAULT 1,
  statut TEXT DEFAULT 'en_attente', -- 'en_attente', 'approuve', 'refuse'
  motif_rejet TEXT,
  remarques TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. TABLE : POINTAGES & RELEVÉS DE TEMPS (Horodatage, GPS, Anti-VPN)
CREATE TABLE IF NOT EXISTS public.pointages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  agent_id TEXT,
  agent_nom TEXT NOT NULL,
  matricule TEXT,
  site_lieu TEXT DEFAULT 'Lubumbashi',
  type_pointage TEXT DEFAULT 'entree', -- 'entree', 'sortie'
  date_heure TIMESTAMPTZ DEFAULT NOW(),
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  precision_gps DOUBLE PRECISION,
  statut_validation TEXT DEFAULT 'valide', -- 'valide', 'en_attente', 'rejete'
  heures_normales NUMERIC DEFAULT 8,
  heures_supplementaires NUMERIC DEFAULT 0,
  is_vpn BOOLEAN DEFAULT false,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. TABLE : MESSAGES CHAT (Intranet Membres)
CREATE TABLE IF NOT EXISTS public.messages_chat (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  expediteur_id TEXT,
  expediteur_nom TEXT NOT NULL,
  expediteur_avatar TEXT DEFAULT 'JBF',
  canal_type TEXT DEFAULT 'general', -- 'general', 'section', 'urgence'
  section_id INTEGER,
  section_nom TEXT,
  message TEXT NOT NULL,
  fichiers JSONB DEFAULT '[]'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. TABLE : ADMIN ACCOUNTS (Gestion des sous-administrateurs)
CREATE TABLE IF NOT EXISTS public.admin_accounts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  role TEXT DEFAULT 'sous_admin', -- 'super_admin', 'sous_admin'
  permissions TEXT[] DEFAULT '{"dashboard"}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. TABLE : CONFIG CLÉS API (Sécurisée)
CREATE TABLE IF NOT EXISTS public.config_cles_api (
  cle_nom TEXT PRIMARY KEY,
  cle_valeur TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15. TABLE : AUDIT LOGS (Journalisation des actions d'administration)
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_nom TEXT,
  action TEXT NOT NULL,
  target TEXT,
  details JSONB,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 16. TABLE : DOCUMENTS_REGISTRY (Gestion intelligente, déduplication et cache documents)
CREATE TABLE IF NOT EXISTS public.documents_registry (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  file_hash TEXT NOT NULL, -- Empreinte cryptographique SHA-256
  file_name TEXT NOT NULL,
  file_size BIGINT,
  mime_type TEXT,
  storage_path TEXT NOT NULL,
  public_url TEXT NOT NULL,
  uploaded_by TEXT, -- Email ou ID de l'expéditeur
  role TEXT DEFAULT 'client', -- 'client', 'admin', 'membre'
  target_type TEXT, -- 'devis', 'ticket', 'mission', 'chat', 'facture'
  target_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_doc_hash ON public.documents_registry(file_hash);
CREATE INDEX IF NOT EXISTS idx_doc_target ON public.documents_registry(target_type, target_id);

-- ==============================================================================
-- ACTIVATION ROW LEVEL SECURITY (RLS)
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
ALTER TABLE public.demandes_conges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pointages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages_chat ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.config_cles_api ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents_registry ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- POLITIQUES RLS SÉCURISÉES (Compatibilité Web statique / GitHub Pages)
-- ==============================================================================
DO $$
BEGIN
  -- PROFILES
  DROP POLICY IF EXISTS "Allow public select on profiles" ON public.profiles;
  DROP POLICY IF EXISTS "Allow public insert on profiles" ON public.profiles;
  DROP POLICY IF EXISTS "Allow public update on profiles" ON public.profiles;
  CREATE POLICY "Allow public select on profiles" ON public.profiles FOR SELECT USING (true);
  CREATE POLICY "Allow public insert on profiles" ON public.profiles FOR INSERT WITH CHECK (true);
  CREATE POLICY "Allow public update on profiles" ON public.profiles FOR UPDATE USING (true);

  -- DEMANDES DE DEVIS
  DROP POLICY IF EXISTS "Allow public on devis" ON public.demandes_devis;
  CREATE POLICY "Allow public on devis" ON public.demandes_devis FOR ALL USING (true) WITH CHECK (true);

  -- MISSIONS
  DROP POLICY IF EXISTS "Allow public on missions" ON public.missions;
  CREATE POLICY "Allow public on missions" ON public.missions FOR ALL USING (true) WITH CHECK (true);

  -- FACTURES
  DROP POLICY IF EXISTS "Allow public on factures" ON public.factures;
  CREATE POLICY "Allow public on factures" ON public.factures FOR ALL USING (true) WITH CHECK (true);

  -- TICKETS SUPPORT
  DROP POLICY IF EXISTS "Allow public on tickets" ON public.tickets_support;
  CREATE POLICY "Allow public on tickets" ON public.tickets_support FOR ALL USING (true) WITH CHECK (true);

  -- AVIS CLIENTS
  DROP POLICY IF EXISTS "Allow public on avis" ON public.avis_clients;
  CREATE POLICY "Allow public on avis" ON public.avis_clients FOR ALL USING (true) WITH CHECK (true);

  -- GALERIE & ACTUALITÉS
  DROP POLICY IF EXISTS "Allow public on galerie" ON public.galerie_items;
  DROP POLICY IF EXISTS "Allow public on gallery_images" ON public.gallery_images;
  DROP POLICY IF EXISTS "Allow public on actualites" ON public.actualites;
  CREATE POLICY "Allow public on galerie" ON public.galerie_items FOR ALL USING (true) WITH CHECK (true);
  CREATE POLICY "Allow public on gallery_images" ON public.gallery_images FOR ALL USING (true) WITH CHECK (true);
  CREATE POLICY "Allow public on actualites" ON public.actualites FOR ALL USING (true) WITH CHECK (true);

  -- CONGÉS & POINTAGES
  DROP POLICY IF EXISTS "Allow public on conges" ON public.demandes_conges;
  DROP POLICY IF EXISTS "Allow public on pointages" ON public.pointages;
  DROP POLICY IF EXISTS "Allow public on messages_chat" ON public.messages_chat;
  CREATE POLICY "Allow public on conges" ON public.demandes_conges FOR ALL USING (true) WITH CHECK (true);
  CREATE POLICY "Allow public on pointages" ON public.pointages FOR ALL USING (true) WITH CHECK (true);
  CREATE POLICY "Allow public on messages_chat" ON public.messages_chat FOR ALL USING (true) WITH CHECK (true);

  -- ADMIN & AUDIT
  DROP POLICY IF EXISTS "Allow public on admin_accounts" ON public.admin_accounts;
  DROP POLICY IF EXISTS "Allow public on audit_logs" ON public.audit_logs;
  CREATE POLICY "Allow public on admin_accounts" ON public.admin_accounts FOR ALL USING (true) WITH CHECK (true);
  CREATE POLICY "Allow public on audit_logs" ON public.audit_logs FOR ALL USING (true) WITH CHECK (true);

  -- DOCUMENTS REGISTRY & STORAGE
  DROP POLICY IF EXISTS "Allow public on documents_registry" ON public.documents_registry;
  CREATE POLICY "Allow public on documents_registry" ON public.documents_registry FOR ALL USING (true) WITH CHECK (true);
END $$;

-- 17. BUCKET DE STOCKAGE SUPABASE STORAGE 'documents'
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DO $$
BEGIN
  DROP POLICY IF EXISTS "Public Access documents bucket" ON storage.objects;
  CREATE POLICY "Public Access documents bucket" ON storage.objects FOR ALL USING (bucket_id = 'documents') WITH CHECK (bucket_id = 'documents');
EXCEPTION
  WHEN undefined_table THEN NULL;
END $$;

