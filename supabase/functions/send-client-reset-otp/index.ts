import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

async function sha256(text: string): Promise<string> {
  const data = new TextEncoder().encode(text);
  const hash = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(hash)).map((b) => b.toString(16).padStart(2, '0')).join('');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { email } = await req.json();
    const cleanEmail = String(email || '').trim().toLowerCase();
    if (!cleanEmail || !cleanEmail.includes('@')) {
      return new Response(JSON.stringify({ success: false, error: 'Email invalide.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const brevoKey = Deno.env.get('BREVO_API_KEY') || '';
    const resendKey = Deno.env.get('RESEND_API_KEY') || '';

    const admin = createClient(supabaseUrl, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    if (!brevoKey && !resendKey) {
      return new Response(JSON.stringify({
        success: false,
        error: 'Aucun fournisseur de messagerie configuré sur la fonction. Aucun code n\'est émis.'
      }), {
        status: 503,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const otp = String(Math.floor(100000 + Math.random() * 900000));
    const codeHash = await sha256(`${cleanEmail}:${otp}`);
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

    const { error: upsertErr } = await admin.from('password_reset_challenges').upsert({
      email: cleanEmail,
      code_hash: codeHash,
      expires_at: expiresAt,
    });
    if (upsertErr) throw upsertErr;

    const html = `<p>Votre code JBF SERVICES : <strong style="font-size:28px;letter-spacing:4px;color:#E6007E">${otp}</strong></p><p>Expire dans 10 minutes.</p>`;
    let provider = '';
    if (brevoKey) {
      const brevoRes = await fetch('https://api.brevo.com/v3/smtp/email', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'api-key': brevoKey,
          Accept: 'application/json',
        },
        body: JSON.stringify({
          sender: { name: 'JBF SERVICES', email: 'dankande3@gmail.com' },
          to: [{ email: cleanEmail }],
          subject: 'Code de réinitialisation JBF',
          htmlContent: html,
        }),
      });
      if (brevoRes.ok) provider = 'brevo';
    }
    if (!provider && resendKey) {
      const resendRes = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${resendKey}`,
        },
        body: JSON.stringify({
          from: 'JBF SERVICES <onboarding@resend.dev>',
          to: [cleanEmail],
          subject: 'Code de réinitialisation JBF',
          html,
        }),
      });
      if (resendRes.ok) provider = 'resend';
    }
    if (!provider) {
      await admin.from('password_reset_challenges').delete().eq('email', cleanEmail);
      throw new Error('Les fournisseurs de messagerie ont refusé l\'envoi.');
    }

    return new Response(JSON.stringify({ success: true, provider }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return new Response(JSON.stringify({ success: false, error: err.message || 'Erreur envoi OTP' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
