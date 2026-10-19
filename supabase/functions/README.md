# Edge Functions — mot de passe oublié client (GitHub Pages)

Sans backend Node, déployez ces fonctions sur le projet Supabase JBF :

```bash
supabase login
supabase link --project-ref dvzwqxcaiagczyonrhsg
supabase db push   # migration password_reset_challenges
supabase secrets set BREVO_API_KEY=votre_cle_brevo
supabase functions deploy send-client-reset-otp
supabase functions deploy client-reset-password
```

Variables automatiques : `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`.

Après déploiement, l’espace client pourra envoyer l’OTP et enregistrer le nouveau mot de passe depuis https://dank2436.github.io/jbf/.
