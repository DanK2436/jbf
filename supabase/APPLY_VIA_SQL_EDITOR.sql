-- =============================================================================
-- JBF SERVICES — Script unique pour Supabase SQL Editor
-- Dashboard : https://supabase.com/dashboard/project/VOTRE_REF/sql/new
-- Coller ce fichier entier puis « Run ».
-- =============================================================================

\i database_schema.sql
-- Si l'éditeur ne supporte pas \i, exécutez d'abord database_schema.sql du repo,
-- puis les blocs ci-dessous :

-- password_reset_challenges
CREATE TABLE IF NOT EXISTS public.password_reset_challenges (
  email TEXT PRIMARY KEY,
  code_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.password_reset_challenges ENABLE ROW LEVEL SECURITY;

-- blog_posts
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
DROP POLICY IF EXISTS "Allow public on blog_posts" ON public.blog_posts;
CREATE POLICY "Allow public on blog_posts" ON public.blog_posts FOR ALL USING (true) WITH CHECK (true);
