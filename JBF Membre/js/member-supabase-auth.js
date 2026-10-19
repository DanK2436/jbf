/** Connexion membre via RPC Supabase (check_member_login) — fonctionne sans Auth email confirmé. */
(function (window) {
  'use strict';

  const SYNC_KEY = (window.JBF_MEMBER_CONFIG && window.JBF_MEMBER_CONFIG.MEMBER_SYNC_KEY) || 'jbf-member-sync-v1';

  function getClient() {
    const cfg = window.JBF_MEMBER_CONFIG || {};
    if (!window.supabase || !cfg.SUPABASE_URL || !cfg.SUPABASE_ANON_KEY) return null;
    try {
      return window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY);
    } catch (e) {
      return null;
    }
  }

  async function tryRpcMemberLogin(email, password) {
    const client = getClient();
    if (!client) return null;
    try {
      const { data, error } = await client.rpc('check_member_login', {
        p_email: email.trim().toLowerCase(),
        p_password: password
      });
      if (error) {
        console.warn('[Member RPC login]', error.message);
        return null;
      }
      const payload = typeof data === 'string' ? JSON.parse(data) : data;
      if (!payload || !payload.ok) return null;

      const fullName = payload.full_name || email;
      const initials = fullName.split(' ').filter(Boolean).map((n) => n[0]).join('').substring(0, 2).toUpperCase();
      return {
        id: payload.profile_id || ('rpc-' + Date.now()),
        email: payload.email || email,
        nom: fullName,
        full_name: fullName,
        initials,
        matricule: payload.matricule || '',
        section_id: payload.section_id || 4,
        section_nom: payload.section_nom || '',
        poste: payload.poste || 'Collaborateur',
        phone: payload.phone || '',
        role: payload.statut_equipe === 'chef_equipe' ? 'chef_equipe' : 'membre',
        statut_equipe: payload.statut_equipe || 'membre',
        token: 'jbf-member-rpc-' + Date.now()
      };
    } catch (e) {
      console.warn('[Member RPC login]', e);
      return null;
    }
  }

  async function syncMemberAccountToSupabase(agent) {
    const client = getClient();
    if (!client || !agent?.email || !agent._authPassword) return { ok: false };
    try {
      const { data, error } = await client.rpc('admin_sync_member_account', {
        p_email: agent.email,
        p_password: agent._authPassword,
        p_full_name: agent.full_name || agent.nom_complet || agent.name || agent.email,
        p_sync_key: SYNC_KEY,
        p_matricule: agent.matricule || null,
        p_section_id: agent.section_id || null,
        p_section_nom: agent.section_nom || null,
        p_poste: agent.poste || agent.fonction || null,
        p_phone: agent.phone || agent.telephone || null,
        p_profile_id: String(agent.id || '').startsWith('ag-') ? null : agent.id
      });
      if (error) return { ok: false, error: error.message };
      const payload = typeof data === 'string' ? JSON.parse(data) : data;
      return { ok: !!(payload && payload.ok), error: payload?.error };
    } catch (e) {
      return { ok: false, error: e.message };
    }
  }

  window.JBFMemberSupabaseAuth = {
    tryRpcMemberLogin,
    syncMemberAccountToSupabase,
    SYNC_KEY
  };
})(window);
