/**
 * JBF SERVICES — ESPACE MEMBRE
 * Module partagé : Authentification Supabase + Fallback Session, Profil membre, Header & Sidebar unifiés
 */

let SUPABASE_URL = window.ENV_SUPABASE_URL || 'https://dvzwqxcaiagczyonrhsg.supabase.co';
let SUPABASE_ANON_KEY = window.ENV_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2endxeGNhaWFnY3p5b25yaHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1ODEzNzIsImV4cCI6MjEwNTE1NzM3Mn0.uam5Z-d6SWS9-4Ly9f0ircJPryFJwOXbNp9_alHHl-o';

// Initialisation dynamique du client Supabase
let supabaseClient = null;
async function initMemberSupabase() {
  if (supabaseClient) return supabaseClient;
  if (!SUPABASE_ANON_KEY) {
    try {
      const endpoints = [];
      if (!window.location.hostname.endsWith('github.io')) {
        endpoints.push('/api/config', 'http://localhost:3001/api/config', 'http://127.0.0.1:8080/api/config');
      }
      for (const ep of endpoints) {
        try {
          const res = await fetch(ep);
          if (res.ok) {
            const d = await res.json();
            if (d.supabaseUrl) SUPABASE_URL = d.supabaseUrl;
            if (d.supabaseAnonKey) SUPABASE_ANON_KEY = d.supabaseAnonKey;
            break;
          }
        } catch(e) {}
      }
    } catch(e) {}
  }
  if (window.supabase && SUPABASE_ANON_KEY) {
    try {
      supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    } catch(e) {}
  }
  return supabaseClient;
}
initMemberSupabase();

// 15 Services Officiels JBF
const JBF_15_SERVICES = [
  { id: 1, name: "Fourniture de produits alimentaires", cat: "Alimentaire" },
  { id: 2, name: "Placement de ressources humaines dans les entreprises", cat: "RH & Recrutement" },
  { id: 3, name: "Prestations de sous-traitance dans le domaine alimentaire", cat: "Alimentaire" },
  { id: 4, name: "Prestations de sous-traitance dans le domaine minier", cat: "Industrie & Mines" },
  { id: 5, name: "Prestations de service de maintenance", cat: "Maintenance" },
  { id: 6, name: "Soudure", cat: "Technique" },
  { id: 7, name: "Housekeeping et assainissement", cat: "Nettoyage & Hygiène" },
  { id: 8, name: "Construction et génie civil", cat: "BTP & Construction" },
  { id: 9, name: "Restauration et agroalimentaire", cat: "Alimentaire" },
  { id: 10, name: "Jardinage", cat: "Espaces Verts" },
  { id: 11, name: "Gardiennage", cat: "Sécurité" },
  { id: 12, name: "Dépôt (logistique et stockage)", cat: "Logistique" },
  { id: 13, name: "Transport des biens et des personnes", cat: "Transport" },
  { id: 14, name: "Informatique", cat: "Technologies" },
  { id: 15, name: "Livraison des consommables et pièces de rechanges", cat: "Approvisionnement" }
];

function getServiceById(id) {
  return JBF_15_SERVICES.find(s => s.id === parseInt(id)) || JBF_15_SERVICES[3]; // défaut Section 4 Mines
}

function isChefEquipe(profile) {
  if (!profile) return false;
  const s = String(profile.statut_equipe || profile.role || '').toLowerCase();
  return s === 'chef_equipe' || s === 'chef';
}

// Session & Profil utilisateur actuel
let currentMemberProfile = null;

/**
 * Récupère le profil du membre connecté depuis Supabase ou session locale
 */
async function initMemberSession() {
  try {
    let user = null;

    // 1. Vérifier session Supabase si disponible
    if (supabaseClient) {
      try {
        const { data: { session } } = await supabaseClient.auth.getSession();
        if (session && session.user) {
          user = session.user;
        }
      } catch (_) {}
    }

    // 2. Vérifier session locale persistée
    const localSessionStr =
      localStorage.getItem('jbf_member_session') ||
      localStorage.getItem('JBF_MEMBER_SESSION');
    let localProfile = null;
    if (localSessionStr) {
      try {
        localProfile = JSON.parse(localSessionStr);
      } catch (_) {}
    }

    function normalizeMemberProfile(raw) {
      if (!raw) return null;
      const fullName = raw.full_name || raw.nom || raw.name || raw.email || 'Collaborateur';
      const initials = raw.initials || fullName.split(' ').filter(Boolean).map((n) => n[0]).join('').substring(0, 2).toUpperCase();
      return {
        ...raw,
        full_name: fullName,
        initials,
        section_id: parseInt(raw.section_id, 10) || 4,
        section_nom: raw.section_nom || getServiceById(parseInt(raw.section_id, 10) || 4).name,
        matricule: raw.matricule || '',
        poste: raw.poste || raw.fonction || raw.role || 'Collaborateur',
        solde_conges: raw.solde_conges !== undefined ? raw.solde_conges : 0,
        role: raw.role || 'membre',
        statut_equipe: raw.statut_equipe || (raw.role === 'chef_equipe' ? 'chef_equipe' : 'membre')
      };
    }

    // Si aucune session
    if (!user && !localProfile) {
      if (!window.location.pathname.includes('/auth/login.html')) {
        const pathToLogin = window.location.pathname.includes('/auth/') ? 'login.html' : 'auth/login.html';
        window.location.href = pathToLogin;
      }
      return null;
    }

    // 3. Charger le profil réel
    if (user && supabaseClient) {
      try {
        const { data: profile } = await supabaseClient
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

        if (profile) {
          const secId = parseInt(profile.section_id) || 4;
          const sec = getServiceById(secId);
          const fullName = profile.full_name || profile.nom_complet || user.email || 'Collaborateur';
          const initials = fullName.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase() || 'JB';

          currentMemberProfile = {
            id: profile.id,
            email: profile.email,
            full_name: fullName,
            initials: initials,
            section_id: secId,
            section_nom: profile.section_nom || sec.name,
            section_cat: sec.cat,
            matricule: profile.matricule || '',
            poste: profile.poste || profile.fonction || 'Collaborateur',
            solde_conges: profile.solde_conges !== undefined ? profile.solde_conges : 22,
            role: profile.role || 'membre',
            statut_equipe: profile.statut_equipe || (profile.role === 'chef_equipe' ? 'chef_equipe' : 'membre')
          };
        }
      } catch (_) {}
    }

    if (!currentMemberProfile) {
      if (localProfile) {
        currentMemberProfile = normalizeMemberProfile(localProfile);
      } else if (user) {
        currentMemberProfile = normalizeMemberProfile({
          id: user.id,
          email: user.email,
          nom: user.user_metadata?.full_name || user.email
        });
      }
    }

    if (!currentMemberProfile) {
      if (!window.location.pathname.includes('/auth/login.html')) {
        window.location.href = window.location.pathname.includes('/auth/') ? 'login.html' : 'auth/login.html';
      }
      return null;
    }

    localStorage.setItem('jbf_member_session', JSON.stringify(currentMemberProfile));
    localStorage.setItem('JBF_MEMBER_SESSION', JSON.stringify(currentMemberProfile));

    updateMemberUI(currentMemberProfile);
    if (typeof renderNavigation === 'function' && document.getElementById('memberSidebarContainer')) {
      const path = window.location.pathname || '';
      let pageKey = document.body.dataset.memberPage || 'dashboard';
      if (path.includes('missions')) pageKey = 'missions';
      else if (path.includes('devis-chiffrage')) pageKey = 'devis-chiffrage';
      else if (path.includes('leaves')) pageKey = 'leaves';
      else if (path.includes('chat')) pageKey = 'chat';
      else if (path.includes('resources')) pageKey = 'resources';
      else if (path.includes('roi')) pageKey = 'roi';
      else if (path.includes('dashboard')) pageKey = 'dashboard';
      renderNavigation(pageKey, currentMemberProfile);
    }
    return currentMemberProfile;

  } catch (err) {
    console.error("Erreur initMemberSession:", err);
    return null;
  }
}

/**
 * Met à jour le header et les éléments profil avec les données réelles
 */
function updateMemberUI(profile) {
  if (!profile) return;

  document.querySelectorAll('.user-avatar').forEach(el => {
    el.textContent = profile.initials || 'DK';
  });

  document.querySelectorAll('.user-meta-name').forEach(el => {
    el.textContent = profile.full_name || profile.nom || 'Collaborateur';
  });

  document.querySelectorAll('.user-meta-role').forEach(el => {
    const chefLabel = isChefEquipe(profile) ? "Chef d'équipe • " : '';
    el.textContent = `${chefLabel}${profile.poste || 'Collaborateur'} • ${profile.section_cat || 'JBF RDC'}`;
    el.title = profile.section_nom || '';
  });

  document.querySelectorAll('.member-section-display').forEach(el => {
    el.textContent = `${profile.section_nom || 'Département des Opérations Minières'}`;
  });
}

/**
 * Injection globale du Header et Sidebar cohérents (sans pointage)
 */
function renderNavigation(activePage, profileOverride) {
  const headerContainer = document.getElementById('memberHeaderContainer');
  const sidebarContainer = document.getElementById('memberSidebarContainer');

  const inAuthDir = window.location.pathname.includes('/auth/');
  const rootPath = inAuthDir ? '../' : '';
  const navProfile = profileOverride || currentMemberProfile;
  const showChefDevis = isChefEquipe(navProfile);

  if (headerContainer) {
    headerContainer.innerHTML = `
      <div class="sidebar-backdrop" id="sidebarBackdrop" onclick="closeSidebar()"></div>
      <header class="member-header">
        <div class="member-brand-container">
          <button class="menu-toggle" id="menuToggle" onclick="toggleSidebar()" aria-label="Menu">
            <span></span><span></span><span></span>
          </button>
          <a href="${rootPath}dashboard.html" style="display:flex; align-items:center; gap:0.75rem; text-decoration:none;">
            <img src="${rootPath}assets/logo.png" alt="JBF SERVICES" class="member-logo-img" style="height:38px; width:auto; object-fit:contain;">
            <div class="member-system-tag">Espace Membre</div>
          </a>
        </div>
        <div class="member-header-actions">
          <div class="user-profile-badge">
            <div class="user-avatar-wrapper">
              <div class="user-avatar">JB</div>
              <div class="status-online-dot" title="Session Active"></div>
            </div>
            <div class="user-info">
              <div class="user-meta-name">Collaborateur</div>
              <div class="user-meta-role">JBF SERVICES</div>
            </div>
          </div>
          <button onclick="handleLogout()" class="btn btn-outline btn-sm btn-logout-compact" title="Déconnexion">Sortir</button>
        </div>
      </header>
    `;
  }

  if (sidebarContainer) {
    sidebarContainer.innerHTML = `
      <aside class="sidebar" id="sidebar">
        <div class="sidebar-mobile-header">
          <div style="display:flex; align-items:center; gap:0.6rem;">
            <img src="${rootPath}assets/logo.png" alt="JBF SERVICES" style="height:32px; width:auto;">
            <span style="font-family:'Poppins',sans-serif; font-size:0.88rem; font-weight:800; color:var(--text-h);">JBF Membre</span>
          </div>
          <button onclick="closeSidebar()" style="background:none; border:none; color:var(--text-light); font-size:1.4rem; cursor:pointer; padding:0.2rem 0.5rem; line-height:1;" aria-label="Fermer le menu">&times;</button>
        </div>
        <div class="sidebar-title">Menu Collaborateur</div>
        <ul class="sidebar-menu">
          <li>
            <a href="${rootPath}dashboard.html" class="${activePage === 'dashboard' ? 'active' : ''}" onclick="if(window.innerWidth<1024) closeSidebar()">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>
              Tableau de Bord
            </a>
          </li>
          <li>
            <a href="${rootPath}missions.html" class="${activePage === 'missions' ? 'active' : ''}" onclick="if(window.innerWidth<1024) closeSidebar()">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 2 7 12 12 22 7 12 2"></polygon><polyline points="2 17 12 22 22 17"></polyline><polyline points="2 12 12 17 22 12"></polyline></svg>
              Mes Missions
            </a>
          </li>
          ${showChefDevis ? `
          <li>
            <a href="${rootPath}devis-chiffrage.html" class="${activePage === 'devis-chiffrage' ? 'active' : ''}" onclick="if(window.innerWidth<1024) closeSidebar()" style="border-left:3px solid var(--pink);">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"></rect><line x1="8" y1="21" x2="16" y2="21"></line><line x1="12" y1="17" x2="12" y2="21"></line><path d="M9 7h6M9 11h6"></path></svg>
              Devis pro (CDF→USD)
            </a>
          </li>
          ` : ''}
          <li>
            <a href="${rootPath}leaves.html" class="${activePage === 'leaves' ? 'active' : ''}" onclick="if(window.innerWidth<1024) closeSidebar()">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path></svg>
              Demandes de Congés
            </a>
          </li>
          <li>
            <a href="${rootPath}chat.html" class="${activePage === 'chat' ? 'active' : ''}" onclick="if(window.innerWidth<1024) closeSidebar()">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path></svg>
              Chat d'Équipe
            </a>
          </li>
          <li>
            <a href="${rootPath}resources.html" class="${activePage === 'resources' ? 'active' : ''}" onclick="if(window.innerWidth<1024) closeSidebar()">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
              Ressources HSE
            </a>
          </li>
          <li>
            <a href="${rootPath}roi.html" class="${activePage === 'roi' ? 'active' : ''}" onclick="if(window.innerWidth<1024) closeSidebar()">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
              Règlement Intérieur (R.O.I)
            </a>
          </li>
        </ul>
      </aside>
    `;
  }
}

function toggleSidebar() {
  const sidebar = document.getElementById('sidebar');
  const backdrop = document.getElementById('sidebarBackdrop');
  if (sidebar) sidebar.classList.toggle('open');
  if (backdrop) backdrop.classList.toggle('show');
}

function closeSidebar() {
  const sidebar = document.getElementById('sidebar');
  const backdrop = document.getElementById('sidebarBackdrop');
  if (sidebar) sidebar.classList.remove('open');
  if (backdrop) backdrop.classList.remove('show');
}

window.addEventListener('resize', () => {
  if (window.innerWidth >= 1024) closeSidebar();
});

/**
 * Déconnexion
 */
async function handleLogout() {
  localStorage.removeItem('jbf_member_session');
  if (supabaseClient) {
    try {
      await supabaseClient.auth.signOut();
    } catch (_) {}
  }
  const inAuthDir = window.location.pathname.includes('/auth/');
  window.location.href = inAuthDir ? 'login.html' : 'auth/login.html';
}

// Keep-Alive Supabase (anti-mise en pause 7 jours)
(function() {
  try {
    const K_KEY = 'JBF_SUPABASE_LAST_PING';
    const now = Date.now();
    const last = parseInt(localStorage.getItem(K_KEY) || '0', 10);
    if (now - last > 24 * 60 * 60 * 1000) {
      fetch('https://dvzwqxcaiagczyonrhsg.supabase.co/rest/v1/profiles?select=id&limit=1', {
        headers: {
          'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2endxeGNhaWFnY3p5b25yaHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1ODEzNzIsImV4cCI6MjEwNTE1NzM3Mn0.uam5Z-d6SWS9-4Ly9f0ircJPryFJwOXbNp9_alHHl-o',
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2endxeGNhaWFnY3p5b25yaHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1ODEzNzIsImV4cCI6MjEwNTE1NzM3Mn0.uam5Z-d6SWS9-4Ly9f0ircJPryFJwOXbNp9_alHHl-o'
        }
      }).then(r => {
        if (r.ok) localStorage.setItem(K_KEY, Date.now().toString());
      }).catch(() => {});
    }
  } catch (_) {}
})();
