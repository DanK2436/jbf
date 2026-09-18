const https = require('https');
const path = require('path');
const fs = require('fs');

function loadEnv() {
  const envPath = path.resolve(__dirname, '../backend/.env');
  if (fs.existsSync(envPath)) {
    const lines = fs.readFileSync(envPath, 'utf-8').split('\n');
    lines.forEach(l => {
      const trimmed = l.trim();
      if (trimmed && !trimmed.startsWith('#') && trimmed.includes('=')) {
        const [k, ...v] = trimmed.split('=');
        process.env[k.trim()] = v.join('=').trim();
      }
    });
  }
}
loadEnv();

const SUPABASE_URL = (process.env.SUPABASE_URL || 'https://dvzwqxcaiagczyonrhsg.supabase.co').replace(/^https?:\/\//, '');
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

function checkEndpoint(path, method = 'GET', body = null) {
  return new Promise((resolve) => {
    const data = body ? JSON.stringify(body) : '';
    const req = https.request({
      hostname: SUPABASE_URL,
      path: path,
      method: method,
      headers: {
        'apikey': SERVICE_KEY,
        'Authorization': 'Bearer ' + SERVICE_KEY,
        'Content-Type': 'application/json',
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {})
      }
    }, (res) => {
      let buf = '';
      res.on('data', chunk => buf += chunk);
      res.on('end', () => resolve({ status: res.statusCode, data: buf }));
    });
    req.on('error', err => resolve({ error: err.message }));
    if (data) req.write(data);
    req.end();
  });
}

(async () => {
  const r1 = await checkEndpoint('/rest/v1/');
  console.log('REST root:', r1.status, (r1.data || r1.error || '').slice(0, 300));

  const tables = ['profiles', 'demandes_devis', 'missions', 'ressources_hse', 'tickets_support', 'devis_equipes'];
  for (const t of tables) {
    const res = await checkEndpoint(`/rest/v1/${t}?select=count`, 'HEAD');
    console.log(`Table ${t}: status=${res.status}`);
  }
})();
