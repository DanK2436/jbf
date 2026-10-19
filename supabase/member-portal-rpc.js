/**
 * Appels RPC Supabase portail membre (fetch REST — fiable sur GitHub Pages).
 */
(function (window) {
  'use strict';

  function readConfig() {
    const admin = window.JBF_CONFIG || {};
    const membre = window.JBF_MEMBER_CONFIG || {};
    return {
      url: (admin.SUPABASE_URL || membre.SUPABASE_URL || '').replace(/\/$/, ''),
      key: admin.SUPABASE_ANON_KEY || membre.SUPABASE_ANON_KEY || '',
      syncKey: admin.MEMBER_SYNC_KEY || membre.MEMBER_SYNC_KEY || 'jbf-member-sync-v1'
    };
  }

  async function callRpc(functionName, body) {
    const cfg = readConfig();
    if (!cfg.url || !cfg.key) {
      return { ok: false, error: 'missing_supabase_config' };
    }
    try {
      const res = await fetch(`${cfg.url}/rest/v1/rpc/${functionName}`, {
        method: 'POST',
        headers: {
          apikey: cfg.key,
          Authorization: `Bearer ${cfg.key}`,
          'Content-Type': 'application/json',
          Accept: 'application/json'
        },
        body: JSON.stringify(body || {})
      });
      const text = await res.text();
      let data = null;
      try {
        data = text ? JSON.parse(text) : null;
      } catch (_) {
        data = { raw: text };
      }
      if (!res.ok) {
        const msg = (data && (data.message || data.error)) || text || res.statusText;
        return { ok: false, error: msg, status: res.status, data };
      }
      return { ok: true, data };
    } catch (e) {
      return { ok: false, error: e.message || 'network_error' };
    }
  }

  async function checkMemberLogin(email, password) {
    const cleanEmail = String(email || '').trim().toLowerCase();
    const cleanPass = String(password || '').trim();
    const res = await callRpc('check_member_login', {
      p_email: cleanEmail,
      p_password: cleanPass
    });
    if (!res.ok) return { ok: false, error: res.error, reason: 'rpc_error' };
    const payload = res.data;
    if (!payload || !payload.ok) {
      return {
        ok: false,
        error: payload?.error || 'login_failed',
        reason: payload?.error === 'invalid_credentials' ? 'invalid_credentials' : 'login_failed'
      };
    }
    return { ok: true, profile: payload };
  }

  async function syncMemberPortalAccount(agent) {
    if (!agent?.email || !agent._authPassword) {
      return { ok: false, error: 'missing_email_or_password' };
    }
    const cfg = readConfig();
    const res = await callRpc('admin_sync_member_account', {
      p_email: String(agent.email).trim().toLowerCase(),
      p_password: String(agent._authPassword).trim(),
      p_full_name: agent.full_name || agent.nom_complet || agent.name || agent.email,
      p_sync_key: cfg.syncKey,
      p_matricule: agent.matricule || null,
      p_section_id: agent.section_id != null ? agent.section_id : null,
      p_section_nom: agent.section_nom || null,
      p_poste: agent.poste || agent.fonction || null,
      p_phone: agent.phone || agent.telephone || null,
      p_profile_id: String(agent.id || '').startsWith('ag-') || String(agent.id || '').startsWith('mem-')
        ? null
        : agent.id,
      p_statut_equipe: agent.statut_equipe || (agent.role === 'chef_equipe' ? 'chef_equipe' : 'membre')
    });
    if (!res.ok) return { ok: false, error: res.error };
    const payload = res.data;
    if (!payload?.ok) return { ok: false, error: payload?.error || 'sync_failed' };
    return { ok: true, email: payload.email };
  }

  async function syncAndVerifyMemberPortal(agent) {
    const sync = await syncMemberPortalAccount(agent);
    if (!sync.ok) return { ok: false, step: 'sync', error: sync.error };
    const login = await checkMemberLogin(agent.email, agent._authPassword);
    if (!login.ok) {
      return {
        ok: false,
        step: 'verify',
        error: login.error || 'verify_failed',
        hint: 'La synchronisation a répondu OK mais le test de connexion a échoué. Ré-exécutez le SQL member_portal_login dans Supabase.'
      };
    }
    return { ok: true, profile: login.profile };
  }

  async function probePortalEmail(email) {
    const cfg = readConfig();
    const res = await callRpc('admin_probe_portal_email', {
      p_email: String(email || '').trim().toLowerCase(),
      p_sync_key: cfg.syncKey
    });
    if (!res.ok) return { ok: false, error: res.error };
    return { ok: true, exists: !!(res.data && res.data.exists) };
  }

  window.JBFMemberPortalRpc = {
    readConfig,
    callRpc,
    checkMemberLogin,
    syncMemberPortalAccount,
    syncAndVerifyMemberPortal,
    probePortalEmail
  };
})(window);
