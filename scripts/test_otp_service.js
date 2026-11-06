#!/usr/bin/env node
/**
 * OTP serveur : succès, expiration, réutilisation, code faux, fournisseur absent ou en échec.
 * Aucun appel réseau.
 */
const { createOtpBroker } = require('../backend/otp-service');

const failures = [];
function check(name, ok) {
  if (!ok) failures.push(name);
}

async function main() {
  let clock = 1_000_000;
  const broker = createOtpBroker({
    now: () => clock,
    ttlMs: 1000,
    makeCode: () => '135790'
  });

  const missing = broker.prepare('user@example.test', false);
  check('provider absent', missing.ok === false && missing.status === 503);
  check('provider absent sans code stocké', broker.verify('user@example.test', '135790').ok === false);

  let sent = 0;
  const prepared = broker.prepare('user@example.test', true);
  check('prepare ne publie pas le code', !Object.prototype.hasOwnProperty.call(broker.toClient(prepared), 'code'));
  try {
    await Promise.reject(new Error('provider down'));
    sent += 1;
  } catch (_) {
    broker.abort(prepared.email);
  }
  check('échec fournisseur n\'active pas le code', broker.verify('user@example.test', '135790').ok === false && sent === 0);

  const again = broker.prepare('user@example.test', true);
  const committed = broker.commit(again.email, again.code, 'brevo');
  const clientBody = broker.toClient(committed);
  check('succès sans code dans la réponse', clientBody.success === true && clientBody.provider === 'brevo' && !JSON.stringify(clientBody).includes('135790'));
  check('code faux', broker.verify('user@example.test', '000000').ok === false);
  check('bon code encore utilisable après un faux', broker.verify('user@example.test', '135790', false).ok === true);
  check('consommation', broker.verify('user@example.test', '135790', true).ok === true);
  check('réutilisation refusée', broker.verify('user@example.test', '135790').ok === false);

  const expiring = createOtpBroker({ now: () => clock, ttlMs: 500, makeCode: () => '246813' });
  const issued = expiring.prepare('expire@example.test', true);
  expiring.commit(issued.email, issued.code, 'resend');
  clock += 501;
  check('expiration', expiring.verify('expire@example.test', '246813').ok === false);

  if (failures.length) {
    console.error('ÉCHEC', failures.join(', '));
    process.exit(1);
  }
  console.log('OK OTP serveur (mock, sans envoi)');
}

main();
