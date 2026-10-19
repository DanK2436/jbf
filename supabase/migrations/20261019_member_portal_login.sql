-- Connexion membre sur GitHub Pages (sans Edge Function déployée)
-- Mot de passe synchronisé à la création admin via RPC admin_sync_member_account.

CREATE TABLE IF NOT EXISTS public.member_portal_accounts (
  email TEXT PRIMARY KEY,
  password TEXT NOT NULL,
  full_name TEXT,
  matricule TEXT,
  section_id INTEGER,
  section_nom TEXT,
  poste TEXT,
  phone TEXT,
  profile_id UUID,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.member_portal_accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "No direct access member_portal_accounts" ON public.member_portal_accounts;
CREATE POLICY "No direct access member_portal_accounts"
  ON public.member_portal_accounts FOR ALL
  USING (false) WITH CHECK (false);

CREATE OR REPLACE FUNCTION public.check_member_login(p_email TEXT, p_password TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  row public.member_portal_accounts%ROWTYPE;
BEGIN
  IF p_email IS NULL OR length(trim(p_email)) < 3 OR p_password IS NULL OR length(p_password) < 6 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_input');
  END IF;

  SELECT * INTO row
  FROM public.member_portal_accounts
  WHERE lower(email) = lower(trim(p_email));

  IF NOT FOUND OR row.password <> p_password THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_credentials');
  END IF;

  RETURN jsonb_build_object(
    'ok', true,
    'email', row.email,
    'full_name', COALESCE(row.full_name, row.email),
    'matricule', row.matricule,
    'section_id', row.section_id,
    'section_nom', row.section_nom,
    'poste', row.poste,
    'phone', row.phone,
    'profile_id', row.profile_id,
    'statut_equipe', COALESCE(NULLIF(trim(row.statut_equipe), ''), 'membre')
  );
END;
$$;

ALTER TABLE public.member_portal_accounts
  ADD COLUMN IF NOT EXISTS statut_equipe TEXT DEFAULT 'membre';

DROP FUNCTION IF EXISTS public.admin_sync_member_account(TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, TEXT, TEXT, TEXT, UUID);

CREATE OR REPLACE FUNCTION public.admin_sync_member_account(
  p_email TEXT,
  p_password TEXT,
  p_full_name TEXT,
  p_sync_key TEXT,
  p_matricule TEXT DEFAULT NULL,
  p_section_id INTEGER DEFAULT NULL,
  p_section_nom TEXT DEFAULT NULL,
  p_poste TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL,
  p_profile_id UUID DEFAULT NULL,
  p_statut_equipe TEXT DEFAULT 'membre'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  expected TEXT := coalesce(current_setting('app.jbf_member_sync_key', true), 'jbf-member-sync-v1');
  v_statut TEXT := COALESCE(NULLIF(trim(p_statut_equipe), ''), 'membre');
BEGIN
  IF p_sync_key IS NULL OR p_sync_key <> expected THEN
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden');
  END IF;
  IF p_email IS NULL OR length(trim(p_email)) < 3 OR p_password IS NULL OR length(p_password) < 6 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_input');
  END IF;
  IF v_statut NOT IN ('membre', 'chef_equipe') THEN
    v_statut := 'membre';
  END IF;

  INSERT INTO public.member_portal_accounts (
    email, password, full_name, matricule, section_id, section_nom, poste, phone, profile_id, statut_equipe, updated_at
  ) VALUES (
    lower(trim(p_email)), p_password, p_full_name, p_matricule, p_section_id, p_section_nom, p_poste, p_phone, p_profile_id, v_statut, NOW()
  )
  ON CONFLICT (email) DO UPDATE SET
    password = EXCLUDED.password,
    full_name = EXCLUDED.full_name,
    matricule = EXCLUDED.matricule,
    section_id = EXCLUDED.section_id,
    section_nom = EXCLUDED.section_nom,
    poste = EXCLUDED.poste,
    phone = EXCLUDED.phone,
    profile_id = COALESCE(EXCLUDED.profile_id, member_portal_accounts.profile_id),
    statut_equipe = EXCLUDED.statut_equipe,
    updated_at = NOW();

  RETURN jsonb_build_object('ok', true, 'email', lower(trim(p_email)), 'statut_equipe', v_statut);
END;
$$;

REVOKE ALL ON FUNCTION public.check_member_login(TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_sync_member_account(TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, TEXT, TEXT, TEXT, UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_member_login(TEXT, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.admin_sync_member_account(TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, TEXT, TEXT, TEXT, UUID, TEXT) TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.admin_delete_member_account(p_email TEXT, p_sync_key TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  expected TEXT := coalesce(current_setting('app.jbf_member_sync_key', true), 'jbf-member-sync-v1');
BEGIN
  IF p_sync_key IS NULL OR p_sync_key <> expected THEN
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden');
  END IF;
  DELETE FROM public.member_portal_accounts WHERE lower(email) = lower(trim(p_email));
  RETURN jsonb_build_object('ok', true);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_delete_member_account(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_delete_member_account(TEXT, TEXT) TO anon, authenticated, service_role;
