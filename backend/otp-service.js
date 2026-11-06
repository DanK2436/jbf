/**
 * Codes OTP émis et vérifiés par le serveur JBF.
 * Brevo et Resend transportent seulement le message.
 * Chaque usage (login, register, reset) est une clé distincte.
 */

const { randomInt } = require('crypto');

const PURPOSES = new Set(['login', 'register', 'reset']);

function createOtpBroker(options = {}) {
  const store = new Map();
  const sends = new Map();
  const now = options.now || (() => Date.now());
  const ttlMs = options.ttlMs || 10 * 60 * 1000;
  const maxAttempts = options.maxAttempts || 5;
  const maxSends = options.maxSends || 5;
  const sendWindowMs = options.sendWindowMs || 15 * 60 * 1000;
  const makeCode = options.makeCode || (() => String(randomInt(0, 1000000)).padStart(6, '0'));

  function cleanEmail(email) {
    return String(email || '').trim().toLowerCase();
  }

  function normalizePurpose(purpose) {
    const value = String(purpose || '').trim().toLowerCase();
    return PURPOSES.has(value) ? value : '';
  }

  function storageKey(email, purpose) {
    return `${purpose}\n${cleanEmail(email)}`;
  }

  function prepare(email, purpose, hasProvider) {
    const clean = cleanEmail(email);
    const use = normalizePurpose(purpose);
    if (!clean || !clean.includes('@')) {
      return { ok: false, status: 400, error: 'Adresse email requise.' };
    }
    if (!use) {
      return { ok: false, status: 400, error: 'Usage OTP invalide.' };
    }
    if (!hasProvider) {
      return { ok: false, status: 503, error: 'Aucun fournisseur de messagerie configuré sur le serveur.' };
    }
    const quotaKey = storageKey(clean, use);
    const quota = sends.get(quotaKey);
    if (quota && now() - quota.start < sendWindowMs && quota.count >= maxSends) {
      return { ok: false, status: 429, error: 'Trop d\'envois pour cette adresse. Réessayez plus tard.' };
    }
    return { ok: true, email: clean, purpose: use, code: makeCode(), expiresAt: now() + ttlMs };
  }

  function commit(email, purpose, code, provider) {
    const use = normalizePurpose(purpose);
    const key = storageKey(email, use);
    const quota = sends.get(key);
    if (!quota || now() - quota.start >= sendWindowMs) {
      sends.set(key, { start: now(), count: 1 });
    } else {
      quota.count += 1;
    }
    store.set(key, {
      code: String(code),
      expiresAt: now() + ttlMs,
      delivered: true,
      attempts: 0,
      purpose: use
    });
    return { ok: true, status: 200, provider: provider || 'serveur', purpose: use };
  }

  function abort(email, purpose) {
    store.delete(storageKey(email, normalizePurpose(purpose)));
  }

  function verify(email, token, purpose, consume = true) {
    const use = normalizePurpose(purpose);
    const key = storageKey(email, use);
    const row = store.get(key);
    const given = String(token || '').trim();
    if (!use || !row || !row.delivered || row.purpose !== use || !given) {
      return { ok: false, status: 400, error: 'Code OTP incorrect ou expiré.' };
    }
    if (now() > row.expiresAt) {
      if (store.get(key) === row) store.delete(key);
      return { ok: false, status: 400, error: 'Code OTP incorrect ou expiré.' };
    }
    row.attempts += 1;
    if (row.attempts > maxAttempts) {
      if (store.get(key) === row) store.delete(key);
      return { ok: false, status: 429, error: 'Trop de tentatives. Demandez un nouveau code.' };
    }
    if (row.code !== given) {
      return { ok: false, status: 400, error: 'Code OTP incorrect ou expiré.' };
    }
    if (consume) {
      if (store.get(key) !== row) {
        return { ok: false, status: 400, error: 'Code OTP incorrect ou expiré.' };
      }
      store.delete(key);
    }
    return { ok: true, status: 200, email: cleanEmail(email), purpose: use };
  }

  function toClient(result) {
    if (!result) return { success: false };
    const body = { success: Boolean(result.ok) };
    if (result.provider) body.provider = result.provider;
    if (result.purpose) body.purpose = result.purpose;
    if (!result.ok) body.error = result.error || 'Opération refusée.';
    return body;
  }

  return { prepare, commit, abort, verify, toClient, PURPOSES };
}

module.exports = { createOtpBroker, PURPOSES };
