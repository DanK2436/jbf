/**
 * ==============================================================================
 * JBF SERVICES — SCRIPT KEEP-ALIVE SUPABASE
 * Empêche la mise en veille automatique après 7 jours d'inactivité (Supabase Free Tier)
 *
 * Fonctionnement polyvalent :
 * 1. Côté Navigateur (Web GitHub Pages / Téléphone / PC) : Envoie une requête
 *    légère une fois par 24 heures pour maintenir la base réveillée.
 * 2. Côté Node.js (CLI / Tâche planifiée) : Exécutable via `node supabase/keep-alive.js`
 * ==============================================================================
 */

(function () {
  'use strict';

  const SUPABASE_URL = "https://dvzwqxcaiagczyonrhsg.supabase.co";
  const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2endxeGNhaWFnY3p5b25yaHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1ODEzNzIsImV4cCI6MjEwNTE1NzM3Mn0.uam5Z-d6SWS9-4Ly9f0ircJPryFJwOXbNp9_alHHl-o";
  const PING_INTERVAL_MS = 24 * 60 * 60 * 1000; // 24 heures
  const STORAGE_KEY = 'JBF_SUPABASE_LAST_PING';

  async function pingSupabase() {
    const endpoint = `${SUPABASE_URL}/rest/v1/profiles?select=id&limit=1`;
    try {
      const response = await fetch(endpoint, {
        method: 'GET',
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
        }
      });
      if (response.ok) {
        console.log(`[JBF Keep-Alive] ✅ Supabase est actif (Statut: ${response.status}). Compteur d'inactivité réinitialisé.`);
        return true;
      } else {
        console.warn(`[JBF Keep-Alive] Réponse inattendue: ${response.status}`);
        return false;
      }
    } catch (err) {
      console.warn('[JBF Keep-Alive] Erreur ping:', err.message);
      return false;
    }
  }

  // Environnement Navigateur
  if (typeof window !== 'undefined') {
    window.jbfPingSupabase = async function (force = false) {
      const lastPing = parseInt(localStorage.getItem(STORAGE_KEY) || '0', 10);
      const now = Date.now();
      if (force || (now - lastPing) > PING_INTERVAL_MS) {
        const ok = await pingSupabase();
        if (ok) {
          localStorage.setItem(STORAGE_KEY, String(now));
        }
      }
    };

    // Déclenchement automatique non-bloquant après le chargement de la page
    if (document.readyState === 'complete') {
      setTimeout(() => window.jbfPingSupabase(), 2000);
    } else {
      window.addEventListener('load', () => {
        setTimeout(() => window.jbfPingSupabase(), 2000);
      });
    }
  }

  // Environnement Node.js (CLI)
  if (typeof module !== 'undefined' && module.exports && typeof window === 'undefined') {
    console.log('🔄 Exécution du ping Keep-Alive Supabase en mode Node.js...');
    pingSupabase().then((success) => {
      if (success) {
        console.log('✅ Projet Supabase maintenu actif avec succès.');
        process.exit(0);
      } else {
        console.error('❌ Échec du ping.');
        process.exit(1);
      }
    });
  }
})();
