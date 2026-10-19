-- Défis OTP réinitialisation mot de passe client (accès service role / Edge Functions uniquement)
CREATE TABLE IF NOT EXISTS public.password_reset_challenges (
  email TEXT PRIMARY KEY,
  code_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.password_reset_challenges ENABLE ROW LEVEL SECURITY;

-- Aucune policy anon/authenticated : seules les Edge Functions (service role) accèdent à la table.
