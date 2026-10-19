-- Renforce la connexion membre : comparaison mot de passe trim + email normalisé

CREATE OR REPLACE FUNCTION public.check_member_login(p_email TEXT, p_password TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  row public.member_portal_accounts%ROWTYPE;
  v_email TEXT := lower(trim(p_email));
  v_pass TEXT := trim(p_password);
BEGIN
  IF v_email IS NULL OR length(v_email) < 3 OR v_pass IS NULL OR length(v_pass) < 6 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_input');
  END IF;

  SELECT * INTO row
  FROM public.member_portal_accounts
  WHERE lower(trim(email)) = v_email;

  IF NOT FOUND OR (trim(row.password) <> v_pass AND row.password <> v_pass) THEN
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

GRANT EXECUTE ON FUNCTION public.check_member_login(TEXT, TEXT) TO anon, authenticated, service_role;
