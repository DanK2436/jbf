#!/usr/bin/env node
/**
 * Applique le schéma JBF sur Supabase PostgreSQL.
 *
 * Variables (backend/.env ou environnement) :
 *   SUPABASE_URL=https://xxxx.supabase.co
 *   SUPABASE_SERVICE_ROLE_KEY=eyJ...   (vérifie les tables via API)
 *   SUPABASE_DB_URL=postgresql://postgres.[ref]:[PWD]@aws-0-eu-central-1.pooler.supabase.com:6543/postgres
 *     — OU —
 *   SUPABASE_DB_PASSWORD=mot_de_passe_db   (Settings → Database dans Supabase)
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { createClient } from '@supabase/supabase-js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');

function loadDotEnv(filePath) {
  if (!fs.existsSync(filePath)) return;
  for (const line of fs.readFileSync(filePath, 'utf8').split('\n')) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const i = t.indexOf('=');
    if (i <= 0) continue;
    const k = t.slice(0, i).trim();
    let v = t.slice(i + 1).trim();
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
      v = v.slice(1, -1);
    }
    if (!process.env[k]) process.env[k] = v;
  }
}

loadDotEnv(path.join(root, 'backend', '.env'));

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://dvzwqxcaiagczyonrhsg.supabase.co';
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
const DB_URL = process.env.SUPABASE_DB_URL || '';
const DB_PASSWORD = process.env.SUPABASE_DB_PASSWORD || '';

function projectRefFromUrl(url) {
  try {
    const h = new URL(url).hostname;
    return h.split('.')[0];
  } catch {
    return '';
  }
}

function buildPoolerUrl(ref, password) {
  if (!ref || !password) return '';
  const region = process.env.SUPABASE_DB_REGION || 'eu-central-1';
  const enc = encodeURIComponent(password);
  return `postgresql://postgres.${ref}:${enc}@aws-0-${region}.pooler.supabase.com:6543/postgres?sslmode=require`;
}

const includeSeed = process.argv.includes('--seed');

const sqlFiles = [
  path.join(root, 'database_schema.sql'),
  path.join(__dirname, 'migrations', '20261019_password_reset_challenges.sql'),
  path.join(__dirname, 'migrations', '20261019_blog_posts.sql'),
];
if (includeSeed) {
  sqlFiles.push(path.join(__dirname, 'seed.sql'));
}

async function applyWithPg(connectionString) {
  const pg = await import('pg');
  const client = new pg.default.Client({ connectionString, ssl: { rejectUnauthorized: false } });
  await client.connect();
  console.log('✅ Connecté à PostgreSQL Supabase');

  for (const file of sqlFiles) {
    if (!fs.existsSync(file)) {
      console.warn('⚠️  Fichier absent:', file);
      continue;
    }
    const sql = fs.readFileSync(file, 'utf8');
    console.log(`▶ Exécution: ${path.relative(root, file)}`);
    await client.query(sql);
    console.log(`   OK`);
  }

  await client.end();
}

async function verifyWithServiceRole() {
  if (!SERVICE_KEY) {
    console.warn('⚠️  SUPABASE_SERVICE_ROLE_KEY absent — vérification API ignorée.');
    return;
  }
  const admin = createClient(SUPABASE_URL, SERVICE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const tables = [
    'profiles', 'admin_accounts', 'demandes_devis', 'missions', 'blog_posts',
    'gallery_images', 'password_reset_challenges', 'config_cles_api',
  ];

  console.log('\n📋 Vérification des tables (REST API):');
  for (const table of tables) {
    const { error } = await admin.from(table).select('*', { head: true, count: 'exact' }).limit(1);
    if (error) {
      console.log(`   ❌ ${table}: ${error.message}`);
    } else {
      console.log(`   ✅ ${table}`);
    }
  }
}

async function main() {
  const ref = projectRefFromUrl(SUPABASE_URL);
  let conn = DB_URL || buildPoolerUrl(ref, DB_PASSWORD);

  if (!conn) {
    console.error(`
❌ Connexion SQL impossible.

Ajoutez dans backend/.env :
  SUPABASE_URL=https://VOTRE_REF.supabase.co
  SUPABASE_SERVICE_ROLE_KEY=eyJ...
  SUPABASE_DB_PASSWORD=mot_de_passe_database

Ou directement :
  SUPABASE_DB_URL=postgresql://postgres.[ref]:[PWD]@...pooler.supabase.com:6543/postgres

Mot de passe DB : Supabase Dashboard → Project Settings → Database → Database password
`);
    process.exit(1);
  }

  try {
    await applyWithPg(conn);
    console.log('\n🎉 Schéma appliqué avec succès.');
  } catch (err) {
    console.error('\n❌ Erreur SQL:', err.message);
    process.exit(1);
  }

  await verifyWithServiceRole();
}

main();
