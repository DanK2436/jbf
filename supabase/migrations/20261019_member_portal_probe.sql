-- Indique si un email existe dans member_portal_accounts (admin diagnostic)

CREATE OR REPLACE FUNCTION public.admin_probe_portal_email(p_email TEXT, p_sync_key TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  expected TEXT := coalesce(current_setting('app.jbf_member_sync_key', true), 'jbf-member-sync-v1');
  v_email TEXT := lower(trim(p_email));
  v_exists BOOLEAN;
BEGIN
  IF p_sync_key IS NULL OR p_sync_key <> expected THEN
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden');
  END IF;
  IF v_email IS NULL OR length(v_email) < 3 THEN
    RETURN jsonb_build_object('ok', false, 'error', 'invalid_input');
  END IF;
  SELECT EXISTS(
    SELECT 1 FROM public.member_portal_accounts WHERE lower(trim(email)) = v_email
  ) INTO v_exists;
  RETURN jsonb_build_object('ok', true, 'exists', v_exists, 'email', v_email);
END;
$$;

REVOKE ALL ON FUNCTION public.admin_probe_portal_email(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_probe_portal_email(TEXT, TEXT) TO anon, authenticated, service_role;
