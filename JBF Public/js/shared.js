/* ============================================================
   JBF SERVICES — Navbar & Footer partagés (injectés)
   ============================================================ */

(function() {
  /* ── Détecter la page active ── */
  const path = window.location.pathname.split('/').pop() || 'index.html';
  function isActive(page) {
    return path === page || (path === '' && page === 'index.html');
  }

  /* ── Calculer le chemin relatif vers la racine ── */
  const depth = window.location.pathname.split('/').filter(Boolean).length - 1;
  const root  = depth > 0 ? '../'.repeat(depth) : '';

  /* ── Injection navbar ── */
  const navHTML = `
<nav class="navbar" id="jbf-navbar">
  <div class="navbar-inner">
    <a href="${root}index.html" class="nav-brand">
      <div class="nav-brand-text">
        <span class="nav-brand-jbf">JBF</span><span class="nav-brand-services">&nbsp;SERVICES</span>
      </div>
      <span class="nav-brand-tagline">L'Excellence à votre service</span>
    </a>
    <ul class="nav-menu" id="jbf-navMenu">
      <li><a href="${root}index.html"    class="nav-link ${isActive('index.html') ? 'active' : ''}">Accueil</a></li>
      <li><a href="${root}services.html" class="nav-link ${isActive('services.html') ? 'active' : ''}">Services</a></li>
      <li><a href="${root}gallery.html"  class="nav-link ${isActive('gallery.html') ? 'active' : ''}">Galerie</a></li>
      <li><a href="${root}avis.html"     class="nav-link ${isActive('avis.html') ? 'active' : ''}">Avis Clients</a></li>
      <li><a href="${root}blog.html"     class="nav-link ${isActive('blog.html') ? 'active' : ''}">Actualités</a></li>
      <li><a href="${root}faq.html"      class="nav-link ${isActive('faq.html') ? 'active' : ''}">FAQ</a></li>
      <li><a href="${root}about.html"    class="nav-link ${isActive('about.html') ? 'active' : ''}">À Propos</a></li>
      <li><a href="${root}contact.html"  class="nav-link ${isActive('contact.html') ? 'active' : ''}">Contact</a></li>
    </ul>
    <div class="nav-actions">
  <a href="${root ? root : ''}../JBF Client/auth/login.html" class="nav-connexion" style="font-weight: 700;">Espace Client</a>
  <button class="hamburger" id="jbf-hamburger" aria-label="Menu">
    <span></span><span></span><span></span>
  </button>
</div>
  </div>
</nav>`;

  /* ── Injection footer ── */
  const footerHTML = `
<footer class="footer">
  <div class="container">
    <div class="footer-grid">
      <div>
        <div class="footer-brand-name">
          <span class="fbj">JBF</span>&nbsp;<span class="fbs">SERVICES</span>
        </div>
        <div class="footer-brand-tag">L'Excellence à votre service</div>
        <p class="footer-about">
          Votre partenaire polyvalent pour l'alimentaire, le BTP, la logistique, le minier
          et bien plus encore. 15 domaines d'expertise à votre service.
        </p>
      </div>
      <div>
        <div class="footer-col-title">Liens Rapides</div>
        <ul class="footer-links">
          <li><a href="${root}index.html">Accueil</a></li>
          <li><a href="${root}services.html">Services (15 Pôles)</a></li>
          <li><a href="${root ? root : ''}../JBF Client/auth/login.html" style="color: var(--pink); font-weight: 700;">Espace Client & Devis</a></li>
          <li><a href="${root ? root : ''}../JBF Client/service-client.html">Service Client & WhatsApp</a></li>
          <li><a href="${root}gallery.html">Galerie Chantiers</a></li>
          <li><a href="${root}avis.html">Avis Clients</a></li>
          <li><a href="${root}blog.html">Actualités</a></li>
          <li><a href="${root}faq.html">FAQ</a></li>
          <li><a href="${root}about.html">À Propos</a></li>
          <li><a href="${root}contact.html">Contact</a></li>
        </ul>
      </div>
      <div>
        <div class="footer-col-title">Contact</div>
        <div class="footer-contact-item">
          <div class="footer-contact-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
              <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/>
            </svg>
          </div>
          <span class="footer-contact-text">contact@jbf-services.com</span>
        </div>
        <div class="footer-contact-item">
          <div class="footer-contact-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
              <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12a19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 3.6 1.09h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 8.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>
            </svg>
          </div>
          <span class="footer-contact-text">+243 0822 357 053 &mdash; +243 0970 349 724</span>
        </div>
        <div class="footer-contact-item">
          <div class="footer-contact-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/>
            </svg>
          </div>
          <span class="footer-contact-text">République Démocratique du Congo</span>
        </div>
      </div>
      <div>
        <div class="footer-col-title">Suivez-nous</div>
        <div class="footer-social">
          <a href="#" class="social-icon" aria-label="Facebook">
            <svg viewBox="0 0 24 24"><path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"/></svg>
          </a>
          <a href="#" class="social-icon" aria-label="LinkedIn">
            <svg viewBox="0 0 24 24"><path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z"/><rect x="2" y="9" width="4" height="12"/><circle cx="4" cy="4" r="2"/></svg>
          </a>
          <a href="#" class="social-icon" aria-label="Instagram">
            <svg viewBox="0 0 24 24"><rect x="2" y="2" width="20" height="20" rx="5" ry="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/></svg>
          </a>
        </div>
      </div>
    </div>
    <div class="footer-bottom">
      <span>&copy; 2026 JBF SERVICES. Tous droits réservés.</span>
      <div class="footer-legal-links">
        <a href="${root}mentions-legales.html">Mentions légales</a>
        <a href="${root}politique-confidentialite.html">Politique de confidentialité</a>
        <a href="${root}cgu.html">CGU</a>
      </div>
    </div>
  </div>
</footer>`;

  /* ── Injecter dans le DOM ── */
  document.addEventListener('DOMContentLoaded', function() {
    // Navbar
    const existingNav = document.querySelector('nav.navbar, nav.navbar-static');
    if (!document.getElementById('jbf-navbar')) {
      if (existingNav) {
        existingNav.outerHTML = navHTML;
      } else {
        document.body.insertAdjacentHTML('afterbegin', navHTML);
      }
    }

    // Footer
    const existingFooter = document.querySelector('footer.footer');
    if (existingFooter && !existingFooter.querySelector('.footer-brand-name')) {
      existingFooter.outerHTML = footerHTML;
    } else if (!existingFooter) {
      document.body.insertAdjacentHTML('beforeend', footerHTML);
    }

    // Hamburger
    const hamburger = document.getElementById('jbf-hamburger');
    const menu = document.getElementById('jbf-navMenu');
    if (hamburger && menu) {
      hamburger.addEventListener('click', () => menu.classList.toggle('is-open'));
    }

    // Scroll
    const nav = document.getElementById('jbf-navbar');
    if (nav) {
      window.addEventListener('scroll', () => nav.classList.toggle('scrolled', window.scrollY > 60));
    }
  });
})();
