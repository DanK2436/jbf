/**
 * Codes OTP émis par le serveur JBF.
 * Brevo et Resend ne font que transporter le message : la vérification est ici.
 * Le code n'est jamais inclus dans l'objet renvoyé au client HTTP.
 */

function createOtpBroker(options = {}) {
  const store = new Map();
  const now = options.now || (() => Date.now());
  const ttlMs = options.ttlMs || 10 * 60 * 1000;
  const makeCode = options.makeCode || (() => String(Math.floor(100000 + Math.random() * 900000)));

  function cleanEmail(email) {
    return String(email || '').trim().toLowerCase();
  }

  function prepare(email, hasProvider) {
    const clean = cleanEmail(email);
    if (!clean || !clean.includes('@')) {
      return { ok: false, status: 400, error: 'Adresse email requise.' };
    }
    if (!hasProvider) {
      return { ok: false, status: 503, error: 'Aucun fournisseur de messagerie configuré sur le serveur.' };
    }
    return { ok: true, email: clean, code: makeCode(), expiresAt: now() + ttlMs };
  }

  function commit(email, code, provider) {
    const clean = cleanEmail(email);
    store.set(clean, {
      code: String(code),
      expiresAt: now() + ttlMs,
      delivered: true
    });
    return { ok: true, status: 200, provider: provider || 'serveur' };
  }

  function abort(email) {
    store.delete(cleanEmail(email));
  }

  function verify(email, token, consume = true) {
    const clean = cleanEmail(email);
    const given = String(token || '').trim();
    const row = store.get(clean);
    if (!row || !row.delivered || !given) {
      return { ok: false, status: 400, error: 'Code OTP incorrect ou expiré.' };
    }
    if (now() > row.expiresAt) {
      store.delete(clean);
      return { ok: false, status: 400, error: 'Code OTP incorrect ou expiré.' };
    }
    if (row.code !== given) {
      return { ok: false, status: 400, error: 'Code OTP incorrect ou expiré.' };
    }
    if (consume) store.delete(clean);
    return { ok: true, status: 200, email: clean };
  }

  function toClient(result) {
    if (!result) return { success: false };
    const body = { success: Boolean(result.ok), provider: result.provider };
    if (!result.ok) body.error = result.error || 'Opération refusée.';
    return body;
  }

  return { prepare, commit, abort, verify, toClient, _store: store };
}

module.exports = { createOtpBroker };
