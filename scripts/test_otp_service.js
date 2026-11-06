#!/usr/bin/env node
/** OTP : usages séparés, expiration, tentatives, sans réseau. */
const { createOtpBroker } = require('../backend/otp-service');

const failures = [];
function check(name, ok) {
  if (!ok) failures.push(name);
}

let clock = 1_000_000;
const broker = createOtpBroker({
  now: () => clock,
  ttlMs: 1000,
  maxAttempts: 3,
  maxSends: 2,
  sendWindowMs: 5000,
  makeCode: () => '135790'
});

const missing = broker.prepare('user@example.test', 'login', false);
check('provider absent', missing.ok === false && missing.status === 503);

const badUse = broker.prepare('user@example.test', 'login', true);
broker.abort(badUse.email, 'login');
check('échec avant commit', broker.verify('user@example.test', '135790', 'login').ok === false);

const login = broker.prepare('user@example.test', 'login', true);
broker.commit(login.email, 'login', login.code, 'brevo', login.reservationId);
const pub = broker.toClient({ ok: true, provider: 'brevo', purpose: 'login' });
check('réponse sans code', pub.success === true && !JSON.stringify(pub).includes('135790'));
check('faux code', broker.verify('user@example.test', '000000', 'login').ok === false);
check('mauvais usage', broker.verify('user@example.test', '135790', 'register').ok === false);
check('login encore valide', broker.verify('user@example.test', '135790', 'login', true).ok === true);
check('rejeu refusé', broker.verify('user@example.test', '135790', 'login').ok === false);

const reg = broker.prepare('user@example.test', 'register', true);
broker.commit(reg.email, 'register', '246813', 'resend', reg.reservationId);
check('reset ne consomme pas register', broker.verify('user@example.test', '246813', 'reset').ok === false);
check('register ok', broker.verify('user@example.test', '246813', 'register', true).ok === true);

const exp = createOtpBroker({ now: () => clock, ttlMs: 400, makeCode: () => '111111' });
const issued = exp.prepare('expire@example.test', 'reset', true);
exp.commit(issued.email, 'reset', issued.code, 'brevo', issued.reservationId);
clock += 401;
check('expiration', exp.verify('expire@example.test', '111111', 'reset').ok === false);

const tries = createOtpBroker({ now: () => clock, maxAttempts: 2, makeCode: () => '222222' });
const row = tries.prepare('try@example.test', 'login', true);
tries.commit(row.email, 'login', row.code, 'brevo', row.reservationId);
check('tentative 1', tries.verify('try@example.test', '000000', 'login').ok === false);
check('tentative 2', tries.verify('try@example.test', '000000', 'login').ok === false);
check('trop de tentatives', tries.verify('try@example.test', '222222', 'login').status === 429);

const quota = createOtpBroker({ now: () => clock, maxSends: 2, sendWindowMs: 1000, makeCode: () => '333333' });
const q1 = quota.prepare('quota@example.test', 'login', true);
const q2 = quota.prepare('quota@example.test', 'login', true);
const q3 = quota.prepare('quota@example.test', 'login', true);
check('quota réservé avant commit', q1.ok && q2.ok && q3.status === 429);
quota.abort(q1.email, 'login', q1.reservationId);
check('échec ne rend pas le quota', quota.prepare('quota@example.test', 'login', true).status === 429);
clock += 1001;
check('fenêtre rouverte', quota.prepare('quota@example.test', 'login', true).ok === true);

const order = createOtpBroker({ now: () => clock, makeCode: () => String(900000 + order._n++) });
order._n = 1;
const first = order.prepare('order@example.test', 'reset', true);
const second = order.prepare('order@example.test', 'reset', true);
const lateFirst = order.commit(first.email, 'reset', first.code, 'brevo', first.reservationId);
check('réponse ancienne ignorée', lateFirst.stale === true && order.verify('order@example.test', first.code, 'reset', false).ok === false);
order.commit(second.email, 'reset', second.code, 'resend', second.reservationId);
check('code récent actif', order.verify('order@example.test', second.code, 'reset', true).ok === true);
check('code ancien refusé', order.verify('order@example.test', first.code, 'reset').ok === false);

if (failures.length) {
  console.error('ÉCHEC', failures.join(', '));
  process.exit(1);
}
console.log('OK OTP usages séparés (mock)');
