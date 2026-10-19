/**
 * Appels Supabase Edge Functions (GitHub Pages — pas de backend Node /api).
 */
(function (window) {
  'use strict';

  function getSupabaseConfig() {
    const cfg = window.JBF_CLIENT_CONFIG || {};
    return {
      url: (cfg.SUPABASE_URL || window.ENV_SUPABASE_URL || '').replace(/\/+$/, ''),
      anonKey: cfg.SUPABASE_ANON_KEY || window.ENV_SUPABASE_ANON_KEY || '',
    };
  }

  async function invokeFunction(functionName, body) {
    const { url, anonKey } = getSupabaseConfig();
    if (!url || !anonKey) {
      return { ok: false, status: 0, error: 'Configuration Supabase manquante.' };
    }

    try {
      const res = await fetch(`${url}/functions/v1/${functionName}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${anonKey}`,
          apikey: anonKey,
        },
        body: JSON.stringify(body || {}),
      });
      const data = await res.json().catch(() => ({}));
      if (res.ok && data.success !== false) {
        return { ok: true, status: res.status, data };
      }
      return {
        ok: false,
        status: res.status,
        error: data.error || `HTTP ${res.status}`,
        data,
      };
    } catch (err) {
      return { ok: false, status: 0, error: err.message || 'Network error' };
    }
  }

  window.JBFClientEdge = {
    invokeFunction,
    sendResetOtp: (email) => invokeFunction('send-client-reset-otp', { email }),
    confirmResetPassword: (email, token, newPassword) =>
      invokeFunction('client-reset-password', { email, token, newPassword }),
  };
})(window);
