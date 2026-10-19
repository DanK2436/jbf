import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const email = String(body.email || '').trim().toLowerCase();
    const password = String(body.password || '');
    const fullName = String(body.full_name || body.fullName || '').trim();
    const phone = String(body.phone || '').trim();
    const staffType = String(body.type || 'membre');
    const permissions = Array.isArray(body.permissions) ? body.permissions : [];

    if (!email || !password || password.length < 6 || !fullName) {
      return new Response(JSON.stringify({ success: false, error: 'Nom, email et mot de passe (6+) requis.' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const admin = createClient(supabaseUrl, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const role = staffType === 'sub_admin' || staffType === 'sous_admin' ? 'sous_admin' : 'membre';
    const poste = role === 'sous_admin' ? 'Sous-Administrateur Délégué' : String(body.poste || body.fonction || 'Collaborateur JBF');

    const { data: usersList } = await admin.auth.admin.listUsers();
    let userId = usersList?.users?.find((u) => u.email?.toLowerCase() === email)?.id;

    if (!userId) {
      const { data: created, error: createErr } = await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { full_name: fullName, phone, role, permissions },
      });
      if (createErr) throw createErr;
      userId = created.user?.id;
    } else {
      await admin.auth.admin.updateUserById(userId, {
        password,
        email_confirm: true,
        user_metadata: { full_name: fullName, phone, role, permissions },
      });
    }

    if (!userId) throw new Error('Impossible de créer le compte Auth.');

    await admin.from('profiles').upsert({
      id: userId,
      email,
      full_name: fullName,
      phone: phone || null,
      role,
      poste,
      permissions: role === 'sous_admin' ? permissions : undefined,
      is_verified: true,
      updated_at: new Date().toISOString(),
      ...(body.extraProfile || {}),
    });

    if (role === 'sous_admin') {
      await admin.from('admin_accounts').upsert({
        id: userId,
        full_name: fullName,
        email,
        phone: phone || null,
        role: 'sous_admin',
        permissions: permissions.length ? permissions : ['dashboard'],
        is_active: true,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'email' });
    }

    return new Response(JSON.stringify({ success: true, userId, role }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return new Response(JSON.stringify({ success: false, error: err.message || 'Erreur provisionnement' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
