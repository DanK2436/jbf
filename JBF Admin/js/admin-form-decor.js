/** Motifs SVG pour en-têtes de formulaires admin */
(function (window) {
  'use strict';

  const SVGS = {
    member: `<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <circle cx="32" cy="22" r="10" stroke="#E6007E" stroke-width="2.5"/>
      <path d="M14 54c2-12 12-18 18-18s16 6 18 18" stroke="#E6007E" stroke-width="2.5" stroke-linecap="round"/>
      <path d="M8 32h48" stroke="#F9A8D4" stroke-width="2" stroke-dasharray="4 4"/>
    </svg>`,
    subadmin: `<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <path d="M32 8l22 10v14c0 14-10 24-22 28C10 56 10 46 10 32V18L32 8z" stroke="#E6007E" stroke-width="2.5" stroke-linejoin="round"/>
      <path d="M24 32l6 6 12-14" stroke="#E6007E" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>`,
    mission: `<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <path d="M12 48V20l20-8 20 8v28" stroke="#E6007E" stroke-width="2.5" stroke-linejoin="round"/>
      <path d="M24 48V34h16v14" stroke="#F472B6" stroke-width="2"/>
      <circle cx="32" cy="26" r="4" fill="#E6007E"/>
    </svg>`,
    resource: `<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <rect x="14" y="10" width="36" height="44" rx="4" stroke="#E6007E" stroke-width="2.5"/>
      <path d="M22 22h20M22 32h20M22 42h12" stroke="#F472B6" stroke-width="2" stroke-linecap="round"/>
    </svg>`,
    generic: `<svg viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <rect x="10" y="14" width="44" height="36" rx="6" stroke="#E6007E" stroke-width="2.5"/>
      <path d="M10 26h44" stroke="#F9A8D4" stroke-width="2"/>
      <circle cx="20" cy="20" r="2" fill="#E6007E"/>
      <circle cx="28" cy="20" r="2" fill="#E6007E"/>
    </svg>`
  };

  function decorHtml(type, label, caption) {
    const svg = SVGS[type] || SVGS.generic;
    const cap = caption ? `<div class="decor-caption">${caption}</div>` : '';
    return `<div class="admin-form-decor">${svg}<div><div class="decor-label">${label}</div>${cap}</div></div>`;
  }

  window.JBFAdminFormDecor = { decorHtml, SVGS };
})(window);
