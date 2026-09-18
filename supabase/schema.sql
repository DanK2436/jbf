-- =============================================================
-- JBF SERVICES SARL — SCHÉMA DE BASE DE DONNÉES ENTERPRISE v9.0
-- Projet Supabase: https://dvzwqxcaiagczyonrhsg.supabase.co
-- Compatible: Web Public, Espace Client, Intranet Membre, Mobile
-- =============================================================

-- Extensions requises
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================
-- 1. TABLE DES PROFILS UTILISATEURS (CLIENTS, MEMBRES, ADMINS)
-- =============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR(150) UNIQUE NOT NULL,
  full_name VARCHAR(150),
  phone VARCHAR(50),
  company VARCHAR(150),
  secteur VARCHAR(100),
  section_id INT DEFAULT 1, -- 1 à 15 parmis les 15 services JBF
  section_nom VARCHAR(150) DEFAULT 'Fourniture de produits alimentaires',
  matricule VARCHAR(50),
  poste VARCHAR(150) DEFAULT 'Collaborateur',
  solde_conges INT DEFAULT 18,
  address TEXT,
  city VARCHAR(100),
  province VARCHAR(100) DEFAULT 'Haut-Katanga',
  role VARCHAR(50) DEFAULT 'client', -- 'client', 'membre', 'admin', 'direction'
  avatar_url TEXT,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Assurer la présence des colonnes si la table existait déjà
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS section_id INT DEFAULT 1;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS section_nom VARCHAR(150) DEFAULT 'Fourniture de produits alimentaires';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS matricule VARCHAR(50);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS poste VARCHAR(150) DEFAULT 'Collaborateur';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS solde_conges INT DEFAULT 18;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'client';

-- Index
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_section ON public.profiles(section_id);

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Les utilisateurs peuvent voir leur propre profil" ON public.profiles;
CREATE POLICY "Les utilisateurs peuvent voir leur propre profil"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leur propre profil" ON public.profiles;
CREATE POLICY "Les utilisateurs peuvent modifier leur propre profil"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Service Role a un acces complet aux profils" ON public.profiles;
CREATE POLICY "Service Role a un acces complet aux profils"
  ON public.profiles FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Trigger automatique auth.users -> public.profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    phone,
    company,
    secteur,
    section_id,
    section_nom,
    matricule,
    poste,
    solde_conges,
    address,
    city,
    province,
    role,
    is_verified
  )
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'phone',
    NEW.raw_user_meta_data->>'company',
    NEW.raw_user_meta_data->>'secteur',
    COALESCE((NEW.raw_user_meta_data->>'section_id')::INT, 1),
    COALESCE(NEW.raw_user_meta_data->>'section_nom', 'Fourniture de produits alimentaires'),
    NEW.raw_user_meta_data->>'matricule',
    COALESCE(NEW.raw_user_meta_data->>'poste', 'Collaborateur'),
    COALESCE((NEW.raw_user_meta_data->>'solde_conges')::INT, 18),
    NEW.raw_user_meta_data->>'address',
    NEW.raw_user_meta_data->>'city',
    NEW.raw_user_meta_data->>'province',
    COALESCE(NEW.raw_user_meta_data->>'role', 'client'),
    (NEW.email_confirmed_at IS NOT NULL)
  )
  ON CONFLICT (id) DO UPDATE
  SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
    phone = COALESCE(EXCLUDED.phone, profiles.phone),
    company = COALESCE(EXCLUDED.company, profiles.company),
    secteur = COALESCE(EXCLUDED.secteur, profiles.secteur),
    section_id = COALESCE(EXCLUDED.section_id, profiles.section_id),
    section_nom = COALESCE(EXCLUDED.section_nom, profiles.section_nom),
    matricule = COALESCE(EXCLUDED.matricule, profiles.matricule),
    poste = COALESCE(EXCLUDED.poste, profiles.poste),
    solde_conges = COALESCE(EXCLUDED.solde_conges, profiles.solde_conges),
    address = COALESCE(EXCLUDED.address, profiles.address),
    city = COALESCE(EXCLUDED.city, profiles.city),
    province = COALESCE(EXCLUDED.province, profiles.province),
    is_verified = (NEW.email_confirmed_at IS NOT NULL),
    updated_at = now();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- =============================================================
-- 2. TABLE DES DEMANDES DE DEVIS
-- =============================================================
CREATE TABLE IF NOT EXISTS public.demandes_devis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  nom VARCHAR(120) NOT NULL,
  societe VARCHAR(150),
  telephone VARCHAR(40) NOT NULL,
  email VARCHAR(150),
  services TEXT[] NOT NULL,
  localite VARCHAR(100) DEFAULT 'Lubumbashi',
  message TEXT,
  statut VARCHAR(30) DEFAULT 'nouveau',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Assurer client_id si la table existait déjà
ALTER TABLE public.demandes_devis ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_devis_statut ON public.demandes_devis(statut);
CREATE INDEX IF NOT EXISTS idx_devis_client ON public.demandes_devis(client_id);

ALTER TABLE public.demandes_devis ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Insertion publique des devis" ON public.demandes_devis;
CREATE POLICY "Insertion publique des devis"
  ON public.demandes_devis FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "Lecture des devis par auteur ou admin" ON public.demandes_devis;
CREATE POLICY "Lecture des devis par auteur ou admin"
  ON public.demandes_devis FOR SELECT
  USING (auth.uid() = client_id OR auth.uid() IN (SELECT id FROM public.profiles WHERE role IN ('admin', 'direction')));

-- =============================================================
-- 3. TABLE DES COMMANDES & DOSSIERS
-- =============================================================
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number VARCHAR(50) UNIQUE NOT NULL,
  client_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  service_id INT,
  description TEXT,
  location VARCHAR(150),
  attachments TEXT[] DEFAULT '{}',
  statut VARCHAR(30) DEFAULT 'en_attente',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_orders_client ON public.orders(client_id);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Clients voient leurs commandes" ON public.orders;
CREATE POLICY "Clients voient leurs commandes"
  ON public.orders FOR SELECT
  USING (auth.uid() = client_id OR auth.uid() IN (SELECT id FROM public.profiles WHERE role IN ('admin', 'direction')));

-- =============================================================
-- 4. TABLE DES MISSIONS TERRAIN (INTRANET MEMBRE)
-- =============================================================
CREATE TABLE IF NOT EXISTS public.missions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titre VARCHAR(200) NOT NULL,
  client VARCHAR(150) NOT NULL,
  site_intervention VARCHAR(150) NOT NULL,
  service_id INT DEFAULT 1,
  service_nom VARCHAR(120),
  date_debut TIMESTAMPTZ DEFAULT now(),
  date_fin TIMESTAMPTZ,
  description TEXT,
  assigned_to UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  statut VARCHAR(30) DEFAULT 'en_cours',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.missions ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.missions ADD COLUMN IF NOT EXISTS service_id INT DEFAULT 1;
ALTER TABLE public.missions ADD COLUMN IF NOT EXISTS service_nom VARCHAR(120);

CREATE INDEX IF NOT EXISTS idx_missions_assigned ON public.missions(assigned_to);
CREATE INDEX IF NOT EXISTS idx_missions_statut ON public.missions(statut);

ALTER TABLE public.missions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lecture des missions par assignation ou admin" ON public.missions;
CREATE POLICY "Lecture des missions par assignation ou admin"
  ON public.missions FOR SELECT
  USING (auth.uid() = assigned_to OR auth.uid() IN (SELECT id FROM public.profiles WHERE role IN ('admin', 'direction')));

DROP POLICY IF EXISTS "Gestion des missions par admin" ON public.missions;
CREATE POLICY "Gestion des missions par admin"
  ON public.missions FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =============================================================
-- 5. TABLE DES DEMANDES DE CONGÉS
-- =============================================================
CREATE TABLE IF NOT EXISTS public.demandes_conges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  agent_nom VARCHAR(120) NOT NULL,
  type_conge VARCHAR(50) DEFAULT 'Annuel',
  date_debut DATE NOT NULL,
  date_fin DATE NOT NULL,
  nombre_jours INT DEFAULT 1,
  motif TEXT,
  statut VARCHAR(30) DEFAULT 'en_attente',
  commentaire_admin TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.demandes_conges ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE public.demandes_conges ADD COLUMN IF NOT EXISTS nombre_jours INT DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_conges_user ON public.demandes_conges(user_id);
CREATE INDEX IF NOT EXISTS idx_conges_statut ON public.demandes_conges(statut);

ALTER TABLE public.demandes_conges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Les membres gerent leurs conges" ON public.demandes_conges;
CREATE POLICY "Les membres gerent leurs conges"
  ON public.demandes_conges FOR ALL
  USING (auth.uid() = user_id OR auth.uid() IN (SELECT id FROM public.profiles WHERE role IN ('admin', 'direction')))
  WITH CHECK (auth.uid() = user_id OR auth.uid() IN (SELECT id FROM public.profiles WHERE role IN ('admin', 'direction')));

-- =============================================================
-- 6. TABLE DU CHAT D'ÉQUIPE (GÉNÉRAL & SECTIONS 1-15)
-- =============================================================
CREATE TABLE IF NOT EXISTS public.messages_chat (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  expediteur_nom VARCHAR(120) NOT NULL,
  expediteur_avatar VARCHAR(10),
  canal_type VARCHAR(20) NOT NULL DEFAULT 'general',
  section_id INT,
  section_nom VARCHAR(120),
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.messages_chat ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.messages_chat ADD COLUMN IF NOT EXISTS canal_type VARCHAR(20) DEFAULT 'general';
ALTER TABLE public.messages_chat ADD COLUMN IF NOT EXISTS section_id INT;
ALTER TABLE public.messages_chat ADD COLUMN IF NOT EXISTS section_nom VARCHAR(120);

CREATE INDEX IF NOT EXISTS idx_chat_canal ON public.messages_chat(canal_type, section_id, created_at);

ALTER TABLE public.messages_chat ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lecture chat general ou de sa section" ON public.messages_chat;
CREATE POLICY "Lecture chat general ou de sa section"
  ON public.messages_chat FOR SELECT
  USING (
    canal_type = 'general' 
    OR (canal_type = 'section' AND (
      section_id IN (SELECT section_id FROM public.profiles WHERE id = auth.uid())
      OR auth.uid() IN (SELECT id FROM public.profiles WHERE role IN ('admin', 'direction'))
    ))
  );

DROP POLICY IF EXISTS "Envoi message chat authentifie" ON public.messages_chat;
CREATE POLICY "Envoi message chat authentifie"
  ON public.messages_chat FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- =============================================================
-- 7. TABLE DES RESSOURCES HSE
-- =============================================================
CREATE TABLE IF NOT EXISTS public.ressources_hse (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titre VARCHAR(200) NOT NULL,
  categorie VARCHAR(100) NOT NULL DEFAULT 'HSE & Sécurité',
  section_id INT DEFAULT 0,
  section_nom VARCHAR(120) DEFAULT 'Tous Services',
  description TEXT,
  fichier_url TEXT,
  type_fichier VARCHAR(30) DEFAULT 'PDF',
  taille VARCHAR(30) DEFAULT '2.5 MB',
  publie BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_hse_publie ON public.ressources_hse(publie, section_id);

ALTER TABLE public.ressources_hse ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lecture ressources HSE" ON public.ressources_hse;
CREATE POLICY "Lecture ressources HSE"
  ON public.ressources_hse FOR SELECT
  USING (publie = true);

-- =============================================================
-- 8. TABLE DE LA GALERIE (SITE PUBLIC)
-- =============================================================
CREATE TABLE IF NOT EXISTS public.gallery_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titre VARCHAR(200) NOT NULL,
  categorie VARCHAR(100) NOT NULL,
  localite VARCHAR(120),
  periode VARCHAR(100),
  description TEXT,
  impact TEXT,
  img_url TEXT NOT NULL,
  publie BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_gallery_publie ON public.gallery_images(publie, created_at);

ALTER TABLE public.gallery_images ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lecture publique de la galerie" ON public.gallery_images;
CREATE POLICY "Lecture publique de la galerie"
  ON public.gallery_images FOR SELECT
  USING (publie = true);

DROP POLICY IF EXISTS "Gestion galerie par admin" ON public.gallery_images;
CREATE POLICY "Gestion galerie par admin"
  ON public.gallery_images FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =============================================================
-- 9. TABLE DU BLOG (SITE PUBLIC)
-- =============================================================
CREATE TABLE IF NOT EXISTS public.blog_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titre VARCHAR(250) NOT NULL,
  categorie VARCHAR(100) NOT NULL,
  temps_lecture VARCHAR(50) DEFAULT '5 min de lecture',
  date_publication TIMESTAMPTZ DEFAULT now(),
  img_url TEXT,
  resume TEXT NOT NULL,
  contenu TEXT NOT NULL,
  publie BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_blog_publie ON public.blog_posts(publie, created_at);

ALTER TABLE public.blog_posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lecture publique du blog" ON public.blog_posts;
CREATE POLICY "Lecture publique du blog"
  ON public.blog_posts FOR SELECT
  USING (publie = true);

DROP POLICY IF EXISTS "Gestion blog par admin" ON public.blog_posts;
CREATE POLICY "Gestion blog par admin"
  ON public.blog_posts FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =============================================================
-- 10. TABLE DES AVIS CLIENTS
-- =============================================================
CREATE TABLE IF NOT EXISTS public.avis_clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  nom VARCHAR(120) NOT NULL,
  entreprise VARCHAR(150),
  service VARCHAR(100) NOT NULL,
  site VARCHAR(150),
  note INT CHECK (note >= 1 AND note <= 5) DEFAULT 5,
  commentaire TEXT NOT NULL,
  approuve BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.avis_clients ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE public.avis_clients ADD COLUMN IF NOT EXISTS site VARCHAR(150);

CREATE INDEX IF NOT EXISTS idx_avis_service ON public.avis_clients(service, approuve);
CREATE INDEX IF NOT EXISTS idx_avis_client ON public.avis_clients(client_id);

ALTER TABLE public.avis_clients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lecture publique des avis" ON public.avis_clients;
CREATE POLICY "Lecture publique des avis"
  ON public.avis_clients FOR SELECT
  USING (approuve = true);

DROP POLICY IF EXISTS "Insertion des avis clients" ON public.avis_clients;
CREATE POLICY "Insertion des avis clients"
  ON public.avis_clients FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "Gestion avis par admin" ON public.avis_clients;
CREATE POLICY "Gestion avis par admin"
  ON public.avis_clients FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Vue de compatibilité public.avis
CREATE OR REPLACE VIEW public.avis AS SELECT * FROM public.avis_clients;

-- =============================================================
-- 11. TABLE DES COMPTES ADMINISTRATEURS (SOUS-ADMINS)
-- =============================================================
CREATE TABLE IF NOT EXISTS public.admin_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name VARCHAR(150) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  phone VARCHAR(50),
  role VARCHAR(30) DEFAULT 'sous_admin', -- 'super_admin', 'sous_admin'
  permissions TEXT[] DEFAULT ARRAY['dashboard'],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_accounts_email ON public.admin_accounts(email);
CREATE INDEX IF NOT EXISTS idx_admin_accounts_role ON public.admin_accounts(role);

ALTER TABLE public.admin_accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service Role gere les comptes admin" ON public.admin_accounts;
CREATE POLICY "Service Role gere les comptes admin"
  ON public.admin_accounts FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Acces admin aux comptes" ON public.admin_accounts;
CREATE POLICY "Acces admin aux comptes"
  ON public.admin_accounts FOR ALL
  USING (auth.uid() IN (SELECT id FROM public.profiles WHERE role IN ('admin', 'direction')))
  WITH CHECK (auth.uid() IN (SELECT id FROM public.profiles WHERE role IN ('admin', 'direction')));

-- INSERT initial super admin
INSERT INTO public.admin_accounts (full_name, email, phone, role, permissions)
VALUES ('Direction Générale JBF', 'direction@jbf-services.cd', '+243 81 000 0000', 'super_admin', ARRAY['*'])
ON CONFLICT (email) DO NOTHING;

-- =============================================================
-- 12. TABLE DES TICKETS SUPPORT CLIENT
-- =============================================================
CREATE TABLE IF NOT EXISTS public.tickets_support (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  client_nom VARCHAR(150) NOT NULL,
  client_telephone VARCHAR(50),
  client_email VARCHAR(150),
  sujet VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  canal VARCHAR(30) DEFAULT 'whatsapp', -- 'whatsapp', 'email', 'telephone', 'web'
  statut VARCHAR(30) DEFAULT 'ouvert', -- 'ouvert', 'en_traitement', 'resolu', 'ferme'
  priorite VARCHAR(20) DEFAULT 'normale', -- 'basse', 'normale', 'haute', 'urgente'
  reponse_admin TEXT,
  assigned_to UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.tickets_support ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_tickets_statut ON public.tickets_support(statut, created_at);
CREATE INDEX IF NOT EXISTS idx_tickets_canal ON public.tickets_support(canal);
CREATE INDEX IF NOT EXISTS idx_tickets_client ON public.tickets_support(client_id);

ALTER TABLE public.tickets_support ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service Role gere les tickets" ON public.tickets_support;
CREATE POLICY "Service Role gere les tickets"
  ON public.tickets_support FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Admins lisent et gerent les tickets" ON public.tickets_support;
CREATE POLICY "Admins lisent et gerent les tickets"
  ON public.tickets_support FOR ALL
  USING (auth.uid() IN (SELECT id FROM public.profiles WHERE role IN ('admin', 'direction')))
  WITH CHECK (auth.uid() IN (SELECT id FROM public.profiles WHERE role IN ('admin', 'direction')));

DROP POLICY IF EXISTS "Insertion publique des tickets" ON public.tickets_support;
CREATE POLICY "Insertion publique des tickets"
  ON public.tickets_support FOR INSERT
  WITH CHECK (true);

-- =============================================================
-- 13. TABLE DES DEVIS TRANSMIS PAR LES CHEFS D'ÉQUIPE
-- =============================================================
CREATE TABLE IF NOT EXISTS public.devis_equipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  demande_devis_id UUID REFERENCES public.demandes_devis(id) ON DELETE SET NULL,
  chef_equipe_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  chef_equipe_nom VARCHAR(150) NOT NULL,
  client_nom VARCHAR(150) NOT NULL,
  client_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  titre VARCHAR(200) NOT NULL,
  domaine VARCHAR(120),
  montant_estime NUMERIC(12, 2) DEFAULT 0.00,
  monnaie VARCHAR(10) DEFAULT 'USD',
  document_url TEXT,
  document_nom VARCHAR(200),
  document_type VARCHAR(50) DEFAULT 'PDF',
  commentaires TEXT,
  statut VARCHAR(30) DEFAULT 'transmis_admin', -- 'transmis_admin', 'envoye_client', 'valide_client'
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_devis_equipes_statut ON public.devis_equipes(statut);
CREATE INDEX IF NOT EXISTS idx_devis_equipes_chef ON public.devis_equipes(chef_equipe_id);

ALTER TABLE public.devis_equipes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Chefs d equipe voient et creent leurs devis" ON public.devis_equipes;
CREATE POLICY "Chefs d equipe voient et creent leurs devis"
  ON public.devis_equipes FOR ALL
  USING (auth.uid() = chef_equipe_id OR auth.uid() IN (SELECT id FROM public.profiles WHERE role IN ('admin', 'direction')))
  WITH CHECK (auth.uid() = chef_equipe_id OR auth.uid() IN (SELECT id FROM public.profiles WHERE role IN ('admin', 'direction')));

DROP POLICY IF EXISTS "Clients voient leurs devis valides transmis" ON public.devis_equipes;
CREATE POLICY "Clients voient leurs devis valides transmis"
  ON public.devis_equipes FOR SELECT
  USING (auth.uid() = client_id AND statut IN ('envoye_client', 'valide_client'));

