/**
 * Outil chef d'équipe : catalogue matériels, calcul CDF, conversion USD (taux manuel).
 */
(function (window) {
  'use strict';

  const MATERIALS_KEY_PREFIX = 'JBF_CHEF_MATERIALS_';

  function materialsKey(email) {
    return MATERIALS_KEY_PREFIX + String(email || 'default').toLowerCase();
  }

  function defaultMaterials() {
    return [
      { id: 'm1', name: 'Ciment (sac 50 kg)', unit: 'sac', price_cdf: 18500 },
      { id: 'm2', name: 'Tôle galvanisée', unit: 'm²', price_cdf: 42000 },
      { id: 'm3', name: 'Main-d\'œuvre qualifiée', unit: 'jour', price_cdf: 35000 },
      { id: 'm4', name: 'Transport engin', unit: 'forfait', price_cdf: 250000 }
    ];
  }

  function loadMaterials(email) {
    try {
      const raw = localStorage.getItem(materialsKey(email));
      if (raw) {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed) && parsed.length) return parsed;
      }
    } catch (_) {}
    return defaultMaterials();
  }

  function saveMaterials(email, list) {
    localStorage.setItem(materialsKey(email), JSON.stringify(list));
  }

  function formatCdf(n) {
    return (Number(n) || 0).toLocaleString('fr-FR', { maximumFractionDigits: 0 }) + ' CDF';
  }

  function formatUsd(n) {
    return '$' + (Number(n) || 0).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }

  function uid() {
    return 'ln-' + Date.now() + '-' + Math.floor(Math.random() * 9999);
  }

  window.JBFDevisChiffrage = {
    loadMaterials,
    saveMaterials,
    defaultMaterials,
    formatCdf,
    formatUsd,
    uid,
    materialsKey
  };
})(window);
