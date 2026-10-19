/** Connexion membre — repli local (GitHub Pages) */
(function (window) {
  'use strict';

  function tryLocalMemberLogin(email, password) {
    try {
      const list = JSON.parse(localStorage.getItem('JBF_ADMIN_MEMBRES_LOCAL') || '[]');
      const ag = list.find((a) => String(a.email || '').toLowerCase() === email);
      if (!ag) return null;
      const pwd = ag._authPassword || ag.password || '';
      if (pwd !== password && pwd !== password.trim()) return null;
      return {
        id: ag.id || ('mem-' + Date.now()),
        nom: ag.full_name || ag.nom_complet || ag.name || email,
        email: email,
        role: ag.role || 'Membre',
        statut_equipe: 'Actif',
        token: 'jbf-member-local-' + Date.now()
      };
    } catch (_) {
      return null;
    }
  }

  window.JBFMemberLogin = { tryLocalMemberLogin };
})(window);
