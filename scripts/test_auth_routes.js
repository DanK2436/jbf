#!/usr/bin/env node
/**
 * Routes Express réelles, Supabase et fournisseurs simulés. Aucun réseau.
 */
const Module = require('module');
const path = require('path');

const calls = { createUser: 0, fetch: 0 };
let lastHtml = '';

const supabaseEntry = require.resolve('@supabase/supabase-js', {
  paths: [path.join(__dirname, '../backend')]
});
require.cache[supabaseEntry] = {
  id: supabaseEntry,
  filename: supabaseEntry,
  loaded: true,
  exports: {
    createClient() {
      return {
        auth: {
          admin: {
            async createUser() {
              calls.createUser += 1;
              return { data: { user: { id: 'user-fixture' } }, error: null };
            },
            async listUsers() {
              return { data: { users: [] } };
            },
            async updateUserById() {
              return { error: null };
            }
          },
          async signInWithPassword() {
            return { data: { session: null, user: null }, error: null };
          }
        },
        from() {
          return {
            upsert: async () => ({ error: null }),
            insert() {
              return { select: () => ({ single: async () => ({ data: { id: 'p1', role: 'client' } }) }) };
            },
            select() {
              return {
                eq: () => ({ maybeSingle: async () => ({ data: null }) }),
                in: () => ({ order: async () => ({ data: [], error: null }) }),
                order: async () => ({ data: [], error: null }),
                limit: async () => ({ data: [], error: null })
              };
            },
            delete: () => ({ eq: async () => ({ error: null }) })
          };
        }
      };
    }
  }
};

process.env.SUPABASE_URL = 'http://127.0.0.1:9';
process.env.SUPABASE_SERVICE_ROLE_KEY = 'fixture-service-role';
process.env.SUPABASE_ANON_KEY = 'fixture-anon';
process.env.BREVO_API_KEY = 'fixture-brevo';
process.env.RESEND_API_KEY = 'fixture-resend';
process.env.ADMIN_OFFICIAL_PASSWORD = '';
process.env.JBF_DISABLE_LISTEN = '1';

const nativeFetch = global.fetch.bind(global);
function installFetch(mode) {
  global.fetch = async (url, opts) => {
    const target = String(url);
    if (target.startsWith('http://127.0.0.1:') || target.startsWith('http://localhost:')) {
      return nativeFetch(url, opts);
    }
    if (!/brevo\.com|resend\.com/.test(target)) {
      throw new Error('réseau inattendu ' + target);
    }
    calls.fetch += 1;
    const body = JSON.parse((opts && opts.body) || '{}');
    lastHtml = body.htmlContent || body.html || '';
    if (mode === 'fail') return { ok: false, status: 502, json: async () => ({ message: 'mock' }) };
    return { ok: true, status: 200, json: async () => ({}) };
  };
}
installFetch('ok');

const { app } = require('../backend/server');

function codeFromMail() {
  const match = String(lastHtml).match(/>(\d{6})</);
  if (!match) throw new Error('code absent du message simulé');
  return match[1];
}

async function post(urlPath, body) {
  const server = await new Promise((resolve) => {
    const listening = app.listen(0, '127.0.0.1', () => resolve(listening));
  });
  const port = server.address().port;
  try {
    const res = await fetch(`http://127.0.0.1:${port}${urlPath}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body || {})
    });
    const data = await res.json().catch(() => ({}));
    return { status: res.status, data, headers: res.headers };
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

function assert(name, ok) {
  if (!ok) {
    console.error('ÉCHEC', name);
    process.exit(1);
  }
}

(async () => {
  const bare = await post('/api/auth/register', {
    email: 'a@example.test',
    password: 'fixture-pass-1',
    full_name: 'Fixture'
  });
  assert('sans code', bare.status === 400 && calls.createUser === 0);
  assert('en-tête sur refus', bare.headers.get('x-frame-options') === 'DENY');

  const wrong = await post('/api/auth/register', {
    email: 'a@example.test',
    password: 'fixture-pass-1',
    full_name: 'Fixture',
    token: '000000'
  });
  assert('faux code', wrong.status === 400 && calls.createUser === 0);

  const sentLogin = await post('/api/auth/otp/send', { email: 'a@example.test', purpose: 'login' });
  assert('envoi login', sentLogin.status === 200 && !JSON.stringify(sentLogin.data).match(/\d{6}/));
  const loginCode = codeFromMail();
  const cross = await post('/api/auth/register', {
    email: 'a@example.test',
    password: 'fixture-pass-1',
    full_name: 'Fixture',
    token: loginCode
  });
  assert('usage login refusé pour inscription', cross.status === 400 && calls.createUser === 0);

  const otherMail = await post('/api/auth/register', {
    email: 'b@example.test',
    password: 'fixture-pass-1',
    full_name: 'Fixture',
    token: loginCode
  });
  assert('email différent', otherMail.status === 400 && calls.createUser === 0);

  const sentReg = await post('/api/auth/otp/send', { email: 'a@example.test', purpose: 'register' });
  assert('envoi register', sentReg.status === 200);
  const regCode = codeFromMail();
  const asLogin = await post('/api/auth/otp/verify', { email: 'a@example.test', token: regCode });
  assert('register ne valide pas le login', asLogin.status === 400 && calls.createUser === 0);

  const created = await post('/api/auth/register', {
    email: 'a@example.test',
    password: 'fixture-pass-1',
    full_name: 'Fixture Nom',
    phone: '+243800000000',
    company: 'Fixture SARL',
    secteur: 'Mines',
    token: regCode
  });
  assert('création unique', created.status === 200 && calls.createUser === 1 && created.data.success === true);

  const replay = await post('/api/auth/register', {
    email: 'a@example.test',
    password: 'fixture-pass-1',
    full_name: 'Fixture Nom',
    token: regCode
  });
  assert('rejeu refusé', replay.status === 400 && calls.createUser === 1);

  const sentReset = await post('/api/auth/reset-otp/send', { email: 'a@example.test' });
  assert('envoi reset', sentReset.status === 200);
  const resetCode = codeFromMail();
  const resetAsRegister = await post('/api/auth/register', {
    email: 'a@example.test',
    password: 'fixture-pass-1',
    full_name: 'Fixture',
    token: resetCode
  });
  assert('reset ne crée pas de compte', resetAsRegister.status === 400 && calls.createUser === 1);
  const resetOk = await post('/api/auth/reset-password', {
    email: 'a@example.test',
    token: resetCode,
    newPassword: 'fixture-pass-2'
  });
  assert('reset consommé sans createUser', resetOk.status === 200 && calls.createUser === 1);

  const beforeFetch = calls.fetch;
  delete process.env.BREVO_API_KEY;
  delete process.env.RESEND_API_KEY;
  const noProv = await post('/api/auth/otp/send', { email: 'c@example.test', purpose: 'register' });
  assert('provider absent', noProv.status === 503 && calls.fetch === beforeFetch && calls.createUser === 1);
  process.env.BREVO_API_KEY = 'fixture-brevo';

  installFetch('fail');
  const failed = await post('/api/auth/otp/send', { email: 'd@example.test', purpose: 'register' });
  assert('provider en échec', failed.status === 503 && calls.createUser === 1);
  const afterFail = await post('/api/auth/register', {
    email: 'd@example.test',
    password: 'fixture-pass-1',
    full_name: 'Fixture',
    token: '135790'
  });
  assert('échec sans code actif', afterFail.status === 400 && calls.createUser === 1);

  const staff = await post('/api/admin/membres', {
    email: 'staff@example.test',
    password: 'fixture-pass-1',
    full_name: 'Staff'
  });
  const sub = await post('/api/admin/sous-admins', {
    email: 'sub@example.test',
    password: 'fixture-pass-1',
    full_name: 'Sub'
  });
  assert('routes staff fermées', staff.status === 403 && sub.status === 403 && calls.createUser === 1);

  console.log('OK routes Express OTP (Supabase et fournisseurs simulés)');
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
