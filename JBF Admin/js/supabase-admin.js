// =============================================================
// JBF SERVICES — SUPABASE ADMIN CLIENT (Connexion Réelle)
// Projet: dvzwqxcaiagczyonrhsg.supabase.co
// Toutes les opérations CRUD admin passent par ce module
// =============================================================

let SUPABASE_URL = window.ENV_SUPABASE_URL || (window.JBF_CONFIG && window.JBF_CONFIG.SUPABASE_URL) || 'https://dvzwqxcaiagczyonrhsg.supabase.co';
let SUPABASE_ANON_KEY = window.ENV_SUPABASE_ANON_KEY || (window.JBF_CONFIG && window.JBF_CONFIG.SUPABASE_ANON_KEY) || '';

// Initialisation dynamique du client Supabase (sans clé en dur)
let _supabaseClient = null;
let _initPromise = null;

async function getOrInitSupabaseClient() {
  if (_supabaseClient) return _supabaseClient;
  if (_initPromise) return await _initPromise;

  _initPromise = (async () => {
    // Si la clé anon n'est pas encore présente, récupération dynamique depuis l'API backend
    if (!SUPABASE_ANON_KEY) {
      try {
        const endpoints = ['/api/config', 'http://localhost:3001/api/config', 'http://127.0.0.1:8080/api/config'];
        for (const url of endpoints) {
          try {
            const resp = await fetch(url, { method: 'GET' });
            if (resp.ok) {
              const cfg = await resp.json();
              if (cfg.supabaseUrl) SUPABASE_URL = cfg.supabaseUrl;
              if (cfg.supabaseAnonKey) SUPABASE_ANON_KEY = cfg.supabaseAnonKey;
              if (window.JBF_CONFIG) {
                window.JBF_CONFIG.SUPABASE_URL = SUPABASE_URL;
                window.JBF_CONFIG.SUPABASE_ANON_KEY = SUPABASE_ANON_KEY;
              }
              break;
            }
          } catch (e) {}
        }
      } catch (err) {}
    }

    if (typeof supabase !== 'undefined' && SUPABASE_ANON_KEY) {
      try {
        _supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
        return _supabaseClient;
      } catch(e) {
        console.warn('[JBF Admin] Erreur init Supabase:', e.message);
        return null;
      }
    }
    return null;
  })();

  return await _initPromise;
}

function getSupabaseClient() {
  if (_supabaseClient) return _supabaseClient;
  if (typeof supabase !== 'undefined' && SUPABASE_ANON_KEY) {
    try {
      _supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
      return _supabaseClient;
    } catch(e) {
      return null;
    }
  }
  // Déclenche l'initialisation asynchrone sans bloquer
  getOrInitSupabaseClient();
  return null;
}

async function ensureDb() {
  return getSupabaseClient() || await getOrInitSupabaseClient();
}

// Exposer globalement
window.jbfSupabase = {
  get client() { return getSupabaseClient(); },
  isConnected() { return getSupabaseClient() !== null; },

  async getDevis(limit) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('demandes_devis').select('*').order('created_at', { ascending: false }).limit(limit || 200);
  },
  async updateDevisStatut(id, statut) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('demandes_devis').update({ statut, updated_at: new Date().toISOString() }).eq('id', id).select().single();
  },
  async deleteDevis(id) {
    const db = await ensureDb(); if (!db) return { error: 'non connecte' };
    return await db.from('demandes_devis').delete().eq('id', id);
  },

  async getMissions(limit) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('missions').select('*').order('created_at', { ascending: false }).limit(limit || 200);
  },
  async createMission(d) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('missions').insert([{
      titre: d.titre, client: d.client, site_intervention: d.site_intervention,
      service_nom: d.service, date_fin: d.date_fin || null, description: d.description,
      statut: 'en_cours', created_at: new Date().toISOString(), updated_at: new Date().toISOString()
    }]).select().single();
  },
  async updateMissionStatut(id, statut) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('missions').update({ statut, updated_at: new Date().toISOString() }).eq('id', id).select().single();
  },
  async deleteMission(id) {
    const db = await ensureDb(); if (!db) return { error: 'non connecte' };
    return await db.from('missions').delete().eq('id', id);
  },

  async getConges(limit) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('demandes_conges').select('*').order('created_at', { ascending: false }).limit(limit || 200);
  },
  async updateCongeStatut(id, statut, commentaire) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('demandes_conges').update({ statut, commentaire_admin: commentaire || '' }).eq('id', id).select().single();
  },

  async getMembres(limit) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('profiles').select('*').in('role', ['membre', 'admin', 'direction']).order('full_name', { ascending: true }).limit(limit || 500);
  },
  async updateMembre(id, updates) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('profiles').update({ ...updates, updated_at: new Date().toISOString() }).eq('id', id).select().single();
  },
  async deleteMembre(id) {
    const db = await ensureDb(); if (!db) return { error: 'non connecte' };
    return await db.from('profiles').delete().eq('id', id);
  },

  async getAvis(limit) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('avis_clients').select('*').order('created_at', { ascending: false }).limit(limit || 200);
  },
  async updateAvisPublication(id, approuve) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('avis_clients').update({ approuve }).eq('id', id).select().single();
  },
  async deleteAvis(id) {
    const db = await ensureDb(); if (!db) return { error: 'non connecte' };
    return await db.from('avis_clients').delete().eq('id', id);
  },

  async getAdminAccounts() {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('admin_accounts').select('*').order('created_at', { ascending: true });
  },
  async createAdminAccount(d) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('admin_accounts').insert([{
      full_name: d.full_name, email: d.email, phone: d.phone || '',
      role: 'sous_admin', permissions: d.permissions || ['dashboard'],
      is_active: true, created_at: new Date().toISOString()
    }]).select().single();
  },
  async updateAdminPermissions(id, permissions) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('admin_accounts').update({ permissions, updated_at: new Date().toISOString() }).eq('id', id).select().single();
  },
  async deleteAdminAccount(id) {
    const db = await ensureDb(); if (!db) return { error: 'non connecte' };
    return await db.from('admin_accounts').delete().eq('id', id);
  },

  async getDashboardStats() {
    const db = await ensureDb(); if (!db) return null;
    const [dR, mR, prR, cR, aR] = await Promise.all([
      db.from('demandes_devis').select('id, statut'),
      db.from('missions').select('id, statut'),
      db.from('profiles').select('id').in('role', ['membre', 'admin', 'direction']),
      db.from('demandes_conges').select('id, statut'),
      db.from('avis_clients').select('id, note, approuve')
    ]);
    const dd = dR.data || []; const md = mR.data || [];
    const cd = cR.data || []; const ad = aR.data || [];
    const avgNote = ad.length > 0 ? (ad.reduce((s, a) => s + (a.note || 5), 0) / ad.length).toFixed(1) : '4.9';
    return {
      devisTotal: dd.length, devisNouveaux: dd.filter(d => d.statut === 'nouveau').length,
      missionsActives: md.filter(m => m.statut === 'en_cours').length, missionsTotal: md.length,
      membresTotal: prR.data?.length || 0,
      congesEnAttente: cd.filter(c => c.statut === 'en_attente').length,
      avisTotal: ad.length, avisNote: avgNote
    };
  },

  async getTickets(limit) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('tickets_support').select('*').order('created_at', { ascending: false }).limit(limit || 100);
  },
  async updateTicketStatut(id, statut) {
    const db = await ensureDb(); if (!db) return { data: null };
    return await db.from('tickets_support').update({ statut, updated_at: new Date().toISOString() }).eq('id', id).select().single();
  }
};

console.info('[JBF Admin] Module Supabase chargé — Projet: dvzwqxcaiagczyonrhsg');
