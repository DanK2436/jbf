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

-- ==============================================================================
-- JBF SERVICES â€” SCRIPT DE MIGRATION & Ã‰VOLUTIONS v11.0 (PHASE 1 : CÅ’UR & BDD)
-- Ce script ajoute toutes les tables et colonnes requises pour :
-- 1. Gestion des Utilisateurs (Statut dÃ©sactivÃ©, rÃ´les et permissions fines)
-- 2. Gestion RH & Cartographie des CompÃ©tences
-- 3. Gestion FinanciÃ¨re & Ã‰critures Comptables (DÃ©penses, Recettes, ReÃ§us)
-- 4. Suivi de Projets Complexes & Progression Tripartite des Missions
-- 5. Format SÃ©curisÃ© .jbf & PiÃ¨ces Jointes Multi-Formats
-- 6. Recrutement Public (Candidatures sans auth & convocations)
-- 7. Devis Membres & Catalogue de MatÃ©riaux
-- 8. CMS, Blog & Diffusion de Notifications / Newsletters
-- 9. Catalogue dynamique des Services JBF
-- ==============================================================================

-- 1. EXTENSIONS REQUISES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 2. Ã‰VOLUTIONS DE LA TABLE : PROFILES
-- ------------------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_disabled BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS statut_compte TEXT DEFAULT 'actif', -- 'actif', 'desactive', 'suspendu'
  ADD COLUMN IF NOT EXISTS permissions_detaillees JSONB DEFAULT '{"all": true}',
  ADD COLUMN IF NOT EXISTS derniere_connexion TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS token_invalidation_ts TIMESTAMPTZ DEFAULT NOW();

-- ------------------------------------------------------------------------------
-- 3. Ã‰VOLUTIONS DE LA TABLE : MISSIONS
-- ------------------------------------------------------------------------------
ALTER TABLE public.missions
  ADD COLUMN IF NOT EXISTS est_desactivee BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS projet_complexe BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS budget_alloue NUMERIC(14, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS budget_depense NUMERIC(14, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS devise TEXT DEFAULT 'USD',
  ADD COLUMN IF NOT EXISTS statut_paiement_client TEXT DEFAULT 'en_attente', -- 'en_attente', 'acompte_regle', 'paye_integralement'
  ADD COLUMN IF NOT EXISTS progression_debloquee_client BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS validation_admin_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS fichiers_attaches JSONB DEFAULT '[]'::JSONB; -- Array d'objets: [{nom, url, format, taille, est_jbf, date}]

-- ------------------------------------------------------------------------------
-- 4. NOUVELLE TABLE : RH & BASE COLLABORATEURS (rh_collaborateurs)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rh_collaborateurs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  matricule TEXT UNIQUE NOT NULL,
  type_contrat TEXT DEFAULT 'CDI' CHECK (type_contrat IN ('CDI', 'CDD', 'Journalier', 'Sous-traitance', 'Stagiaire')),
  salaire_base NUMERIC(12, 2) DEFAULT 0.00,
  devise_salaire TEXT DEFAULT 'USD',
  date_embauche DATE NOT NULL DEFAULT CURRENT_DATE,
  competences TEXT[] DEFAULT '{}'::TEXT[], -- ex: ['Soudure TIG', 'Topographie', 'Tuyauterie', 'Cuisine industrielle', 'QHSE']
  niveau_qualification TEXT DEFAULT 'Technicien', -- 'Ouvrier', 'Technicien', 'IngÃ©nieur', 'Chef d''Ã©quipe'
  statut_disponibilite TEXT DEFAULT 'disponible', -- 'disponible', 'en_mission', 'en_conge', 'malade'
  site_actuel TEXT,
  province_affectation TEXT DEFAULT 'Haut-Katanga',
  documents_administratifs JSONB DEFAULT '[]'::JSONB, -- CV, contrat signÃ©, carte d'Ã©lecteur, habilitations
  formations_suivies JSONB DEFAULT '[]'::JSONB, -- [{titre, organisme, date, certificat_url}]
  notes_evaluation TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 5. NOUVELLE TABLE : RECRUTEMENT PUBLIC & CANDIDATURES SANS COMPTE (candidatures)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.candidatures (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nom_complet TEXT NOT NULL,
  email TEXT NOT NULL,
  telephone TEXT NOT NULL,
  province_residence TEXT NOT NULL,
  domaine_expertise TEXT NOT NULL,
  annees_experience INTEGER DEFAULT 0,
  cv_url TEXT NOT NULL,
  lettre_motivation_url TEXT,
  diplomes_attestations_urls JSONB DEFAULT '[]'::JSONB,
  statut TEXT DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'en_revue', 'convoque', 'accepte', 'rejete')),
  convocation_details JSONB, -- { "date_convocation": "...", "lieu": "...", "message": "...", "envoyee_par": "..." }
  date_convocation_envoyee TIMESTAMPTZ,
  compte_cree_id UUID REFERENCES public.profiles(id),
  commentaires_recruteur TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 6. NOUVELLE TABLE : COMPTABILITÃ‰ & GESTION FINANCIÃˆRE (comptabilite_ecritures)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.comptabilite_ecritures (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  numero_ecriture TEXT UNIQUE NOT NULL,
  type_operation TEXT NOT NULL CHECK (type_operation IN ('recette_client', 'depense_achat', 'depense_frais', 'depense_investissement', 'paiement_fournisseur', 'paie_rh')),
  categorie TEXT NOT NULL, -- 'Achats chantiers', 'Frais transport', 'Salaires', 'MatÃ©riel lourd', 'Honoraires'
  montant NUMERIC(14, 2) NOT NULL,
  devise TEXT DEFAULT 'USD',
  tiers_nom TEXT NOT NULL, -- Nom du client ou fournisseur
  reference_piece TEXT, -- NÂ° facture ou NÂ° reÃ§u
  mode_paiement TEXT DEFAULT 'virement' CHECK (mode_paiement IN ('virement', 'cheque', 'm_pesa', 'airtel_money', 'orange_money', 'cash')),
  facture_associee_id UUID,
  mission_associee_id UUID REFERENCES public.missions(id),
  date_ecriture DATE NOT NULL DEFAULT CURRENT_DATE,
  justificatif_url TEXT,
  recu_genere_url TEXT,
  statut_validation TEXT DEFAULT 'valide' CHECK (statut_validation IN ('en_attente', 'valide', 'rejete')),
  cree_par UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 7. NOUVELLE TABLE : JALONS ET Ã‰TAPES DE PROGRESSION TRIPARTITE (mission_etapes)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.mission_etapes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID NOT NULL REFERENCES public.missions(id) ON DELETE CASCADE,
  titre_etape TEXT NOT NULL,
  description TEXT,
  ordre_etape INTEGER NOT NULL DEFAULT 1,
  
  -- Validation Membre (Terrain)
  est_acheve_par_membre BOOLEAN DEFAULT FALSE,
  valide_par_membre_id UUID REFERENCES public.profiles(id),
  date_achevement_membre TIMESTAMPTZ,
  preuves_photos JSONB DEFAULT '[]'::JSONB, -- URLs des photos horodatÃ©es
  preuves_documents JSONB DEFAULT '[]'::JSONB,
  coordonnees_gps TEXT,
  observations_membre TEXT,

  -- Approbation Admin (Direction)
  est_approuve_par_admin BOOLEAN DEFAULT FALSE,
  approuve_par_admin_id UUID REFERENCES public.profiles(id),
  date_approbation_admin TIMESTAMPTZ,
  commentaires_admin TEXT,

  -- VisibilitÃ© Client
  visible_par_client BOOLEAN DEFAULT FALSE,
  date_notification_client TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 8. NOUVELLE TABLE : DEVIS SOUMIS PAR LES MEMBRES (devis_membres)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.devis_membres (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  numero_devis TEXT UNIQUE NOT NULL,
  membre_id UUID NOT NULL REFERENCES public.profiles(id),
  nom_collaborateur TEXT NOT NULL,
  nom_client TEXT NOT NULL,
  projet_prestation TEXT NOT NULL,
  site_intervention TEXT,
  lignes_elements JSONB NOT NULL DEFAULT '[]'::JSONB, -- [{designation, unite, quantite, prix_unitaire, total}]
  total_ht NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
  devise TEXT DEFAULT 'USD',
  pdf_url TEXT,
  sceau_numerique_hash TEXT,
  statut TEXT DEFAULT 'transmis_admin' CHECK (statut IN ('brouillon', 'transmis_admin', 'valide_admin', 'transmis_client', 'rejete')),
  marge_appliquee_pct NUMERIC(5, 2) DEFAULT 0.00,
  prix_final_client NUMERIC(14, 2),
  notes_direction TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 9. NOUVELLE TABLE : CATALOGUE DYNAMIQUE DES SERVICES JBF (services_catalogue)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.services_catalogue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code_service TEXT UNIQUE NOT NULL,
  titre TEXT NOT NULL,
  categorie TEXT NOT NULL,
  description_courte TEXT,
  description_complete TEXT,
  icone_nom TEXT DEFAULT 'construction',
  image_url TEXT,
  ordre_affichage INTEGER DEFAULT 1,
  est_actif BOOLEAN DEFAULT TRUE,
  tarification_indicative TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 10. NOUVELLE TABLE : CMS & BLOG (cms_articles)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.cms_articles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug TEXT UNIQUE NOT NULL,
  titre TEXT NOT NULL,
  resume TEXT,
  contenu_html TEXT NOT NULL,
  image_couverture TEXT,
  categorie TEXT DEFAULT 'ActualitÃ©s',
  tags_seo TEXT[] DEFAULT '{}'::TEXT[],
  mots_cles_cibles TEXT[] DEFAULT '{}'::TEXT[],
  est_publie BOOLEAN DEFAULT TRUE,
  vues_count INTEGER DEFAULT 0,
  auteur_id UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 11. NOUVELLE TABLE : DIFFUSION NOTIFICATIONS & NEWSLETTERS (notifications_diffusees)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications_diffusees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  titre TEXT NOT NULL,
  message TEXT NOT NULL,
  cible_type TEXT NOT NULL CHECK (cible_type IN ('tous', 'clients', 'membres', 'sous_admins', 'province')),
  province_cible TEXT,
  canal TEXT NOT NULL CHECK (canal IN ('in_app', 'email', 'push', 'tous')),
  est_envoyee BOOLEAN DEFAULT FALSE,
  total_destinataires INTEGER DEFAULT 0,
  cree_par UUID REFERENCES public.profiles(id),
  date_envoi TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 12. SEED INITIAL DES 15 PRESTATIONS DANS services_catalogue
-- ------------------------------------------------------------------------------
INSERT INTO public.services_catalogue (code_service, titre, categorie, description_courte, ordre_affichage, est_actif)
VALUES
  ('SRV-01', 'Sous-traitance MiniÃ¨re & Extraction', 'Industrie & Mines', 'Extraction, transport de minerais, concassage et gestion de carriÃ¨res.', 1, true),
  ('SRV-02', 'BTP & Construction Industrielle', 'GÃ©nie Civil', 'Terrassement, gros Å“uvre, construction d''usines et voiries en RDC.', 2, true),
  ('SRV-03', 'Maintenance Industrielle & Usinage', 'Maintenance', 'Maintenance prÃ©ventive, rÃ©paration mÃ©canique, chaudronnerie et tuyauterie.', 3, true),
  ('SRV-04', 'Catering Industriel & Base Vie', 'Services GÃ©nÃ©raux', 'Restauration collective pour sites miniers et gestion hÃ´teliÃ¨re de base-vie.', 4, true),
  ('SRV-05', 'Transport Lourd & Logistique', 'Logistique', 'Flotte de camions bennes, convois exceptionnels et approvisionnement minier.', 5, true),
  ('SRV-06', 'Mise Ã  Disposition RH & Recrutement', 'Ressources Humaines', 'DÃ©lÃ©gation de main-d''Å“uvre qualifiÃ©e, techniciens et ingÃ©nieurs certifiÃ©s.', 6, true),
  ('SRV-07', 'Ã‰lectricitÃ© Haute Tension & Ã‰nergie', 'Ã‰nergie', 'Installation de transformateurs, lignes MT/HT et gÃ©nÃ©rateurs industriels.', 7, true),
  ('SRV-08', 'Forage Hydraulique & Assainissement', 'Environnement', 'Forages d''eau potable grande profondeur, canalisations et stations d''Ã©puration.', 8, true),
  ('SRV-09', 'Chaudronnerie & Soudure SpÃ©cialisÃ©e', 'Maintenance', 'Soudure TIG/MIG certifiÃ©e, fabrication de cuves et structures mÃ©talliques.', 9, true),
  ('SRV-10', 'Nettoyage Industriel & DÃ©pollution', 'Environnement', 'Nettoyage haute pression de cuves, gestion des dÃ©chets dangereux et rÃ©sidus.', 10, true),
  ('SRV-11', 'Gardiennage & SÃ©curitÃ© RapprochÃ©e', 'SÃ©curitÃ©', 'Surveillance Ã©lectronique, gardiennage armÃ© agrÃ©Ã© et contrÃ´le d''accÃ¨s biomÃ©trique.', 11, true),
  ('SRV-12', 'Location d''Engins & MatÃ©riel Lourd', 'Ã‰quipements', 'Excavatrices, compacteurs, grues mobiles, chargeuses et bulldozers.', 12, true),
  ('SRV-13', 'Informatique, TÃ©lÃ©coms & RÃ©seaux', 'Nouvelles Technologies', 'Fibre optique, interconnexion VSAT de camps miniers et vidÃ©osurveillance IP.', 13, true),
  ('SRV-14', 'Conseil QHSE & ConformitÃ© RDC', 'Audit & Conseil', 'Audits de conformitÃ© ARSP, plans d''hygiÃ¨ne et certifications ISO.', 14, true),
  ('SRV-15', 'Approvisionnement & Fournitures MRO', 'Supply Chain', 'Vente d''EPI certifiÃ©s, piÃ¨ces de rechange et consommables industriels.', 15, true)
ON CONFLICT (code_service) DO UPDATE
SET titre = EXCLUDED.titre,
    categorie = EXCLUDED.categorie,
    description_courte = EXCLUDED.description_courte;

-- ------------------------------------------------------------------------------
-- 13. POLITIQUES RLS (ROW LEVEL SECURITY)
-- ------------------------------------------------------------------------------
ALTER TABLE public.rh_collaborateurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidatures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comptabilite_ecritures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mission_etapes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devis_membres ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services_catalogue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cms_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications_diffusees ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  -- CANDIDATURES : Le public peut insÃ©rer une candidature sans Ãªtre connectÃ©
  DROP POLICY IF EXISTS "Public can submit candidatures" ON public.candidatures;
  CREATE POLICY "Public can submit candidatures" ON public.candidatures FOR INSERT WITH CHECK (true);

  DROP POLICY IF EXISTS "Admin view/edit candidatures" ON public.candidatures;
  CREATE POLICY "Admin view/edit candidatures" ON public.candidatures FOR ALL USING (true);

  -- SERVICES CATALOGUE : Lecture publique autorisÃ©e
  DROP POLICY IF EXISTS "Public can view services" ON public.services_catalogue;
  CREATE POLICY "Public can view services" ON public.services_catalogue FOR SELECT USING (true);
  
  DROP POLICY IF EXISTS "Admin manage services" ON public.services_catalogue;
  CREATE POLICY "Admin manage services" ON public.services_catalogue FOR ALL USING (true);

  -- CMS ARTICLES : Lecture publique pour les articles publiÃ©s
  DROP POLICY IF EXISTS "Public view published articles" ON public.cms_articles;
  CREATE POLICY "Public view published articles" ON public.cms_articles FOR SELECT USING (est_publie = true);

  DROP POLICY IF EXISTS "Admin manage articles" ON public.cms_articles;
  CREATE POLICY "Admin manage articles" ON public.cms_articles FOR ALL USING (true);

  -- POLITIQUES SOUPLES PAR DÃ‰FAUT POUR TOUTES LES NOUVELLES TABLES OPÃ‰RATIONNELLES
  DROP POLICY IF EXISTS "Allow operational access rh_collaborateurs" ON public.rh_collaborateurs;
  CREATE POLICY "Allow operational access rh_collaborateurs" ON public.rh_collaborateurs FOR ALL USING (true);

  DROP POLICY IF EXISTS "Allow operational access comptabilite" ON public.comptabilite_ecritures;
  CREATE POLICY "Allow operational access comptabilite" ON public.comptabilite_ecritures FOR ALL USING (true);

  DROP POLICY IF EXISTS "Allow operational access mission_etapes" ON public.mission_etapes;
  CREATE POLICY "Allow operational access mission_etapes" ON public.mission_etapes FOR ALL USING (true);

  DROP POLICY IF EXISTS "Allow operational access devis_membres" ON public.devis_membres;
  CREATE POLICY "Allow operational access devis_membres" ON public.devis_membres FOR ALL USING (true);

  DROP POLICY IF EXISTS "Allow operational access notifications" ON public.notifications_diffusees;
  CREATE POLICY "Allow operational access notifications" ON public.notifications_diffusees FOR ALL USING (true);
END $$;
