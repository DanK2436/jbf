-- =============================================================
-- JBF SERVICES SARL — DONNÉES DE TEST & DÉMONSTRATION MEMBRE
-- À exécuter dans l'éditeur SQL de Supabase après schema.sql
-- =============================================================

-- 1. Insertion de ressources HSE & Documents Techniques réels
INSERT INTO public.ressources_hse (titre, categorie, section_id, section_nom, description, fichier_url, type_fichier, taille, publie)
VALUES
(
  'Guide de Sécurité en Milieu Minier 2026',
  'HSE & Sécurité',
  4,
  'Prestations de sous-traitance dans le domaine minier',
  'Manuel complet des équipements de protection individuelle (EPI) obligatoires et protocoles d''évacuation sur sites miniers.',
  '#',
  'PDF',
  '3.8 MB',
  true
),
(
  'Protocoles d''Hygiène Alimentaire & Chaîne du Froid',
  'HSE & Sécurité',
  1,
  'Fourniture de produits alimentaires',
  'Directives strictes de manutention des denrées périssables et normes HACCP pour cantines et bases de vie.',
  '#',
  'PDF',
  '2.4 MB',
  true
),
(
  'Règlement Intérieur & Code de Conduite Entreprise',
  'Règlements & Politiques',
  0,
  'Tous Services',
  'Directives officielles d''éthique, de discipline et de conformité pour tous les collaborateurs de JBF SERVICES SARL.',
  '#',
  'PDF',
  '1.5 MB',
  true
),
(
  'Manuel de Maintenance Préventive des Installations',
  'HSE & Sécurité',
  5,
  'Prestations de service de maintenance',
  'Fiches de diagnostic, calendrier des interventions préventives et procédures d''arrêt d''urgence.',
  '#',
  'PDF',
  '4.2 MB',
  true
)
ON CONFLICT DO NOTHING;

-- 2. Insertion de messages d'exemple dans le Chat Général et Section
INSERT INTO public.messages_chat (expediteur_nom, expediteur_avatar, canal_type, section_id, section_nom, message, created_at)
VALUES
(
  'Direction des Opérations',
  'DO',
  'general',
  NULL,
  NULL,
  'Bienvenue sur le nouveau portail intranet JBF SERVICES. Les canaux par section métier sont désormais opérationnels.',
  now() - interval '2 hours'
),
(
  'Superviseur HSE',
  'HSE',
  'general',
  NULL,
  NULL,
  'Rappel à toutes les équipes terrain : port des EPI obligatoire dès l''entrée sur les zones d''intervention minières et BTP.',
  now() - interval '1 hour'
),
(
  'Responsable Section 4',
  'S4',
  'section',
  4,
  'Prestations de sous-traitance dans le domaine minier',
  'Briefing de sécurité de 7h00 validé pour l''équipe du secteur Fungurume. Rotation planifiée sans incident.',
  now() - interval '30 minutes'
)
ON CONFLICT DO NOTHING;

-- 3. Insertion de ressource Vidéo de Formation pour les membres
INSERT INTO public.ressources_hse (titre, categorie, section_id, section_nom, description, fichier_url, type_fichier, taille, publie)
VALUES
(
  'Formation Vidéo : Protocoles d''intervention et Sécurité Électrique Haute Tension',
  'Formation Vidéo & HSE',
  5,
  'Prestations de service de maintenance',
  'Module complet en vidéo démontrant les étapes de consignation électrique et d''isolation des circuits industriels.',
  'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  'Vidéo',
  '18 min • Full HD',
  true
)
ON CONFLICT DO NOTHING;

-- 4. Inscription du compte Administrateur officiel dans admin_accounts
INSERT INTO public.admin_accounts (full_name, email, phone, role, permissions)
VALUES (
  'Direction Générale JBF SERVICES',
  'services@admin.jbf',
  '+243 971 306 666',
  'super_admin',
  ARRAY['*']
)
ON CONFLICT (email) DO UPDATE
SET role = 'super_admin', permissions = ARRAY['*'], is_active = true;

