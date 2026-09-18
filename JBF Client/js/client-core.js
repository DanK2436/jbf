// =============================================================
// JBF SERVICES — SCRIPT CENTRAL DU PORTAIL CLIENT
// Gestion de session, navigation, scrollbars & API client
// =============================================================

document.addEventListener('DOMContentLoaded', () => {
  initClientAuth();
  initSidebar();
  createToastContainer();
  initTableScrollControls();
});

// 1. Contrôle de session Client
function initClientAuth() {
  const isAuthPage = window.location.pathname.includes('/auth/');
  let session = getClientSession();

  if (!session && !isAuthPage) {
    // Redirection stricte vers la page de connexion si aucune session active
    window.location.href = window.location.pathname.includes('/auth/') ? 'login.html' : 'auth/login.html';
    return;
  }

  // Mettre à jour les éléments d'affichage utilisateur avec les données réelles
  if (session) {
    const nameEls = document.querySelectorAll('.client-user-name, #clientUserName');
    const compEls = document.querySelectorAll('.client-company-name, #clientCompanyName');
    const avatarEls = document.querySelectorAll('.client-user-avatar, #clientUserAvatar');

    const displayName = session.contactName || session.name || (session.email ? session.email.split('@')[0] : 'Client Partenaire');
    const displayCompany = session.companyName || session.company || displayName || 'Mon Entreprise';
    const displayAvatar = session.avatar || (displayCompany.slice(0, 2).toUpperCase()) || 'CL';

    nameEls.forEach(el => el.textContent = displayName);
    compEls.forEach(el => el.textContent = displayCompany);
    avatarEls.forEach(el => el.textContent = displayAvatar);
  }
}

function getClientSession() {
  try {
    const raw = localStorage.getItem('JBF_CLIENT_SESSION') || localStorage.getItem('jbf_client_session');
    return raw ? JSON.parse(raw) : null;
  } catch (e) {
    return null;
  }
}

function setClientSession(data) {
  const json = JSON.stringify(data);
  localStorage.setItem('JBF_CLIENT_SESSION', json);
  localStorage.setItem('jbf_client_session', json);
}

function logoutClient() {
  localStorage.removeItem('JBF_CLIENT_SESSION');
  localStorage.removeItem('jbf_client_session');
  showToast('Déconnexion effectuée avec succès', 'info');
  setTimeout(() => {
    window.location.href = window.location.pathname.includes('/auth/') ? 'login.html' : 'auth/login.html';
  }, 400);
}

// 2. Gestion de la Sidebar Mobile & Tiroir
function initSidebar() {
  const toggleBtn = document.getElementById('btnMenuToggle');
  const sidebar = document.querySelector('.client-sidebar');
  if (!sidebar) return;

  let backdrop = document.querySelector('.sidebar-backdrop');
  if (!backdrop) {
    backdrop = document.createElement('div');
    backdrop.className = 'sidebar-backdrop';
    document.body.appendChild(backdrop);
  }

  function openSidebar() {
    sidebar.classList.add('open');
    backdrop.classList.add('active');
    document.body.style.overflow = window.innerWidth <= 992 ? 'hidden' : '';
  }

  function closeSidebar() {
    sidebar.classList.remove('open');
    backdrop.classList.remove('active');
    document.body.style.overflow = '';
  }

  if (toggleBtn) {
    toggleBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      sidebar.classList.contains('open') ? closeSidebar() : openSidebar();
    });
  }

  backdrop.addEventListener('click', closeSidebar);

  // Bouton de fermeture dans le header de la sidebar sur mobile
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

  sidebar.querySelectorAll('.sidebar-nav a').forEach(link => {
    link.addEventListener('click', () => {
      if (window.innerWidth <= 992) closeSidebar();
    });
  });
}

// 3. Contrôleur de Défilement Horizontal Universel pour Tableaux
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

// 4. Modales
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

// 5. Notifications Toast
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
    <i class="bi ${icon}" style="font-size: 1.2rem; color: ${type === 'success' ? 'var(--success)' : type === 'error' ? 'var(--danger)' : 'var(--brand-pink)'};"></i>
    <div style="flex: 1; font-size: 0.85rem; font-weight: 500;">${message}</div>
  `;

  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(100%)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// 6. Raccourci d'ouverture WhatsApp direct avec message pré-rempli (Service Client Officiel Uniquement)
function openWhatsAppDirect(customMsg = '') {
  const number = (window.JBF_CLIENT_CONFIG?.WHATSAPP_SUPPORT_NUMBER || '243971306666').replace(/[^0-9]/g, '');
  const session = getClientSession();
  const clientName = session ? `${session.companyName || session.nom || 'Client'} (${session.contactName || ''})` : 'Client';
  const defaultText = encodeURIComponent(`Bonjour Service Client JBF SERVICES, je suis ${clientName}. ${customMsg || "J'ai besoin d'assistance concernant nos prestations."}`);
  window.open(`https://wa.me/${number}?text=${defaultText}`, '_blank');
}

window.clientCore = {
  getClientSession,
  setClientSession,
  logoutClient,
  openModal,
  closeModal,
  showToast,
  initTableScrollControls,
  openWhatsAppDirect
};
