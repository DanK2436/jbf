/**
 * JBF SERVICES — Client d'envoi OTP
 * Aucune clé de messagerie n'est lue ni envoyée par le navigateur.
 * Le serveur génère le code et parle aux fournisseurs.
 */
(function (window) {
  'use strict';

  function apiBases() {
    if (window.JBFClientApi && typeof window.JBFClientApi.getClientApiBases === 'function') {
      return window.JBFClientApi.getClientApiBases();
    }
    const host = window.location.hostname;
    if (host === 'localhost' || host === '127.0.0.1') {
      return ['http://127.0.0.1:3001/api', 'http://localhost:3001/api'];
    }
    return [];
  }

  async function postServer(path, body) {
    const errors = [];
    const bases = apiBases();
    if (!bases.length) {
      return {
        ok: false,
        error: 'Aucun serveur de messagerie joignable depuis cette page. Le navigateur n\'envoie pas de courriel.'
      };
    }
    for (const base of bases) {
      try {
        const res = await fetch(base + path, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
          body: JSON.stringify(body || {})
        });
        const data = await res.json().catch(() => ({}));
        if (res.ok && data && data.success !== false) {
          return { ok: true, data };
        }
        errors.push(data.error || ('HTTP ' + res.status));
      } catch (err) {
        errors.push(err.message || 'réseau');
      }
    }
    return { ok: false, error: errors.join(' · ') || 'Envoi refusé par le serveur.' };
  }

  const JBFMailService = {
    getQuotaStats: function () {
      return { date: new Date().toISOString().slice(0, 10), total: 0, brevo: 0, resend: 0 };
    },

    async sendClientLoginOtp(email) {
      const result = await postServer('/auth/otp/send', { email: email });
      if (!result.ok) {
        const error = new Error(result.error || 'Envoi du code impossible.');
        error.simulated = false;
        throw error;
      }
      return {
        success: true,
        simulated: false,
        provider: (result.data && result.data.provider) || 'serveur'
      };
    },

    async sendClientPasswordReset(email) {
      const result = await postServer('/auth/reset-otp/send', { email: email });
      if (!result.ok) {
        const error = new Error(result.error || 'Envoi du code impossible.');
        error.simulated = false;
        throw error;
      }
      return {
        success: true,
        simulated: false,
        provider: (result.data && result.data.provider) || 'serveur'
      };
    },

    async verifyServerOtp(email, token) {
      const result = await postServer('/auth/otp/verify', { email: email, token: token });
      if (!result.ok) {
        throw new Error(result.error || 'Code OTP incorrect ou expiré.');
      }
      return result.data || { success: true };
    }
  };

  window.JBFMailService = JBFMailService;
})(window);
