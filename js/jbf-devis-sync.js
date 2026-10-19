/**
 * Synchronisation devis chefs → admin (localStorage partagé GitHub Pages).
 */
(function (window) {
  'use strict';

  const DEVIS_LOCAL_KEY = 'JBF_DEVIS_EQUIPES_LOCAL';

  function readLocalDevis() {
    try {
      const raw = localStorage.getItem(DEVIS_LOCAL_KEY);
      return raw ? JSON.parse(raw) : [];
    } catch (_) {
      return [];
    }
  }

  function writeLocalDevis(list) {
    try {
      localStorage.setItem(DEVIS_LOCAL_KEY, JSON.stringify(list));
    } catch (_) {}
  }

  function mergeDevisLists(remote, local) {
    const map = new Map();
    [...(local || []), ...(remote || [])].forEach((d) => {
      if (!d) return;
      const id = String(d.id || `${d.created_at || ''}-${d.titre || ''}-${d.chef_equipe_nom || ''}`);
      const prev = map.get(id);
      map.set(id, prev ? { ...prev, ...d, id: d.id || prev.id || id } : { ...d, id: d.id || id });
    });
    return Array.from(map.values()).sort(
      (a, b) => new Date(b.created_at || 0) - new Date(a.created_at || 0)
    );
  }

  function pushDevisFromChef(devis) {
    const list = readLocalDevis();
    list.unshift(devis);
    writeLocalDevis(list);
    return devis;
  }

  window.JBFDevisSync = {
    DEVIS_LOCAL_KEY,
    readLocalDevis,
    writeLocalDevis,
    mergeDevisLists,
    pushDevisFromChef
  };
})(window);
