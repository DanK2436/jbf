/**
 * Affichage texte UI — évite &amp; et entités HTML visibles dans le contenu injecté en JS.
 */
(function (window) {
  'use strict';

  function decodeHtmlEntities(value) {
    if (value == null || value === '') return '';
    let s = String(value);
    if (!/&(?:#x?[0-9a-f]+|[a-z]+);/i.test(s)) return s;
    try {
      const el = document.createElement('textarea');
      el.innerHTML = s;
      return el.value || s;
    } catch (_) {
      return s.replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&#039;/g, "'");
    }
  }

  function displayLabel(value, fallback) {
    const decoded = decodeHtmlEntities(value);
    if (!decoded) return fallback || '';
    if (/^data:[\w/+.-]+;base64,/i.test(decoded.trim())) return fallback || 'Contenu';
    return decoded;
  }

  window.JBFTextDisplay = { decodeHtmlEntities, displayLabel };
})(window);
