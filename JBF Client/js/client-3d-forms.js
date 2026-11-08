/**
 * =============================================================
 * JBF Client — 3D INTERACTIVE FORM SYSTEM & SPATIAL DEPTH
 * Moteur physique pour formulaires 3D (Tilt, Profondeur spatiale & Reflets)
 * S'applique à :
 * - Page Login (.login-container)
 * - Page Sign Up (.auth-container)
 * - Page Mot de Passe Oublié (.card)
 * - Page Devis (.modal-box, .card)
 * - Page Service Client (.card form)
 * - Page Avis / Évaluations (.modal-box, .card)
 * - Page Profil Entreprise (.card form)
 * =============================================================
 */

(function () {
  'use strict';

  function init3DForms() {
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (prefersReducedMotion) return;

    const targetSelectors = [
      '.login-container',
      '.auth-container',
      '.card-form-3d',
      '.form-3d-card',
      '.modal-box',
      '.support-grid .card',
      'main.client-content .card form',
      '.client-hero-motion-card'
    ];

    const cards = document.querySelectorAll(targetSelectors.join(', '));
    cards.forEach(card => {
      // Pour les formulaires, on applique le tilt au conteneur parent carte
      const target = card.tagName === 'FORM' ? (card.closest('.card') || card) : card;
      if (target.dataset.has3dTilt) return;
      target.dataset.has3dTilt = 'true';

      target.classList.add('spatial-3d-card');

      let bounds = target.getBoundingClientRect();
      let isHovered = false;

      function updateBounds() {
        bounds = target.getBoundingClientRect();
      }

      function onMouseMove(e) {
        if (!isHovered) return;
        const x = e.clientX - bounds.left;
        const y = e.clientY - bounds.top;

        const xPct = (x / bounds.width) - 0.5;
        const yPct = (y / bounds.height) - 0.5;

        // Angle de rotation 3D contenu (max 8 deg pour élégance B2B)
        const rotY = (xPct * 8).toFixed(2);
        const rotX = (-yPct * 8).toFixed(2);

        target.style.transform = `perspective(1100px) rotateX(${rotX}deg) rotateY(${rotY}deg) translateZ(8px)`;

        // Réflectance dynamique
        const sheenX = ((x / bounds.width) * 100).toFixed(1);
        const sheenY = ((y / bounds.height) * 100).toFixed(1);
        target.style.setProperty('--sheen-x', `${sheenX}%`);
        target.style.setProperty('--sheen-y', `${sheenY}%`);
      }

      target.addEventListener('mouseenter', () => {
        isHovered = true;
        updateBounds();
        target.style.transition = 'transform 120ms cubic-bezier(0.2, 0.8, 0.2, 1), box-shadow 250ms ease';
      });

      target.addEventListener('mousemove', onMouseMove, { passive: true });

      target.addEventListener('mouseleave', () => {
        isHovered = false;
        target.style.transition = 'transform 450ms cubic-bezier(0.25, 1, 0.5, 1), box-shadow 350ms ease';
        target.style.transform = 'perspective(1100px) rotateX(0deg) rotateY(0deg) translateZ(0px)';
      });

      window.addEventListener('resize', updateBounds, { passive: true });
    });

    // Effet 3D tactile sur chaque champ de formulaire
    const inputs = document.querySelectorAll('.form-control, input, select, textarea');
    inputs.forEach(input => {
      if (input.dataset.has3dFocus) return;
      input.dataset.has3dFocus = 'true';

      input.addEventListener('focus', () => {
        const wrap = input.closest('.input-icon-wrap') || input.parentElement;
        if (wrap) wrap.classList.add('focused-3d');
      });

      input.addEventListener('blur', () => {
        const wrap = input.closest('.input-icon-wrap') || input.parentElement;
        if (wrap) wrap.classList.remove('focused-3d');
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init3DForms);
  } else {
    init3DForms();
  }

  // Support des ouvertures modales dynamiques
  window.reinit3DForms = init3DForms;
})();
