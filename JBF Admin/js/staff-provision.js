/**
 * Création comptes Auth (membre / sous-admin) via Edge Function ou backend.
 */
(function (window) {
  'use strict';

  async function invokeStaffProvision(payload) {
    const cfg = window.JBF_CONFIG || {};
    const url = (cfg.SUPABASE_URL || '').replace(/\/+$/, '');
    const key = cfg.SUPABASE_ANON_KEY || '';
    if (url && key) {
      try {
        const res = await fetch(`${url}/functions/v1/staff-provision`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${key}`,
            apikey: key,
          },
          body: JSON.stringify(payload),
        });
        const data = await res.json().catch(() => ({}));
        if (res.ok && data.success) return { ok: true, data };
      } catch (e) {
        console.warn('[staff-provision] Edge:', e.message);
      }
    }

    const bases = [];
    if (cfg.API_BASE_URL && !String(cfg.API_BASE_URL).includes('github.io')) {
      bases.push(String(cfg.API_BASE_URL).replace(/\/+$/, ''));
    }
    if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
      bases.push('http://localhost:3001');
    }

    for (const base of bases) {
      try {
        const path = payload.type === 'sub_admin' || payload.type === 'sous_admin'
          ? '/api/admin/sous-admins'
          : '/api/auth/register';
        const res = await fetch(`${base}${path}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });
        const data = await res.json().catch(() => ({}));
        if (res.ok && data.success !== false) return { ok: true, data };
      } catch (_) {}
    }

    return { ok: false };
  }

  window.JBFStaffProvision = { invokeStaffProvision };
})(window);
