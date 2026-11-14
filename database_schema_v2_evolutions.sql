-- ==============================================================================
-- JBF SERVICES — SCRIPT DE MIGRATION & ÉVOLUTIONS v11.0 (PHASE 1 : CŒUR & BDD)
-- Ce script ajoute toutes les tables et colonnes requises pour :
-- 1. Gestion des Utilisateurs (Statut désactivé, rôles et permissions fines)
-- 2. Gestion RH & Cartographie des Compétences
-- 3. Gestion Financière & Écritures Comptables (Dépenses, Recettes, Reçus)
-- 4. Suivi de Projets Complexes & Progression Tripartite des Missions
-- 5. Format Sécurisé .jbf & Pièces Jointes Multi-Formats
-- 6. Recrutement Public (Candidatures sans auth & convocations)
-- 7. Devis Membres & Catalogue de Matériaux
-- 8. CMS, Blog & Diffusion de Notifications / Newsletters
-- 9. Catalogue dynamique des Services JBF
-- ==============================================================================

-- 1. EXTENSIONS REQUISES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 2. ÉVOLUTIONS DE LA TABLE : PROFILES
-- ------------------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_disabled BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS statut_compte TEXT DEFAULT 'actif', -- 'actif', 'desactive', 'suspendu'
  ADD COLUMN IF NOT EXISTS permissions_detaillees JSONB DEFAULT '{"all": true}',
  ADD COLUMN IF NOT EXISTS derniere_connexion TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS token_invalidation_ts TIMESTAMPTZ DEFAULT NOW();

-- ------------------------------------------------------------------------------
-- 3. ÉVOLUTIONS DE LA TABLE : MISSIONS
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
  niveau_qualification TEXT DEFAULT 'Technicien', -- 'Ouvrier', 'Technicien', 'Ingénieur', 'Chef d''équipe'
  statut_disponibilite TEXT DEFAULT 'disponible', -- 'disponible', 'en_mission', 'en_conge', 'malade'
  site_actuel TEXT,
  province_affectation TEXT DEFAULT 'Haut-Katanga',
  documents_administratifs JSONB DEFAULT '[]'::JSONB, -- CV, contrat signé, carte d'électeur, habilitations
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
-- 6. NOUVELLE TABLE : COMPTABILITÉ & GESTION FINANCIÈRE (comptabilite_ecritures)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.comptabilite_ecritures (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  numero_ecriture TEXT UNIQUE NOT NULL,
  type_operation TEXT NOT NULL CHECK (type_operation IN ('recette_client', 'depense_achat', 'depense_frais', 'depense_investissement', 'paiement_fournisseur', 'paie_rh')),
  categorie TEXT NOT NULL, -- 'Achats chantiers', 'Frais transport', 'Salaires', 'Matériel lourd', 'Honoraires'
  montant NUMERIC(14, 2) NOT NULL,
  devise TEXT DEFAULT 'USD',
  tiers_nom TEXT NOT NULL, -- Nom du client ou fournisseur
  reference_piece TEXT, -- N° facture ou N° reçu
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
-- 7. NOUVELLE TABLE : JALONS ET ÉTAPES DE PROGRESSION TRIPARTITE (mission_etapes)
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
  preuves_photos JSONB DEFAULT '[]'::JSONB, -- URLs des photos horodatées
  preuves_documents JSONB DEFAULT '[]'::JSONB,
  coordonnees_gps TEXT,
  observations_membre TEXT,

  -- Approbation Admin (Direction)
  est_approuve_par_admin BOOLEAN DEFAULT FALSE,
  approuve_par_admin_id UUID REFERENCES public.profiles(id),
  date_approbation_admin TIMESTAMPTZ,
  commentaires_admin TEXT,

  -- Visibilité Client
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
  categorie TEXT DEFAULT 'Actualités',
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
  ('SRV-01', 'Sous-traitance Minière & Extraction', 'Industrie & Mines', 'Extraction, transport de minerais, concassage et gestion de carrières.', 1, true),
  ('SRV-02', 'BTP & Construction Industrielle', 'Génie Civil', 'Terrassement, gros œuvre, construction d''usines et voiries en RDC.', 2, true),
  ('SRV-03', 'Maintenance Industrielle & Usinage', 'Maintenance', 'Maintenance préventive, réparation mécanique, chaudronnerie et tuyauterie.', 3, true),
  ('SRV-04', 'Catering Industriel & Base Vie', 'Services Généraux', 'Restauration collective pour sites miniers et gestion hôtelière de base-vie.', 4, true),
  ('SRV-05', 'Transport Lourd & Logistique', 'Logistique', 'Flotte de camions bennes, convois exceptionnels et approvisionnement minier.', 5, true),
  ('SRV-06', 'Mise à Disposition RH & Recrutement', 'Ressources Humaines', 'Délégation de main-d''œuvre qualifiée, techniciens et ingénieurs certifiés.', 6, true),
  ('SRV-07', 'Électricité Haute Tension & Énergie', 'Énergie', 'Installation de transformateurs, lignes MT/HT et générateurs industriels.', 7, true),
  ('SRV-08', 'Forage Hydraulique & Assainissement', 'Environnement', 'Forages d''eau potable grande profondeur, canalisations et stations d''épuration.', 8, true),
  ('SRV-09', 'Chaudronnerie & Soudure Spécialisée', 'Maintenance', 'Soudure TIG/MIG certifiée, fabrication de cuves et structures métalliques.', 9, true),
  ('SRV-10', 'Nettoyage Industriel & Dépollution', 'Environnement', 'Nettoyage haute pression de cuves, gestion des déchets dangereux et résidus.', 10, true),
  ('SRV-11', 'Gardiennage & Sécurité Rapprochée', 'Sécurité', 'Surveillance électronique, gardiennage armé agréé et contrôle d''accès biométrique.', 11, true),
  ('SRV-12', 'Location d''Engins & Matériel Lourd', 'Équipements', 'Excavatrices, compacteurs, grues mobiles, chargeuses et bulldozers.', 12, true),
  ('SRV-13', 'Informatique, Télécoms & Réseaux', 'Nouvelles Technologies', 'Fibre optique, interconnexion VSAT de camps miniers et vidéosurveillance IP.', 13, true),
  ('SRV-14', 'Conseil QHSE & Conformité RDC', 'Audit & Conseil', 'Audits de conformité ARSP, plans d''hygiène et certifications ISO.', 14, true),
  ('SRV-15', 'Approvisionnement & Fournitures MRO', 'Supply Chain', 'Vente d''EPI certifiés, pièces de rechange et consommables industriels.', 15, true)
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
  -- CANDIDATURES : Le public peut insérer une candidature sans être connecté
  DROP POLICY IF EXISTS "Public can submit candidatures" ON public.candidatures;
  CREATE POLICY "Public can submit candidatures" ON public.candidatures FOR INSERT WITH CHECK (true);

  DROP POLICY IF EXISTS "Admin view/edit candidatures" ON public.candidatures;
  CREATE POLICY "Admin view/edit candidatures" ON public.candidatures FOR ALL USING (true);

  -- SERVICES CATALOGUE : Lecture publique autorisée
  DROP POLICY IF EXISTS "Public can view services" ON public.services_catalogue;
  CREATE POLICY "Public can view services" ON public.services_catalogue FOR SELECT USING (true);
  
  DROP POLICY IF EXISTS "Admin manage services" ON public.services_catalogue;
  CREATE POLICY "Admin manage services" ON public.services_catalogue FOR ALL USING (true);

  -- CMS ARTICLES : Lecture publique pour les articles publiés
  DROP POLICY IF EXISTS "Public view published articles" ON public.cms_articles;
  CREATE POLICY "Public view published articles" ON public.cms_articles FOR SELECT USING (est_publie = true);

  DROP POLICY IF EXISTS "Admin manage articles" ON public.cms_articles;
  CREATE POLICY "Admin manage articles" ON public.cms_articles FOR ALL USING (true);

  -- POLITIQUES SOUPLES PAR DÉFAUT POUR TOUTES LES NOUVELLES TABLES OPÉRATIONNELLES
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
