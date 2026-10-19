/**
 * Affichage ressources HSE — masque data:base64 et chaînes encodées dans titres/descriptions.
 */
(function (window) {
  'use strict';

  function looksLikeDataUrl(s) {
    return /^data:[\w/+.-]+;base64,/i.test(String(s || '').trim());
  }

  function looksLikeBase64Blob(s) {
    const t = String(s || '').replace(/\s/g, '');
    return t.length > 120 && /^[A-Za-z0-9+/=]+$/.test(t);
  }

  function tryDecodeUri(s) {
    if (!s || typeof s !== 'string') return s;
    if (!/%[0-9A-Fa-f]{2}/.test(s)) return s;
    try {
      const d = decodeURIComponent(s);
      if (looksLikeDataUrl(d) || looksLikeBase64Blob(d)) return null;
      return d;
    } catch (_) {
      return s;
    }
  }

  function sanitizeResourceText(value, fallback) {
    if (value == null || value === '') return fallback || '';
    let s = String(value).trim();
    s = (tryDecodeUri(s) ?? fallback) || '';
    if (!s) return fallback || '';
    if (looksLikeDataUrl(s)) return fallback || 'Document téléversé';
    if (looksLikeBase64Blob(s)) return fallback || 'Document archivé';
    if (s.length > 280) return s.slice(0, 277) + '…';
    return s;
  }

  function inferTitleFromRow(row) {
    if (row._fileLabel) return sanitizeResourceText(row._fileLabel, 'Document partagé');
    if (row.document_nom) return sanitizeResourceText(row.document_nom, 'Document partagé');
    const url = String(row.fichier_url || '');
    if (url && !looksLikeDataUrl(url)) {
      const tail = url.split('/').pop().split('?')[0];
      if (tail && tail.length < 120) return sanitizeResourceText(decodeURIComponent(tail), 'Document partagé');
    }
    return 'Ressource JBF';
  }

  function normalizeResourceRow(row) {
    if (!row || typeof row !== 'object') return row;
    let titre = sanitizeResourceText(row.titre, '');
    if (!titre || looksLikeDataUrl(row.titre) || looksLikeBase64Blob(row.titre)) {
      titre = inferTitleFromRow(row);
    }
    let description = sanitizeResourceText(row.description, '');
    const url = row.fichier_url || '';
    if (description && url && description === url) description = '';
    if (description && looksLikeDataUrl(description)) description = '';
    if (looksLikeBase64Blob(description)) description = '';
    return { ...row, titre, description };
  }

  function normalizeResourceList(list) {
    return (list || []).map(normalizeResourceRow);
  }

  window.JBFResourceDisplay = {
    sanitizeResourceText,
    normalizeResourceRow,
    normalizeResourceList,
    looksLikeDataUrl
  };
})(window);
