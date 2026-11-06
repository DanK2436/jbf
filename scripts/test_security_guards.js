#!/usr/bin/env node
/**
 * Mot de passe admin fail-closed et absence d'OTP dans les journaux.
 * Aucun secret réel.
 */
const fs = require('fs');
const path = require('path');
const {
  isOfficialAdminPassword,
  formatOtpLog,
  publicAssetAllowed,
  arbitraryMailRelayEnabled,
  applySecurityHeaders
} = require('../backend/security-guards');

const FAKE_OTP = '246813';
const FAKE_PASSWORD = 'fixture-pass-not-secret';
const failures = [];

function check(name, ok) {
  if (!ok) failures.push(name);
}

check('absent', isOfficialAdminPassword(undefined, FAKE_PASSWORD) === false);
check('vide', isOfficialAdminPassword('', FAKE_PASSWORD) === false);
check('espaces', isOfficialAdminPassword('   ', '   ') === false);
check('incorrect', isOfficialAdminPassword(FAKE_PASSWORD, 'incorrect') === false);
check('correct', isOfficialAdminPassword(FAKE_PASSWORD, FAKE_PASSWORD) === true);

const logs = [];
const original = console.log;
console.log = (...args) => logs.push(args.join(' '));
console.log(formatOtpLog('Backend OTP', 'fixture@example.test'));
console.log = original;
const joined = logs.join('\n');
check('log sans otp', !joined.includes(FAKE_OTP) && joined.includes('non journalisée'));

const serverSrc = fs.readFileSync(path.join(__dirname, '..', 'backend', 'server.js'), 'utf8');
const serveSrc = fs.readFileSync(path.join(__dirname, '..', 'serve.py'), 'utf8');
const logLines = serverSrc.split('\n').filter((line) => line.includes('console.log') && /otp/i.test(line));
check('server.js ne journalise pas otpCode', logLines.every((line) => !line.includes('otpCode') && !line.includes('${otp')));
check('serve.py ne journalise plus le code', !serveSrc.includes('CODE DE CONNEXION') && !serveSrc.includes('otp_match.group(1)'));

check('backend/.env bloqué', publicAssetAllowed('/backend/.env') === false);
check('double encodage bloqué', publicAssetAllowed('/%252e%252e/backend/.env') === false);
check('dotfile bloqué', publicAssetAllowed('/.git/HEAD') === false);
check('asset public', publicAssetAllowed('/JBF%20Public/index.html') === true);
check('relais arbitraire fermé', arbitraryMailRelayEnabled() === false);
check('en-têtes avant les routes', (() => {
  const headerAt = serverSrc.indexOf('app.use(applySecurityHeaders)');
  const firstPost = serverSrc.indexOf('app.post(');
  const firstGet = serverSrc.indexOf('app.get(');
  const firstRoute = [firstPost, firstGet].filter((n) => n >= 0).sort((a, b) => a - b)[0];
  return headerAt >= 0 && headerAt < firstRoute;
})());
check('navigateur sans clé messagerie', (() => {
  const mail = fs.readFileSync(path.join(__dirname, '..', 'supabase', 'mail-service.js'), 'utf8');
  return !mail.includes('ENV_BREVO_API_KEY') && !mail.includes('api.brevo.com') && !mail.includes('api.resend.com') && !mail.includes('simulated: true');
})());

if (failures.length) {
  console.error('ÉCHEC', failures.join(', '));
  process.exit(1);
}
console.log('OK gardes admin/OTP/fichiers/relais');
