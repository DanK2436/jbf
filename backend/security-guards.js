/**
 * Garde-fous partagés par le serveur Express.
 * Aucun secret : uniquement des comparaisons et des en-têtes.
 */

const SECURITY_CSP = [
  "default-src 'self'",
  "base-uri 'self'",
  "object-src 'none'",
  "frame-ancestors 'none'",
  "form-action 'self'",
  "script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'",
  "style-src 'self' https://cdn.jsdelivr.net https://fonts.googleapis.com 'unsafe-inline'",
  "font-src 'self' https://fonts.gstatic.com https://cdn.jsdelivr.net data:",
  "img-src 'self' data: blob: https:",
  "connect-src 'self' https://*.supabase.co https://cdn.jsdelivr.net http://127.0.0.1:* http://localhost:*"
].join('; ');

const SECURITY_HEADERS = {
  'Content-Security-Policy': SECURITY_CSP,
  'X-Frame-Options': 'DENY',
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'strict-origin-when-cross-origin'
};

function isOfficialAdminPassword(configured, password) {
  const secret = String(configured || '').trim();
  const given = String(password || '');
  if (!secret || !given.trim()) return false;
  return given === secret || given.trim() === secret;
}

function formatOtpLog(channel, destination) {
  return `[${channel}] Code OTP traité pour ${destination} (valeur non journalisée)`;
}

function decodeRequestPath(urlPath) {
  let decoded = String(urlPath || '').split('?')[0];
  if (decoded.includes('\0') || /%00/i.test(decoded)) return null;
  for (let i = 0; i < 5; i += 1) {
    let next;
    try {
      next = decodeURIComponent(decoded);
    } catch (_) {
      return null;
    }
    if (next === decoded) break;
    decoded = next;
  }
  if (decoded.includes('\\') || decoded.includes('\0')) return null;
  const parts = [];
  for (const part of decoded.split('/')) {
    if (!part || part === '.') continue;
    if (part === '..' || part.startsWith('.')) return null;
    parts.push(part);
  }
  return parts;
}

function publicAssetAllowed(urlPath) {
  const parts = decodeRequestPath(urlPath);
  if (!parts) return false;
  if (parts.length === 0) return true;
  if (parts.length === 1 && parts[0] === 'index.html') return true;
  if (['JBF Public', 'JBF Client', 'assets', 'js'].includes(parts[0])) return true;
  if (parts[0] === 'supabase' && parts.length === 2 && parts[1].endsWith('.js')) return true;
  return false;
}

function applySecurityHeaders(req, res, next) {
  Object.entries(SECURITY_HEADERS).forEach(([name, value]) => {
    res.setHeader(name, value);
  });
  if (typeof next === 'function') next();
}

/**
 * Le relais de contenu libre n'a pas de contrôle serveur authentifié.
 * L'adresse loopback, Origin et Sec-Fetch-Site sont forgeables, et un
 * reverse proxy peut présenter un client distant comme local.
 * Tant qu'aucun secret serveur dédié n'existe, le relais reste fermé.
 */
function arbitraryMailRelayEnabled() {
  return false;
}

module.exports = {
  SECURITY_CSP,
  SECURITY_HEADERS,
  isOfficialAdminPassword,
  formatOtpLog,
  decodeRequestPath,
  publicAssetAllowed,
  applySecurityHeaders,
  arbitraryMailRelayEnabled
};
