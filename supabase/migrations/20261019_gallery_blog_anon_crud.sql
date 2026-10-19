-- Autorise l’admin statique (clé anon) à modifier / supprimer galerie et blog.
-- À exécuter dans Supabase → SQL Editor si modifier/supprimer échoue après publication.

DROP POLICY IF EXISTS "Gestion galerie par admin" ON public.gallery_images;
DROP POLICY IF EXISTS "Allow public on gallery_images" ON public.gallery_images;
CREATE POLICY "Allow public on gallery_images"
  ON public.gallery_images FOR ALL
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public on galerie" ON public.galerie_items;
CREATE POLICY "Allow public on galerie"
  ON public.galerie_items FOR ALL
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Gestion blog par admin" ON public.blog_posts;
DROP POLICY IF EXISTS "Allow public on blog_posts" ON public.blog_posts;
CREATE POLICY "Allow public on blog_posts"
  ON public.blog_posts FOR ALL
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public on actualites" ON public.actualites;
CREATE POLICY "Allow public on actualites"
  ON public.actualites FOR ALL
  USING (true) WITH CHECK (true);
