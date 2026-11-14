// ==============================================================================
// FORMAT PROPRIÉTAIRE JBF (.jbf) — ENCAPSULATION & SÉCURISATION DE DOCUMENTS
// Spécification JBF-SEC-v1.0
// Format binaire sécurisé :
// [Magic 4B: 'JBF!'] [IV 12B] [Auth Tag 16B] [Encrypted JSON Payload (AES-256-GCM)]
// ==============================================================================

const crypto = require('crypto');

const MAGIC_HEADER = Buffer.from('JBF!', 'ascii');
const MASTER_JBF_KEY = crypto.createHash('sha256').update(process.env.JBF_SECURITY_SALT || 'JBF-SERVICES-RDC-KEY-2026').digest();

/**
 * Encapsule du texte, JSON ou document binaire dans un conteneur chiffré .jbf
 * @param {Object} options 
 * @param {string} options.titre - Nom ou libellé du document
 * @param {string} options.typeOriginal - Extension d'origine (txt, pdf, docx, dwg, etc.)
 * @param {string|Buffer} options.contenu - Contenu brut ou texte
 * @param {string} [options.emetteur] - Qui émet le document
 * @param {string} [options.missionCode] - Code de la mission associée
 * @returns {Buffer} - Contenu binaire du fichier .jbf
 */
function packJbfFile({ titre, typeOriginal, contenu, emetteur = 'JBF SERVICES SARL', missionCode = null }) {
  const contentBase64 = Buffer.isBuffer(contenu) 
    ? contenu.toString('base64') 
    : Buffer.from(String(contenu), 'utf-8').toString('base64');

  const sha256 = crypto.createHash('sha256').update(contentBase64).digest('hex');

  const payload = JSON.stringify({
    format_version: '1.0',
    titre: titre || 'Document JBF Confidentiel',
    type_original: typeOriginal || 'txt',
    emetteur: emetteur,
    mission_code: missionCode,
    date_creation: new Date().toISOString(),
    sha256_checksum: sha256,
    content_base64: contentBase64,
    notice_securite: 'Ce document est réservé aux applications agréées de JBF Services RDC.'
  });

  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', MASTER_JBF_KEY, iv);

  const encrypted = Buffer.concat([cipher.update(payload, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();

  // Assemblage : [MAGIC (4B)] + [IV (12B)] + [TAG (16B)] + [ENCRYPTED DATA]
  return Buffer.concat([MAGIC_HEADER, iv, tag, encrypted]);
}

/**
 * Déchiffre et extrait les informations d'un conteneur .jbf
 * @param {Buffer} buffer - Contenu binaire du fichier .jbf
 * @returns {Object} Métadonnées et contenu décodé
 */
function unpackJbfFile(buffer) {
  if (!Buffer.isBuffer(buffer) || buffer.length < 32) {
    throw new Error('Format de fichier invalide ou corrompu (taille insuffisante).');
  }

  const magic = buffer.subarray(0, 4);
  if (!magic.equals(MAGIC_HEADER)) {
    throw new Error('Signature magique JBF! manquante. Ce fichier n\'est pas un format officiel .jbf.');
  }

  const iv = buffer.subarray(4, 16);
  const tag = buffer.subarray(16, 32);
  const encryptedData = buffer.subarray(32);

  const decipher = crypto.createDecipheriv('aes-256-gcm', MASTER_JBF_KEY, iv);
  decipher.setAuthTag(tag);

  let decryptedStr;
  try {
    decryptedStr = Buffer.concat([decipher.update(encryptedData), decipher.final()]).toString('utf8');
  } catch (err) {
    throw new Error('Échec du déchiffrement .jbf : clé invalide ou fichier altéré.');
  }

  const parsed = JSON.parse(decryptedStr);
  return {
    titre: parsed.titre,
    typeOriginal: parsed.type_original,
    emetteur: parsed.emetteur,
    missionCode: parsed.mission_code,
    dateCreation: parsed.date_creation,
    checksum: parsed.sha256_checksum,
    contenuBuffer: Buffer.from(parsed.content_base64, 'base64'),
    contenuTexte: Buffer.from(parsed.content_base64, 'base64').toString('utf-8')
  };
}

module.exports = {
  packJbfFile,
  unpackJbfFile
};
