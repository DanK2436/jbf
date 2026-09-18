/* =============================================================
   JBF SERVICES — CLIENT JS CENTRAL (js/supabase.js)
   Connecteur API Backend & Supabase sécurisé v7.0
   Aucune clé secrète n'est exposée côté client
   ============================================================= */

const API_BASE_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
  ? 'http://localhost:3001'
  : '';

let supabaseInstance = null;

// Initialise le client Supabase de manière sécurisée en récupérant les clés publiques
async function getSupabase() {
  if (supabaseInstance) return supabaseInstance;

  try {
    const res = await fetch(`${API_BASE_URL}/api/config`);
    if (!res.ok) throw new Error('Erreur configuration API');
    const config = await res.json();

    if (window.supabase) {
      supabaseInstance = window.supabase.createClient(config.supabaseUrl, config.supabaseAnonKey);
    }
    return supabaseInstance;
  } catch (e) {
    console.warn('API locale indisponible, fonctionnement en mode direct:', e.message);
    return null;
  }
}

// 1. Soumission d'une demande de devis
async function soumettreDevis(devisData) {
  try {
    const res = await fetch(`${API_BASE_URL}/api/devis`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(devisData)
    });
    return await res.json();
  } catch (err) {
    console.error('Erreur soumission devis:', err);
    return { success: false, error: 'Impossible de joindre le serveur. Vérifiez votre connexion.' };
  }
}

// 2. Récupération des avis clients
async function chargerAvis(service = 'all') {
  try {
    const url = `${API_BASE_URL}/api/avis${service !== 'all' ? `?service=${encodeURIComponent(service)}` : ''}`;
    const res = await fetch(url);
    if (!res.ok) throw new Error('Erreur chargement avis');
    return await res.json();
  } catch (err) {
    console.error('Erreur chargement avis:', err);
    return { success: false, avis: [] };
  }
}

// 3. Soumission d'un avis client
async function soumettreAvis(avisData) {
  try {
    const res = await fetch(`${API_BASE_URL}/api/avis`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(avisData)
    });
    return await res.json();
  } catch (err) {
    console.error('Erreur soumission avis:', err);
    return { success: false, error: 'Erreur réseau lors de la soumission de l\'avis.' };
  }
}

// 4. Pointage QR Code / GPS
async function enregistrerPointage(pointageData) {
  try {
    const res = await fetch(`${API_BASE_URL}/api/pointage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(pointageData)
    });
    return await res.json();
  } catch (err) {
    console.error('Erreur pointage:', err);
    return { success: false, error: 'Erreur lors du pointage.' };
  }
}
