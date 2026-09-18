// =============================================================
// JBF SERVICES — CONFIGURATION GLOBALE ESPACE CLIENT
// =============================================================

const JBF_CLIENT_CONFIG = {
  APP_NAME: 'JBF Client Enterprise',
  VERSION: '1.0.0',
  API_BASE_URL: 'http://localhost:3001/api',
  CLIENT_SESSION_KEY: 'jbf_client_session',
  SUPABASE_URL: window.ENV_SUPABASE_URL || 'https://dvzwqxcaiagczyonrhsg.supabase.co',
  SUPABASE_ANON_KEY: window.ENV_SUPABASE_ANON_KEY || '',
  WHATSAPP_SUPPORT_NUMBER: '+243971306666', // Numéro officiel Service Client JBF RDC
  DEFAULT_CLIENT: null
};

(async function loadClientConfig() {
  if (JBF_CLIENT_CONFIG.SUPABASE_ANON_KEY) return;
  try {
    const endpoints = ['/api/config', 'http://localhost:3001/api/config', 'http://127.0.0.1:8080/api/config'];
    for (const ep of endpoints) {
      try {
        const res = await fetch(ep);
        if (res.ok) {
          const d = await res.json();
          if (d.supabaseUrl) JBF_CLIENT_CONFIG.SUPABASE_URL = d.supabaseUrl;
          if (d.supabaseAnonKey) JBF_CLIENT_CONFIG.SUPABASE_ANON_KEY = d.supabaseAnonKey;
          break;
        }
      } catch(e) {}
    }
  } catch(e) {}
})();
