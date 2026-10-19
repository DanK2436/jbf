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
    const { email, token, newPassword } = await req.json();
    const cleanEmail = String(email || '').trim().toLowerCase();
    const cleanToken = String(token || '').trim();
    const password = String(newPassword || '');

    if (!cleanEmail || cleanToken.length !== 6 || password.length < 8) {
      return new Response(JSON.stringify({ success: false, error: 'Email, code OTP (6 chiffres) et mot de passe (8+) requis.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const admin = createClient(supabaseUrl, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const codeHash = await sha256(`${cleanEmail}:${cleanToken}`);
    const { data: row, error: fetchErr } = await admin
      .from('password_reset_challenges')
      .select('code_hash, expires_at')
      .eq('email', cleanEmail)
      .maybeSingle();

    if (fetchErr) throw fetchErr;
    if (!row || row.code_hash !== codeHash || new Date(row.expires_at).getTime() < Date.now()) {
      return new Response(JSON.stringify({ success: false, error: 'Code OTP incorrect ou expiré.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: usersList } = await admin.auth.admin.listUsers();
    const target = usersList?.users?.find((u) => u.email?.toLowerCase() === cleanEmail);

    if (!target) {
      const { data: created, error: createErr } = await admin.auth.admin.createUser({
        email: cleanEmail,
        password,
        email_confirm: true,
        user_metadata: { role: 'client' },
      });
      if (createErr) throw createErr;
      if (created?.user?.id) {
        await admin.from('profiles').upsert({
          id: created.user.id,
          email: cleanEmail,
          full_name: cleanEmail.split('@')[0],
          role: 'client',
          is_verified: true,
        });
      }
    } else {
      const { error: updateErr } = await admin.auth.admin.updateUserById(target.id, { password });
      if (updateErr) throw updateErr;
    }

    await admin.from('password_reset_challenges').delete().eq('email', cleanEmail);

    return new Response(JSON.stringify({ success: true, message: 'Mot de passe mis à jour.' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return new Response(JSON.stringify({ success: false, error: err.message || 'Erreur réinitialisation' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
