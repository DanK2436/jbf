// =============================================================
// JBF SERVICES — CORE SCRIPT DU PORTAIL WEB ADMIN
// Gestion globale : Authentification, Permissions, Sidebar, Toasts, API Client
// Zéro Emoji — Charte 90% Rose Vif / 10% Blanc — Logo Officiel
// =============================================================

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
    // Session par défaut pour le test : Super Administrateur avec tous les droits
    session = {
      name: 'Direction Générale JBF',
      email: 'direction@jbf-services.cd',
      role: 'Super Administrateur',
      site: 'Direction Lubumbashi & Kinshasa',
      avatar: 'DG',
      permissions: ['*'], // Accès total
      token: 'jbf-super-admin-session'
    };
    setAdminSession(session);
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
  try {
    const raw = localStorage.getItem(JBF_CONFIG.ADMIN_USER_KEY);
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

// 3. Horloge temps réel
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

// 4. Gestion Sidebar Responsive, Logo Officiel et Filtrage Dynamique des Droits
function initSidebar() {
  const toggleBtn = document.getElementById('btnMenuToggle');
  const sidebar = document.querySelector('.admin-sidebar');
  if (!sidebar) return;

  // Création ou récupération du backdrop pour mobile
  let backdrop = document.querySelector('.sidebar-backdrop');
  if (!backdrop) {
    backdrop = document.createElement('div');
    backdrop.className = 'sidebar-backdrop';
    document.body.appendChild(backdrop);
  }

  function openSidebar() {
    sidebar.classList.add('open');
    backdrop.classList.add('active');
    document.body.style.overflow = window.innerWidth <= 1024 ? 'hidden' : '';
  }

  function closeSidebar() {
    sidebar.classList.remove('open');
    backdrop.classList.remove('active');
    document.body.style.overflow = '';
  }

  if (toggleBtn) {
    toggleBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      if (sidebar.classList.contains('open')) {
        closeSidebar();
      } else {
        openSidebar();
      }
    });
  }

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

// 10. Observer l'apparition de tableaux dynamiques pour y attacher les contrôleurs de défilement
if (typeof MutationObserver !== 'undefined') {
  let scrollCtrlTimer = null;
  const tableScrollObserver = new MutationObserver(() => {
    clearTimeout(scrollCtrlTimer);
    scrollCtrlTimer = setTimeout(() => {
      initTableScrollControls();
    }, 100);
  });
// 11. Helper pour injecter data-label sur les cellules de tableau (responsive mobile)
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
  applyTableDataLabels
};


