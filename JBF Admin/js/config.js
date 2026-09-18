// =============================================================
// JBF SERVICES — CONFIGURATION GLOBALE WEB ADMIN
// Supabase Project: dvzwqxcaiagczyonrhsg.supabase.co
// =============================================================

const JBF_CONFIG = {
  SUPABASE_URL: window.ENV_SUPABASE_URL || 'https://dvzwqxcaiagczyonrhsg.supabase.co',
  SUPABASE_ANON_KEY: window.ENV_SUPABASE_ANON_KEY || '',
  ADMIN_USER_KEY: 'jbf_admin_session',
  BRAND: {
    name: 'JBF SERVICES',
    edition: 'Supervision & Administration Web',
    primaryColor: '#E6007E'
  }
};

// Récupération asynchrone transparente de la configuration depuis le backend
(async function loadDynamicConfig() {
  if (JBF_CONFIG.SUPABASE_ANON_KEY) return;
  try {
    const endpoints = ['/api/config', 'http://localhost:3001/api/config', 'http://127.0.0.1:8080/api/config'];
    for (const ep of endpoints) {
      try {
        const res = await fetch(ep);
        if (res.ok) {
          const data = await res.json();
          if (data.supabaseUrl) JBF_CONFIG.SUPABASE_URL = data.supabaseUrl;
          if (data.supabaseAnonKey) JBF_CONFIG.SUPABASE_ANON_KEY = data.supabaseAnonKey;
          break;
        }
      } catch (err) {}
    }
  } catch (e) {}
})();

window.JBF_CONFIG = JBF_CONFIG;
