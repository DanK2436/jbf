-- Blog public (complément si absent)
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
