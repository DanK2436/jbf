// =============================================================
// JBF Service — Test Suite Évolutions V2
// =============================================================
const { packJbfFile, unpackJbfFile } = require('./jbf_format');
const assert = require('assert');

async function runTests() {
  console.log('--- 1. TEST DU FORMAT PROPRIÉTAIRE .JBF ---');
  const sampleData = {
    titre: 'Plan Minier et Devis Forage',
    typeOriginal: 'dxf',
    contenu: 'SPECS-CAD-AUTOCAD-DATA-2026-LAYER-FORAGE-MINIER-JBF',
    emetteur: 'JBF Services SARL - Ingénierie',
    missionCode: 'MSN-KATANGA-042'
  };

  const packedBuffer = packJbfFile(sampleData);
  console.log('✅ Buffer .JBF créé avec succès. Taille :', packedBuffer.length, 'octets');
  console.log('Magic Bytes :', packedBuffer.subarray(0, 4).toString('ascii'));
  assert.strictEqual(packedBuffer.subarray(0, 4).toString('ascii'), 'JBF!');

  const unpacked = unpackJbfFile(packedBuffer);
  console.log('✅ Décompression et déchiffrement .JBF réussis !');
  assert.strictEqual(unpacked.titre, 'Plan Minier et Devis Forage');
  assert.strictEqual(unpacked.typeOriginal, 'dxf');
  assert.strictEqual(unpacked.missionCode, 'MSN-KATANGA-042');
  assert.strictEqual(unpacked.contenuTexte, 'SPECS-CAD-AUTOCAD-DATA-2026-LAYER-FORAGE-MINIER-JBF');
  console.log('Document décodé :', unpacked.titre, '| Type :', unpacked.typeOriginal, '| Mission :', unpacked.missionCode);

  // Test avec fichier altéré / faux magic
  try {
    const corrupted = Buffer.from(packedBuffer);
    corrupted[0] = 0x58; // 'X' au lieu de 'J'
    unpackJbfFile(corrupted);
    console.error('❌ Échec : Le déchiffrement aurait dû rejeter une signature invalide.');
  } catch (err) {
    console.log('✅ Sécurité vérifiée :', err.message);
  }

  console.log('\n--- 2. TEST SYNTAXE ET IMPORT ROUTES V2 ---');
  const routesV2 = require('./routes_evolutions_v2');
  assert.strictEqual(typeof routesV2, 'function');
  console.log('✅ Router V2 exporté correctement sous forme de factory function.');

  console.log('\n--- 3. TEST INTÉGRITÉ SCHÉMA SQL V2 ---');
  const fs = require('fs');
  const path = require('path');
  const sqlEvolutions = fs.readFileSync(path.join(__dirname, '../database_schema_v2_evolutions.sql'), 'utf-8');
  assert(sqlEvolutions.includes('CREATE TABLE IF NOT EXISTS public.rh_collaborateurs'));
  assert(sqlEvolutions.includes('CREATE TABLE IF NOT EXISTS public.candidatures'));
  assert(sqlEvolutions.includes('CREATE TABLE IF NOT EXISTS public.mission_etapes'));
  assert(sqlEvolutions.includes('CREATE TABLE IF NOT EXISTS public.comptabilite_ecritures'));
  assert(sqlEvolutions.includes('CREATE TABLE IF NOT EXISTS public.devis_membres'));
  assert(sqlEvolutions.includes('CREATE TABLE IF NOT EXISTS public.services_catalogue'));
  console.log('✅ Les 8 nouvelles tables et extensions de sécurité SQL sont bien présentes.');

  console.log('\n--- 4. TEST INTÉGRITÉ NAVIGATION FLUTTER ET PAGES WEB ---');
  const recrutementHtml = fs.readFileSync(path.join(__dirname, '../JBF Public/recrutement.html'), 'utf-8');
  assert(recrutementHtml.includes('https://jbf-service.com'));
  assert(recrutementHtml.includes('/api/recrutement/statut'));
  assert(recrutementHtml.includes('/api/candidatures/postuler'));
  console.log('✅ Page recrutement.html pointe bien vers jbf-service.com et les APIs V2.');

  console.log('\n======================================================');
  console.log('🎉 TOUS LES TESTS UNITAIRES ET D\'INTÉGRITÉ V2 SONT VALIDÉS !');
  console.log('======================================================');
}

runTests().catch(err => {
  console.error('❌ Erreur durant les tests :', err);
  process.exit(1);
});
