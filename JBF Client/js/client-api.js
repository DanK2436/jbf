/**
 * Résolution des URLs API pour l'espace client (local, backend déployé, relais).
 */
(function (window) {
  'use strict';

  function normalizeBase(url) {
    if (!url || typeof url !== 'string') return '';
    return url.replace(/\/+$/, '');
  }

  function isGitHubPagesHost() {
    return window.location.hostname.endsWith('github.io');
  }

  function getClientApiBases() {
    const cfg = window.JBF_CLIENT_CONFIG || {};
    const bases = [];
    const seen = new Set();
    const origin = normalizeBase(window.location.origin);

    function add(base) {
      const n = normalizeBase(base);
      if (!n || seen.has(n)) return;
      if (isGitHubPagesHost() && (n === '/api' || n === `${origin}/api` || n.endsWith('/jbf/api'))) {
        return;
      }
      seen.add(n);
      bases.push(n);
    }

    if (cfg.API_BASE_URL && String(cfg.API_BASE_URL).trim()) {
      add(String(cfg.API_BASE_URL).replace(/\/api\/?$/, '') + '/api');
    }

    const host = window.location.hostname;
    if (host === 'localhost' || host === '127.0.0.1') {
      add('http://localhost:3001/api');
      add('http://127.0.0.1:3001/api');
    }

    return bases;
  }

  async function postJson(path, body) {
    const errors = [];
    for (const base of getClientApiBases()) {
      try {
        const res = await fetch(`${base}${path.startsWith('/') ? path : '/' + path}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
          body: JSON.stringify(body || {})
        });
        const data = await res.json().catch(() => ({}));
        if (res.ok && data && data.success !== false) {
          return { ok: true, data, base };
        }
        errors.push(`${base}: ${data.error || res.status}`);
      } catch (err) {
        errors.push(`${base}: ${err.message}`);
      }
    }
    return { ok: false, errors };
  }

  window.JBFClientApi = {
    isGitHubPagesHost,
    getClientApiBases,
    postJson
  };
})(window);
