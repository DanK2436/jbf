-- ==============================================================================
-- JBF SERVICE — ÉVOLUTION SCHEMA V3 : FAQ & CATALOGUE DYNAMIQUE DES SERVICES
-- UTF-8 SANS CARACTÈRES CORROMPUS
-- ==============================================================================

-- 1. TABLE : FOIRE AUX QUESTIONS (faq_items)
CREATE TABLE IF NOT EXISTS public.faq_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question TEXT NOT NULL,
  reponse TEXT NOT NULL,
  categorie TEXT NOT NULL DEFAULT 'Général',
  ordre_affichage INTEGER DEFAULT 1,
  est_actif BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. ENRICHISSEMENT TABLE SERVICES CATALOGUE
ALTER TABLE public.services_catalogue ADD COLUMN IF NOT EXISTS points_forts TEXT;
ALTER TABLE public.services_catalogue ADD COLUMN IF NOT EXISTS certifications TEXT;
ALTER TABLE public.services_catalogue ADD COLUMN IF NOT EXISTS delai_mobilisation TEXT;

-- 3. POLITIQUES RLS (ROW LEVEL SECURITY)
ALTER TABLE public.faq_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services_catalogue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view active faq" ON public.faq_items;
CREATE POLICY "Public can view active faq" ON public.faq_items FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin manage faq" ON public.faq_items;
CREATE POLICY "Admin manage faq" ON public.faq_items FOR ALL USING (true);

DROP POLICY IF EXISTS "Public can view services" ON public.services_catalogue;
CREATE POLICY "Public can view services" ON public.services_catalogue FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin manage services" ON public.services_catalogue;
CREATE POLICY "Admin manage services" ON public.services_catalogue FOR ALL USING (true);

-- 4. SEED INITIAL OFFICIEL DES 12 QUESTIONS FAQ
INSERT INTO public.faq_items (question, reponse, categorie, ordre_affichage, est_actif)
VALUES
  (
    'Quel est le délai de transmission d''un devis commercial chiffré ?',
    'Toute demande de cotation soumise via notre site web ou par courriel officiel fait l''objet d''un accusé de réception immédiat. Nos ingénieurs d''affaires et métreurs vous transmettent une proposition technique et financière détaillée sous un délai garanti de 24 heures ouvrables pour les demandes courantes (gardiennage, catering, mise à disposition de main-d''œuvre) et sous 48 heures pour les chantiers complexes de génie civil ou de maintenance d''usine nécessitant une étude d''ingénierie préliminaire.',
    'devis',
    1,
    true
  ),
  (
    'Quelles sont vos modalités de facturation et devises acceptées ?',
    'Nos conditions de règlement sont parfaitement adaptées aux standards industriels et miniers : Contrats récurrents (catering, gardiennage, maintenance) : Facturation mensuelle à terme échu sur la base des états de présence ou situations de travaux validées. Missions ponctuelles (BTP, arrêts d''usines, convoyage) : Acompte de mobilisation (30% à 50%) puis solde à réception définitive des livrables. Les paiements sont acceptés par virement bancaire sécurisé en USD ou en Francs Congolais (CDF) sur nos comptes bancaires d''entreprise domiciliés en RDC.',
    'devis',
    2,
    true
  ),
  (
    'Proposez-vous des contrats-cadres pluriannuels avec des remises de volume ?',
    'Oui. Pour les grands donneurs d''ordres industriels et miniers engageant des volumes réguliers ou combinant plusieurs de nos 15 prestations (ex: Gestion globale de camp de vie + Gardiennage + Catering), nous mettons en place des contrats-cadres de sous-traitance pluriannuels. Ces accords confèrent des tarifs préférentiels dégressifs, des engagements de niveau de service (SLA chiffrés) et la désignation d''un Directeur de Compte dédié joignable 24h/24.',
    'devis',
    3,
    true
  ),
  (
    'Dans quelles provinces de la RDC vos équipes peuvent-elles intervenir ?',
    'JBF Service possède une capacité de projection opérationnelle sur l''ensemble des 26 provinces de la République Démocratique du Congo. Grâce à nos bases et hubs logistiques établis à Lubumbashi (Haut-Katanga), Kolwezi (Lualaba) et Kinshasa, nous approvisionnons et déployons nos brigades techniques jusque dans les sites miniers les plus enclavés (Kibali, Tenke, Kamoa, Doko, Matadi, etc.).',
    'terrain',
    4,
    true
  ),
  (
    'Quel est le délai moyen de mobilisation d''équipes sur site ?',
    'Nos délais de déploiement sont parmi les plus compétitifs du marché congolais : Interventions d''urgence (soudure, maintenance, renfort de sécurité) : Mobilisation sous 12 à 24 heures. Déploiements complets de brigades (équipes de catering de 500 repas/jour, régie BTP, gardiennage de site) : Mobilisation complète sous 48 à 72 heures incluant visites médicales d''aptitude, badges et inductions de sécurité.',
    'terrain',
    5,
    true
  ),
  (
    'Prenez-vous en charge l''intendance et la logistique complète d''acheminement ?',
    'Absolument. JBF Service fonctionne en autonomie complète selon les termes convenus au cahier des charges : Nous assurons l''acheminement de notre personnel qualifié, le transport de notre outillage lourd, l''approvisionnement en denrées certifiées et consommables industriels, ainsi que l''hébergement de nos équipes de relève. Le donneur d''ordre peut ainsi se concentrer sur son cœur de métier.',
    'terrain',
    6,
    true
  ),
  (
    'JBF Service est-elle officiellement enregistrée et certifiée ARSP ?',
    'Oui, sans réserve. JBF Service est une société de droit congolais en règle intégrale avec les dispositions de la Loi n° 17/001 du 8 février 2017 régissant la sous-traitance dans le secteur privé en RDC. Nous détenons notre certificat d''enregistrement auprès de l''ARSP et fournissons à chaque appel d''offres notre dossier complet de régularité fiscale (DGI) et sociale (CNSS).',
    'hse',
    7,
    true
  ),
  (
    'Quels sont vos protocoles de sécurité industrielle et d''hygiène HACCP ?',
    'La sécurité et la conformité sont nos priorités absolues : QHSE Minier & Industriel : Alignement rigoureux sur les normes ISO 45001 et ISO 9001 avec causeries sécurité matinales (« Tool Box Talks ») et analyse quotidienne des risques (JSA). Restauration & Catering : Application stricte de la méthode HACCP, contrôle microbiologique des denrées et respect sans faille de la chaîne du froid. Soudure Industrielle : Soudeurs qualifiés et certifiés selon les normes ASME IX et ISO 9606.',
    'hse',
    8,
    true
  ),
  (
    'Fournissez-vous les Équipements de Protection Individuelle (EPI) à vos équipes ?',
    'Oui. Tous nos agents déployés sur site sont intégralement dotés d''EPI certifiés CE et conformes aux exigences spécifiques de chaque mine ou usine : Casques avec jugulaire, lunettes de protection balistiques, gants anticoupure adaptés aux tâches, chaussures de sécurité coquées S3, gilets haute visibilité floqués JBF Service et harnais anti-chute vérifiés pour le travail en hauteur.',
    'hse',
    9,
    true
  ),
  (
    'Comment est encadrée et supervisée chaque mission sur le terrain ?',
    'Chaque détachement opérationnel est structuré hiérarchiquement : Un Superviseur de Site ou Chef de Brigade assure le commandement direct et la coordination opérationnelle quotidienne avec vos chefs d''équipe, tandis qu''un Officier QHSE veille à la conformité réglementaire et à la prévention des incidents.',
    'organisation',
    10,
    true
  ),
  (
    'Quels rapports de suivi d''activité transmettez-vous aux clients ?',
    'Nous assurons une traçabilité totale à travers : Des feuilles de pointage et de présence quotidiennes émargées. Des rapports hebdomadaires d''avancement technique et d''avancement des travaux. Des revues mensuelles de performance (KPI) portant sur la qualité de service, le respect des délais et les statistiques QHSE (taux de fréquence et de gravité zéro accident).',
    'organisation',
    11,
    true
  ),
  (
    'Comment planifier une visite technique préalable sur notre site ?',
    'Nos ingénieurs d''affaires se déplacent gratuitement sur vos sites d''exploitation pour auditer les installations et évaluer les besoins réels avant cotation. Vous pouvez nous contacter directement par téléphone au +243 822 357 053 ou via notre formulaire de contact en ligne pour convenir d''une date d''audit technique.',
    'organisation',
    12,
    true
  )
ON CONFLICT DO NOTHING;
