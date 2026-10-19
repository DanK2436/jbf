/** Synchronise email/mot de passe collaborateur → Supabase RPC (connexion membre multi-appareils). */
(function (window) {
  'use strict';

  function getClient() {
    const cfg = window.JBF_CONFIG || {};
    if (!window.supabase || !cfg.SUPABASE_URL || !cfg.SUPABASE_ANON_KEY) return null;
    try {
      return window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY);
    } catch (e) {
      return null;
    }
  }

  async function syncMemberAccount(agent) {
    const client = getClient();
    const syncKey = cfgKey();
    if (!client || !agent?.email || !agent._authPassword) {
      return { ok: false, error: 'missing_client_or_password' };
    }
    try {
      const { data, error } = await client.rpc('admin_sync_member_account', {
        p_email: agent.email,
        p_password: agent._authPassword,
        p_full_name: agent.full_name || agent.nom_complet || agent.name || agent.email,
        p_sync_key: syncKey,
        p_matricule: agent.matricule || null,
        p_section_id: agent.section_id || null,
        p_section_nom: agent.section_nom || null,
        p_poste: agent.poste || agent.fonction || null,
        p_phone: agent.phone || agent.telephone || null,
        p_profile_id: String(agent.id || '').startsWith('ag-') ? null : agent.id,
        p_statut_equipe: agent.statut_equipe || agent.role || 'membre'
      });
      if (error) return { ok: false, error: error.message };
      const payload = typeof data === 'string' ? JSON.parse(data) : data;
      if (payload?.ok) return { ok: true };
      return { ok: false, error: payload?.error || 'sync_failed' };
    } catch (e) {
      return { ok: false, error: e.message };
    }
  }

  function cfgKey() {
    return (window.JBF_CONFIG && window.JBF_CONFIG.MEMBER_SYNC_KEY) || 'jbf-member-sync-v1';
  }

  async function deleteMemberAccount(email) {
    const client = getClient();
    const syncKey = cfgKey();
    if (!client || !email) {
      return { ok: false, error: 'missing_client_or_email' };
    }
    try {
      const { data, error } = await client.rpc('admin_delete_member_account', {
        p_email: email.trim().toLowerCase(),
        p_sync_key: syncKey
      });
      if (error) return { ok: false, error: error.message };
      const payload = typeof data === 'string' ? JSON.parse(data) : data;
      if (payload?.ok) return { ok: true };
      return { ok: false, error: payload?.error || 'delete_failed' };
    } catch (e) {
      return { ok: false, error: e.message };
    }
  }

  window.JBFMemberPortalSync = { syncMemberAccount, deleteMemberAccount };
})(window);
