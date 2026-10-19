/** Connexion membre via RPC Supabase (check_member_login) — fetch REST + repli client JS. */
(function (window) {
  'use strict';

  let lastLoginError = null;

  function getClient() {
    const cfg = window.JBF_MEMBER_CONFIG || window.JBF_CONFIG || {};
    if (!window.supabase || !cfg.SUPABASE_URL || !cfg.SUPABASE_ANON_KEY) return null;
    try {
      return window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY);
    } catch (e) {
      return null;
    }
  }

  function profileToSession(payload, emailFallback) {
    const fullName = payload.full_name || emailFallback;
    const initials = fullName.split(' ').filter(Boolean).map((n) => n[0]).join('').substring(0, 2).toUpperCase();
    return {
      id: payload.profile_id || ('rpc-' + Date.now()),
      email: payload.email || emailFallback,
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
      solde_conges: 0,
      token: 'jbf-member-rpc-' + Date.now()
    };
  }

  async function tryRpcMemberLogin(email, password) {
    lastLoginError = null;
    const cleanEmail = String(email || '').trim().toLowerCase();
    const cleanPass = String(password || '').trim();

    if (window.JBFMemberPortalRpc?.checkMemberLogin) {
      const viaFetch = await window.JBFMemberPortalRpc.checkMemberLogin(cleanEmail, cleanPass);
      if (viaFetch.ok && viaFetch.profile) {
        return profileToSession(viaFetch.profile, cleanEmail);
      }
      lastLoginError = viaFetch.reason || viaFetch.error || 'login_failed';
      if (lastLoginError === 'rpc_error' && /could not find|PGRST202|function/i.test(String(viaFetch.error))) {
        lastLoginError = 'rpc_missing';
      }
      if (lastLoginError === 'network_error' || /fetch|network/i.test(String(viaFetch.error))) {
        lastLoginError = 'network';
      }
      return null;
    }

    const client = getClient();
    if (!client) {
      lastLoginError = 'no_client';
      return null;
    }
    try {
      const { data, error } = await client.rpc('check_member_login', {
        p_email: cleanEmail,
        p_password: cleanPass
      });
      if (error) {
        lastLoginError = /could not find the function|PGRST202/i.test(error.message || '') ? 'rpc_missing' : 'rpc_error';
        return null;
      }
      const payload = typeof data === 'string' ? JSON.parse(data) : data;
      if (!payload || !payload.ok) {
        lastLoginError = payload?.error === 'invalid_credentials' ? 'invalid_credentials' : 'login_failed';
        return null;
      }
      return profileToSession(payload, cleanEmail);
    } catch (e) {
      lastLoginError = 'network';
      return null;
    }
  }

  function getLastLoginError() {
    return lastLoginError;
  }

  window.JBFMemberSupabaseAuth = {
    tryRpcMemberLogin,
    getLastLoginError
  };
})(window);
