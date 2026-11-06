#!/usr/bin/env node
/**
 * En-têtes de sécurité sur réponses API, sans réseau externe.
 */
const http = require('http');
const path = require('path');
const express = require(require.resolve('express', { paths: [path.join(__dirname, '../backend')] }));
const { applySecurityHeaders, SECURITY_HEADERS } = require('../backend/security-guards');

function assertHeaders(res, label) {
  for (const [name, value] of Object.entries(SECURITY_HEADERS)) {
    const got = res.headers[name.toLowerCase()];
    if (got !== value) {
      console.error('ÉCHEC', label, name, got);
      process.exit(1);
    }
  }
  if (!String(res.headers['content-security-policy'] || '').includes("frame-ancestors 'none'")) {
    console.error('ÉCHEC', label, 'frame-ancestors');
    process.exit(1);
  }
  if (res.headers['x-frame-options'] !== 'DENY') {
    console.error('ÉCHEC', label, 'X-Frame-Options');
    process.exit(1);
  }
}

const app = express();
app.use(applySecurityHeaders);
app.get('/api/ok', (req, res) => res.status(200).json({ success: true }));
app.get('/api/private', (req, res) => res.status(401).json({ success: false }));
app.get('/api/blocked', (req, res) => res.status(403).json({ success: false }));
app.get('/api/boom', (req, res, next) => next(new Error('isolé')));
app.use((req, res) => res.status(404).json({ success: false, error: 'introuvable' }));
app.use((err, req, res, next) => {
  res.status(500).json({ success: false, error: 'erreur isolée' });
});

const server = app.listen(0, '127.0.0.1', async () => {
  const port = server.address().port;
  const paths = [
    ['/api/ok', 200],
    ['/api/private', 401],
    ['/api/blocked', 403],
    ['/api/absent', 404],
    ['/api/boom', 500]
  ];
  try {
    for (const [urlPath, expect] of paths) {
      const res = await fetch(`http://127.0.0.1:${port}${urlPath}`);
      if (res.status !== expect) {
        console.error('ÉCHEC statut', urlPath, res.status);
        process.exit(1);
      }
      assertHeaders({ headers: Object.fromEntries(res.headers.entries()) }, urlPath);
    }
    console.log('OK en-têtes sur 200, 401, 403, 404 et 500');
  } finally {
    server.close();
  }
});
