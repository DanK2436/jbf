// =============================================================
// JBF SERVICES — CORE SCRIPT DU PORTAIL WEB ADMIN
// Gestion globale : Authentification, Permissions, Sidebar, Toasts, API Client
// Zéro Emoji — Charte 90% Rose Vif / 10% Blanc — Logo Officiel
// =============================================================

/** Titres courts affichés sur mobile (< 768px) */
const ADMIN_MOBILE_TITLES = {
  'dashboard.html': 'Tableau de bord',
  'devis.html': 'Devis',
  'devis-equipes.html': 'Devis équipes',
  'missions.html': 'Missions',
  'galerie.html': 'Galerie',
  'actualites.html': 'Actualités',
  'conges.html': 'Congés',
  'membres.html': 'Collaborateurs',
  'ressources.html': 'Ressources HSE',
  'service-client.html': 'Service client',
  'avis.html': 'Avis clients',
  'sous-admins.html': 'Accès admin',
  'utilisateurs.html': 'Utilisateurs',
  'pointages.html': 'Pointages'
};

const PAGE_PERMISSION_MAP = {
  'dashboard.html': 'dashboard',
  'devis.html': 'devis',
  'devis-equipes.html': 'devis',
  'missions.html': 'missions',
  'conges.html': 'conges',
  'membres.html': 'membres',
  'ressources.html': 'ressources',
  'service-client.html': 'service_client',
  'avis.html': 'avis',
  'sous-admins.html': 'sous_admins'
};

document.addEventListener('DOMContentLoaded', () => {
  initAdminAuthCheck();
  enforcePagePermission();
  initResponsivePageTitles();
  initClock();
  initSidebar();
  createToastContainer();
  initTableScrollControls();
});

// 1. Contrôle d'authentification Administrateur & Permissions
function initAdminAuthCheck() {
  const isLoginPage = window.location.pathname.includes('/auth/login.html');
  let session = getAdminSession();

  if (!session && !isLoginPage) {
    const inAdminFolder = window.location.pathname.includes('/JBF Admin/') || window.location.pathname.includes('/JBF%20Admin/');
    const loginUrl = inAdminFolder ? 'auth/login.html' : 'JBF Admin/auth/login.html';
    window.location.replace(loginUrl);
    return;
  }

  // Mettre à jour l'affichage du profil utilisateur dans la sidebar si présent
  const userNameEl = document.getElementById('adminUserName');
  const userRoleEl = document.getElementById('adminUserRole');
  const userAvatarEl = document.getElementById('adminUserAvatar');

  if (session) {
    if (userNameEl) userNameEl.textContent = session.name || 'Direction JBF';
    if (userRoleEl) userRoleEl.textContent = session.role || 'Administrateur';
    if (userAvatarEl) userAvatarEl.textContent = session.avatar || 'AD';
  }
}

function getAdminSession() {
  const key = (window.JBF_CONFIG && JBF_CONFIG.ADMIN_USER_KEY) || 'jbf_admin_session';
  try {
    const raw =
      localStorage.getItem(key) ||
      localStorage.getItem('JBF_ADMIN_USER') ||
      localStorage.getItem('jbf_admin_session');
    return raw ? JSON.parse(raw) : null;
  } catch (e) {
    return null;
  }
}

function setAdminSession(data) {
  localStorage.setItem(JBF_CONFIG.ADMIN_USER_KEY, JSON.stringify(data));
}

function logoutAdmin() {
  localStorage.removeItem(JBF_CONFIG.ADMIN_USER_KEY);
  showToast('Déconnexion effectuée avec succès', 'info');
  setTimeout(() => {
    window.location.href = window.location.pathname.includes('/auth/') ? 'login.html' : 'auth/login.html';
  }, 500);
}

// 2. Système de Guard & Vérification des Permissions par Page
function hasPermission(permissionKey) {
  const session = getAdminSession();
  if (!session) return false;
  // Super admin ou direction générale a accès à tout
  if (session.role === 'Super Administrateur' || 
      session.role === 'direction' || 
      session.role === 'super_admin' || 
      (session.permissions && session.permissions.includes('*'))) {
    return true;
  }
  const perms = session.permissions || [];
  return perms.includes(permissionKey);
}

function enforcePagePermission() {
  const isLoginPage = window.location.pathname.includes('/auth/login.html');
  if (isLoginPage) return;

  const currentFile = window.location.pathname.split('/').pop() || 'dashboard.html';
  const requiredPermission = PAGE_PERMISSION_MAP[currentFile];

  if (requiredPermission && !hasPermission(requiredPermission)) {
    const session = getAdminSession();
    const userPerms = session?.permissions || ['dashboard'];
    const redirectMap = {
      'dashboard': 'dashboard.html',
      'devis': 'devis.html',
      'missions': 'missions.html',
      'conges': 'conges.html',
      'membres': 'membres.html',
      'avis': 'avis.html',
      'sous_admins': 'sous-admins.html'
    };

    let targetPage = 'dashboard.html';
    for (const p of userPerms) {
      if (redirectMap[p] && redirectMap[p] !== currentFile) {
        targetPage = redirectMap[p];
        break;
      }
    }

    if (targetPage !== currentFile) {
      alert("Accès restreint : Vous n'avez pas l'autorisation d'accéder à cette section.");
      window.location.href = targetPage;
    }
  }
}

// 3. Titres de page adaptés mobile (textes courts, pas de débordement)
function initResponsivePageTitles() {
  const currentFile = window.location.pathname.split('/').pop() || 'dashboard.html';
  const shortTitle = ADMIN_MOBILE_TITLES[currentFile];

  let titleWrap = document.querySelector('.topbar-left .page-title');
  let h1 = titleWrap?.querySelector('h1');

  if (!h1) {
    const legacyH1 = document.querySelector('h1.page-title');
    if (legacyH1) {
      titleWrap = document.createElement('div');
      titleWrap.className = 'page-title';
      legacyH1.classList.remove('page-title');
      titleWrap.appendChild(legacyH1);
      const topbarLeft = document.querySelector('.topbar-left');
      if (topbarLeft) topbarLeft.appendChild(titleWrap);
      h1 = legacyH1;
    }
  }

  if (!h1) return;

  const longTitle = (h1.dataset.fullTitle || h1.textContent).trim();
  h1.dataset.fullTitle = longTitle;
  const short = h1.getAttribute('data-short-title') || shortTitle || longTitle.split(/[—–&]/)[0].trim();

  const mq = window.matchMedia('(max-width: 768px)');
  const apply = () => {
    h1.textContent = mq.matches ? short : longTitle;
    document.title = `${mq.matches ? short : longTitle} — JBF SERVICES`;
  };
  apply();
  mq.addEventListener('change', apply);
}

// 4. Horloge temps réel
function initClock() {
  const clockEl = document.getElementById('liveClock');
  if (!clockEl) return;

  function update() {
    const now = new Date();
    const h = String(now.getHours()).padStart(2, '0');
    const m = String(now.getMinutes()).padStart(2, '0');
    const s = String(now.getSeconds()).padStart(2, '0');
    clockEl.textContent = `${h}:${m}:${s} RDC`;
  }
  update();
  setInterval(update, 1000);
}

// 5. Gestion Sidebar Responsive, Logo Officiel et Filtrage Dynamique des Droits
function initSidebar() {
  const sidebar = document.querySelector('.admin-sidebar');
  if (!sidebar) return;

  if (sidebar.dataset.sidebarInit === '1') return;
  sidebar.dataset.sidebarInit = '1';

  let backdrop = document.querySelector('.sidebar-backdrop');
  if (!backdrop) {
    backdrop = document.createElement('div');
    backdrop.className = 'sidebar-backdrop';
    backdrop.setAttribute('aria-hidden', 'true');
    document.body.appendChild(backdrop);
  }

  function setSidebarOpen(isOpen) {
    sidebar.classList.toggle('open', isOpen);
    backdrop.classList.toggle('active', isOpen);
    document.body.classList.toggle('admin-nav-open', isOpen);
    backdrop.setAttribute('aria-hidden', isOpen ? 'false' : 'true');
    if (!isOpen) {
      document.body.style.overflow = '';
    } else if (window.innerWidth <= 1024) {
      document.body.style.overflow = 'hidden';
    }
    const toggleBtn = document.getElementById('btnMenuToggle');
    if (toggleBtn) {
      toggleBtn.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    }
  }

  function toggleSidebar() {
    setSidebarOpen(!sidebar.classList.contains('open'));
  }

  function closeSidebar() {
    setSidebarOpen(false);
  }

  function openSidebar() {
    setSidebarOpen(true);
  }

  window.jbfAdminNav = { openSidebar, closeSidebar, toggleSidebar };

  document.querySelectorAll('.btn-menu-toggle, #btnMenuToggle').forEach((btn) => {
    if (!btn.getAttribute('type')) btn.setAttribute('type', 'button');
    btn.setAttribute('aria-expanded', 'false');
    btn.setAttribute('aria-label', btn.getAttribute('aria-label') || 'Ouvrir le menu de navigation');
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeSidebar();
  });

  document.addEventListener('click', (e) => {
    const toggle = e.target.closest('#btnMenuToggle, .btn-menu-toggle');
    if (toggle) {
      e.preventDefault();
      e.stopPropagation();
      toggleSidebar();
      return;
    }
    if (e.target === backdrop || (backdrop.classList.contains('active') && backdrop.contains(e.target))) {
      closeSidebar();
    }
  }, true);

  backdrop.addEventListener('click', closeSidebar);

  // Ajouter un bouton de fermeture explicite sur mobile dans le header de la sidebar
  if (!sidebar.querySelector('.btn-sidebar-close')) {
    const header = sidebar.querySelector('.sidebar-header');
    if (header) {
      const closeBtn = document.createElement('button');
      closeBtn.className = 'btn-sidebar-close';
      closeBtn.setAttribute('aria-label', 'Fermer le menu');
      closeBtn.innerHTML = '<i class="bi bi-x-lg"></i>';
      closeBtn.onclick = closeSidebar;
      header.appendChild(closeBtn);
    }
  }

  // Fermer la sidebar après clic sur un élément de navigation sur mobile
  sidebar.querySelectorAll('.sidebar-nav a').forEach(link => {
    link.addEventListener('click', () => {
      if (window.innerWidth <= 1024) closeSidebar();
    });
  });

  // Remplacer l'icône placeholder par le logo officiel JBF SERVICES
  const logoBoxes = document.querySelectorAll('.sidebar-header .logo-box');
  logoBoxes.forEach(box => {
    if (!box.querySelector('img')) {
      const isAuthDir = window.location.pathname.includes('/auth/');
      const logoPath = isAuthDir ? '../../assets/logo.png' : '../assets/logo.png';
      box.innerHTML = `<img src="${logoPath}" alt="JBF SERVICES" class="admin-brand-logo" onerror="this.src='${isAuthDir ? '../assets/logo.png' : 'assets/logo.png'}'">`;
    }
  });

  // SUPPRIMER TOUT LIEN DE POINTAGE DE LA NAVIGATION (Demande utilisateur)
  const pointageLinks = sidebar.querySelectorAll('a[href*="pointages.html"]');
  pointageLinks.forEach(link => link.remove());

  // FILTRER LES LIENS SELON LES PERMISSIONS DU COMPTE CONNECTÉ
  const navLinks = sidebar.querySelectorAll('.sidebar-nav a.nav-item');
  navLinks.forEach(link => {
    const href = link.getAttribute('href') || '';
    const filename = href.split('/').pop();
    const permRequired = PAGE_PERMISSION_MAP[filename];
    if (permRequired && !hasPermission(permRequired)) {
      link.remove(); // Masquer le lien non autorisé
    }
  });

  // AJOUTER OU ASSURER LA PRÉSENCE DU LIEN SOUS-ADMINISTRATEURS SI AUTORISÉ
  if (hasPermission('sous_admins')) {
    const existingSousAdminLink = sidebar.querySelector('a[href*="sous-admins.html"]');
    if (!existingSousAdminLink) {
      const navContainer = sidebar.querySelector('.sidebar-nav');
      if (navContainer) {
        const isAuthDir = window.location.pathname.includes('/auth/');
        const prefix = isAuthDir ? '../' : '';
        const currentFile = window.location.pathname.split('/').pop();
        const isActive = currentFile === 'sous-admins.html' ? 'active' : '';

        const adminSecDiv = document.createElement('div');
        adminSecDiv.innerHTML = `
          <div class="nav-section-title">Sécurité & Accès</div>
          <a href="${prefix}sous-admins.html" class="nav-item ${isActive}">
            <i class="bi bi-shield-lock-fill"></i>
            <span>Sous-Administrateurs</span>
          </a>
        `;
        navContainer.appendChild(adminSecDiv);
      }
    }
  }
}

// 5. Client API Unifié avec Jeton d'Administration
async function apiFetch(endpoint, options = {}) {
  const baseUrl = JBF_CONFIG.API_BASE_URL;
  const url = endpoint.startsWith('http') ? endpoint : `${baseUrl}${endpoint}`;

  const session = getAdminSession();
  const defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'x-admin-token': session?.token || 'jbf-admin-session-active'
  };

  try {
    const response = await fetch(url, {
      ...options,
      headers: {
        ...defaultHeaders,
        ...(options.headers || {})
      }
    });

    const data = await response.json();
    return { ok: response.ok, status: response.status, data };
  } catch (error) {
    console.warn(`[JBF Admin API] Requête vers ${endpoint} échouée:`, error.message);
    return { ok: false, error: error.message };
  }
}

// 6. Système de Notifications Toast (Zéro Emoji)
function createToastContainer() {
  if (document.querySelector('.toast-container')) return;
  const container = document.createElement('div');
  container.className = 'toast-container';
  document.body.appendChild(container);
}

function showToast(message, type = 'info') {
  const container = document.querySelector('.toast-container') || document.body;
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;

  const iconMap = {
    success: 'bi-check-circle-fill',
    error: 'bi-exclamation-triangle-fill',
    info: 'bi-info-circle-fill'
  };

  const icon = iconMap[type] || iconMap.info;
  toast.innerHTML = `
    <i class="bi ${icon}" style="font-size: 1.2rem; color: ${type === 'success' ? 'var(--success)' : type === 'error' ? 'var(--danger)' : 'var(--pink)'};"></i>
    <div style="flex: 1; font-size: 0.88rem; font-weight: 500;">${message}</div>
  `;

  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(100%)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// 7. Helpers Modales
function openModal(modalId) {
  const modal = document.getElementById(modalId);
  if (modal) {
    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
  }
}

function closeModal(modalId) {
  const modal = document.getElementById(modalId);
  if (modal) {
    modal.classList.remove('active');
    document.body.style.overflow = '';
  }
}

// 8. Formatters & Badges (Zéro Emoji)
function formatDate(dateStr) {
  if (!dateStr) return '—';
  try {
    const d = new Date(dateStr);
    return d.toLocaleDateString('fr-FR', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  } catch (e) {
    return dateStr;
  }
}

function renderBadgeStatus(status) {
  const labels = {
    nouveau: 'Nouveau',
    en_etude: 'En étude',
    en_cours: 'En cours',
    valide: 'Validé',
    approuve: 'Approuvé',
    termine: 'Terminé',
    rejete: 'Rejeté',
    annule: 'Annulé',
    en_attente: 'En attente'
  };
  const label = labels[status] || status || 'Inconnu';
  return `<span class="badge-status ${status}">${label}</span>`;
}

function renderBadgeFonction(fonction) {
  const map = {
    directeur_section: {
      label: 'Directeur de Section',
      class: 'directeur',
      icon: 'bi-briefcase-fill'
    },
    superviseur: {
      label: 'Superviseur de Pôle',
      class: 'superviseur',
      icon: 'bi-person-gear'
    },
    employe_simple: {
      label: 'Employé / Technicien',
      class: 'employe',
      icon: 'bi-person'
    }
  };

  const item = map[fonction] || {
    label: fonction || 'Collaborateur',
    class: 'employe',
    icon: 'bi-person'
  };

  return `<span class="badge-fonction ${item.class}"><i class="bi ${item.icon}"></i> ${item.label}</span>`;
}

// 9. Contrôleur de Défilement Horizontal Universel pour Tables
function scrollTable(triggerBtn, delta) {
  let container = null;
  if (triggerBtn) {
    const parent = triggerBtn.closest('.card') || triggerBtn.closest('.card-body') || triggerBtn.closest('.admin-content');
    if (parent) {
      container = parent.querySelector('.table-responsive');
    }
  }
  if (!container) {
    container = document.querySelector('.table-responsive');
  }

  if (container) {
    container.scrollBy({ left: delta, behavior: 'smooth' });
  }
}

// Rendre accessible globalement directement et via adminCore
window.scrollTable = scrollTable;

function initTableScrollControls() {
  const containers = document.querySelectorAll('.table-responsive');
  containers.forEach(container => {
    // Éviter les doublons
    const prevSibling = container.previousElementSibling;
    if (prevSibling && prevSibling.classList.contains('table-scroll-controller')) return;

    const controller = document.createElement('div');
    controller.className = 'table-scroll-controller';
    controller.innerHTML = `
      <div class="scroll-label">
        <i class="bi bi-arrow-left-right"></i> Défilement tableau
      </div>
      <div class="scroll-btn-group">
        <button type="button" class="btn-scroll-nav btn-scroll-prev" title="Défiler vers la gauche" aria-label="Défiler vers la gauche">
          <i class="bi bi-chevron-left"></i>
        </button>
        <button type="button" class="btn-scroll-nav btn-scroll-next" title="Défiler vers la droite" aria-label="Défiler vers la droite">
          <i class="bi bi-chevron-right"></i>
        </button>
      </div>
    `;

    container.parentNode.insertBefore(controller, container);

    const btnPrev = controller.querySelector('.btn-scroll-prev');
    const btnNext = controller.querySelector('.btn-scroll-next');

    function updateButtons() {
      const maxScroll = Math.max(0, container.scrollWidth - container.clientWidth);
      if (maxScroll <= 2) {
        btnPrev.disabled = true;
        btnNext.disabled = true;
      } else {
        btnPrev.disabled = container.scrollLeft <= 2;
        btnNext.disabled = container.scrollLeft >= maxScroll - 2;
      }
    }

    btnPrev.addEventListener('click', (e) => {
      e.preventDefault();
      container.scrollBy({ left: -300, behavior: 'smooth' });
    });

    btnNext.addEventListener('click', (e) => {
      e.preventDefault();
      container.scrollBy({ left: 300, behavior: 'smooth' });
    });

    container.addEventListener('scroll', updateButtons, { passive: true });
    window.addEventListener('resize', updateButtons, { passive: true });

    setTimeout(updateButtons, 100);
  });
}

// 10. Helper pour injecter data-label sur les cellules de tableau (responsive mobile)
function applyTableDataLabels(tableSelector) {
  const tables = document.querySelectorAll(tableSelector || '.admin-table');
  tables.forEach(table => {
    const headers = Array.from(table.querySelectorAll('thead th')).map(th => th.textContent.trim());
    const rows = table.querySelectorAll('tbody tr');
    rows.forEach(row => {
      const cells = row.querySelectorAll('td');
      cells.forEach((td, idx) => {
        if (!td.hasAttribute('data-label') && headers[idx]) {
          td.setAttribute('data-label', headers[idx]);
        }
      });
    });
  });
}

function getSupabaseScriptBase() {
  const scripts = document.getElementsByTagName('script');
  for (const sc of scripts) {
    if (sc.src && sc.src.includes('admin-core.js')) {
      return sc.src.replace(/admin-core\.js(\?.*)?$/, '');
    }
  }
  return 'js/';
}

function ensureSupabaseAdminModule() {
  if (window.jbfSupabase) return;
  if (document.querySelector('script[src*="supabase-admin.js"]')) return;
  const s = document.createElement('script');
  s.src = `${getSupabaseScriptBase()}supabase-admin.js`;
  s.async = true;
  document.head.appendChild(s);
}

async function resolveSupabaseClient() {
  ensureSupabaseAdminModule();
  if (window.jbfSupabase?.client) return window.jbfSupabase.client;
  if (typeof supabase !== 'undefined' && window.JBF_CONFIG?.SUPABASE_ANON_KEY) {
    return supabase.createClient(window.JBF_CONFIG.SUPABASE_URL, window.JBF_CONFIG.SUPABASE_ANON_KEY);
  }
  return null;
}

async function querySupabaseTable(table, options = {}) {
  const client = await resolveSupabaseClient();
  if (!client) return { data: null, error: new Error('Supabase indisponible') };

  let q = client.from(table).select(options.select || '*');
  if (options.eq) {
    Object.entries(options.eq).forEach(([col, val]) => { q = q.eq(col, val); });
  }
  if (options.order) {
    q = q.order(options.order.column, { ascending: options.order.ascending !== false });
  }
  if (options.limit) q = q.limit(options.limit);
  return await q;
}

/** Charge des lignes : API backend d'abord, puis Supabase (première table qui répond). */
async function loadAdminRows({ apiPath, extract, tables }) {
  if (apiPath) {
    const apiRes = await apiFetch(apiPath);
    if (apiRes.ok && apiRes.data) {
      const rows = typeof extract === 'function' ? extract(apiRes.data) : apiRes.data;
      if (Array.isArray(rows) && rows.length > 0) return rows;
    }
  }

  ensureSupabaseAdminModule();
  for (const table of tables || []) {
    try {
      const { data, error } = await querySupabaseTable(table, { order: { column: 'created_at', ascending: false }, limit: 500 });
      if (!error && Array.isArray(data) && data.length > 0) return data;
    } catch (err) {
      console.warn(`[JBF Admin] Lecture ${table}:`, err.message || err);
    }
  }
  return [];
}

function scheduleTableEnhancements() {
  initTableScrollControls();
  applyTableDataLabels();
}

if (typeof MutationObserver !== 'undefined') {
  let scrollCtrlTimer = null;
  const tableScrollObserver = new MutationObserver(() => {
    clearTimeout(scrollCtrlTimer);
    scrollCtrlTimer = setTimeout(scheduleTableEnhancements, 120);
  });
  document.addEventListener('DOMContentLoaded', () => {
    ensureSupabaseAdminModule();
    scheduleTableEnhancements();
    const target = document.querySelector('.admin-main') || document.body;
    tableScrollObserver.observe(target, { childList: true, subtree: true });
  });
} else {
  document.addEventListener('DOMContentLoaded', () => {
    ensureSupabaseAdminModule();
    scheduleTableEnhancements();
  });
}

// Rendre accessible globalement
window.openModal = openModal;
window.closeModal = closeModal;
window.showToast = showToast;
window.formatDate = formatDate;
window.renderBadgeStatus = renderBadgeStatus;
window.renderBadgeFonction = renderBadgeFonction;

// Exposer sur l'objet global
window.adminCore = {
  getAdminSession,
  setAdminSession,
  logoutAdmin,
  hasPermission,
  enforcePagePermission,
  apiFetch,
  showToast,
  openModal,
  closeModal,
  formatDate,
  renderBadgeStatus,
  renderBadgeFonction,
  initTableScrollControls,
  scrollTable,
  applyTableDataLabels,
  loadAdminRows,
  querySupabaseTable,
  resolveSupabaseClient,
  ensureSupabaseAdminModule
};



