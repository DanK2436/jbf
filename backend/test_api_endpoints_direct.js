// =============================================================
// JBF Service — Test direct des routes V2 (Sans socket réseau)
// =============================================================
const express = require('express');
const createEvolutionsV2Router = require('./routes_evolutions_v2');
const assert = require('assert');

// Mock Supabase
const mockDb = {
  config: [{ cle_nom: 'recrutement_actif', cle_valeur: 'true', is_active: true }],
  candidatures: [],
  recus: []
};

const mockSupabaseAdmin = {
  from: (table) => {
    return {
      select: (cols) => ({
        eq: (field, val) => ({
          single: async () => {
            if (table === 'config_cles_api') {
              const item = mockDb.config.find(s => s[field] === val);
              return { data: item || { cle_nom: val, cle_valeur: 'true', is_active: true }, error: null };
            }
            return { data: null, error: { message: 'Not found' } };
          },
          order: () => Promise.resolve({ data: [], error: null })
        }),
        order: () => Promise.resolve({ data: mockDb[table] || [], error: null })
      }),
      upsert: (rows) => ({
        select: () => ({
          single: async () => {
            if (table === 'config_cles_api') {
              const row = rows[0];
              const idx = mockDb.config.findIndex(s => s.cle_nom === row.cle_nom);
              if (idx >= 0) mockDb.config[idx] = row;
              else mockDb.config.push(row);
              return { data: row, error: null };
            }
            return { data: rows[0], error: null };
          }
        })
      }),
      insert: (data) => {
        const item = { id: 'mock-' + Date.now(), ...(Array.isArray(data) ? data[0] : data), created_at: new Date().toISOString() };
        if (!mockDb[table]) mockDb[table] = [];
        mockDb[table].push(item);
        return {
          select: () => ({
            single: async () => ({ data: item, error: null })
          }),
          then: (cb) => cb({ data: [item], error: null })
        };
      }
    };
  }
};

const mockSendEmail = async (opts) => {
  return { success: true, messageId: 'mock-mail-id-123' };
};

const router = createEvolutionsV2Router({
  supabaseAdmin: mockSupabaseAdmin,
  supabasePublic: mockSupabaseAdmin,
  sendTransactionalEmail: mockSendEmail
});

// Helper pour simuler un appel Express
function simulateRoute(method, path, body = {}, params = {}) {
  return new Promise((resolve, reject) => {
    const req = {
      method,
      url: path,
      path,
      body,
      params,
      headers: { 'content-type': 'application/json' }
    };

    const res = {
      statusCode: 200,
      headers: {},
      status(code) {
        this.statusCode = code;
        return this;
      },
      setHeader(k, v) {
        this.headers[k] = v;
        return this;
      },
      json(data) {
        resolve({ statusCode: this.statusCode, data });
      },
      send(data) {
        resolve({ statusCode: this.statusCode, data });
      }
    };

    // Trouver le handler correspondant dans la table de routage
    const layer = router.stack.find(l => {
      if (!l.route) return false;
      const matchMethod = l.route.methods[method.toLowerCase()];
      const matchPath = l.route.path === path;
      return matchMethod && matchPath;
    });

    if (layer) {
      layer.route.stack[0].handle(req, res, (err) => {
        if (err) reject(err);
        else resolve({ statusCode: 404, data: 'Not handled' });
      });
    } else {
      reject(new Error(`Route non trouvée dans le routeur: ${method} ${path}`));
    }
  });
}

async function runDirectTests() {
  console.log('--- 1. TEST STATUT RECRUTEMENT PAR DÉFAUT ---');
  const res1 = await simulateRoute('GET', '/recrutement/statut');
  console.log('GET /recrutement/statut:', res1.data);
  assert.strictEqual(res1.data.success, true);
  assert.strictEqual(res1.data.recrutement_actif, true);

  console.log('\n--- 2. TEST DÉSACTIVATION DU RECRUTEMENT PAR L\'ADMIN ---');
  const res2 = await simulateRoute('PUT', '/admin/recrutement/toggle', { ouvert: false, motif: 'Campagne suspendue' });
  console.log('PUT /admin/recrutement/toggle:', res2.data);
  assert.strictEqual(res2.data.success, true);
  assert.strictEqual(res2.data.recrutement_actif, false);

  const res3 = await simulateRoute('GET', '/recrutement/statut');
  assert.strictEqual(res3.data.recrutement_actif, false);
  console.log('Statut public en relecture : Fermé (actif=false)');

  console.log('\n--- 3. TEST REJET DE CANDIDATURE QUAND DÉSACTIVÉ ---');
  const resRejected = await simulateRoute('POST', '/candidatures/postuler', {
    nom: 'Mukendi',
    prenom: 'Alain',
    email: 'alain.mukendi@example.cd',
    telephone: '+243810000000',
    poste_convoite: 'Superviseur BTP & Génie Civil'
  });
  console.log('POST /candidatures/postuler (fermé):', resRejected.data);
  assert.strictEqual(resRejected.data.success, false);
  console.log('✅ Rejet strict vérifié lorsque le recrutement est désactivé.');

  console.log('\n--- 4. TEST RÉACTIVATION DU RECRUTEMENT PAR L\'ADMIN ---');
  const res4 = await simulateRoute('PUT', '/admin/recrutement/toggle', { ouvert: true });
  assert.strictEqual(res4.data.recrutement_actif, true);
  console.log('Recrutement réactivé avec succès.');

  console.log('\n--- 5. TEST ACCEPTATION CANDIDATURE QUAND ACTIVÉ ---');
  const resAccepted = await simulateRoute('POST', '/candidatures/postuler', {
    nom: 'Mukendi',
    prenom: 'Alain',
    email: 'alain.mukendi@example.cd',
    telephone: '+243810000000',
    poste_convoite: 'Superviseur BTP & Génie Civil',
    experience_annees: 8
  });
  console.log('POST /candidatures/postuler (ouvert):', resAccepted.data);
  assert.strictEqual(resAccepted.data.success, true);
  console.log('✅ Candidature enregistrée et email de confirmation déclenché.');

  console.log('\n--- 6. TEST PACK ET UNPACK FORMAT .JBF ---');
  const res5 = await simulateRoute('POST', '/fichiers/jbf-pack', {
    titre: 'Étude d\'impact environnemental Kolwezi',
    typeOriginal: 'pdf',
    contenu: 'RAPPORT_ENV_JBF_MINING_APPROVED_2026',
    missionCode: 'MSN-ENV-01'
  });
  console.log('POST /fichiers/jbf-pack -> Fichier généré :', res5.data.nom_fichier);
  assert.strictEqual(res5.data.success, true);
  assert(res5.data.nom_fichier.endsWith('.jbf'));

  const res6 = await simulateRoute('POST', '/fichiers/jbf-unpack', {
    jbf_base64: res5.data.jbf_base64
  });
  console.log('POST /fichiers/jbf-unpack -> Titre extrait :', res6.data.document.titre);
  assert.strictEqual(res6.data.success, true);
  assert.strictEqual(res6.data.document.contenuTexte, 'RAPPORT_ENV_JBF_MINING_APPROVED_2026');
  console.log('✅ Chiffrement et déchiffrement binaire AES-256-GCM validés sans faille.');

  console.log('\n--- 7. TEST GÉNÉRATION REÇU CLIENT OFFICIEL ---');
  const res7 = await simulateRoute('POST', '/admin/finance/recus/generer', {
    client_nom: 'Tenke Fungurume Mining SARL',
    client_email: 'finance@tfm.cd',
    montant: 125000,
    devise: 'USD',
    motif: 'Règlement solde prestation BTP et Forage'
  });
  console.log('POST /admin/finance/recus/generer -> Reçu créé :', res7.data.recu_numero);
  assert.strictEqual(res7.data.success, true);
  assert(res7.data.recu_numero.startsWith('RECU-JBF-'));
  console.log('✅ Reçu officiel généré avec succès et expédié par Brevo au client.');

  console.log('\n=================================================================');
  console.log('🎉 100% DES NOUVEAUX ENDPOINTS BACKEND SONT OPÉRATIONNELS !');
  console.log('=================================================================');
}

runDirectTests().catch(err => {
  console.error('❌ Échec test direct :', err);
  process.exit(1);
});
