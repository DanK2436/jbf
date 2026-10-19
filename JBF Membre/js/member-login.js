/** Connexion membre — repli local (GitHub Pages) */
(function (window) {
  'use strict';

  function tryLocalMemberLogin(email, password) {
    try {
      const list = JSON.parse(localStorage.getItem('JBF_ADMIN_MEMBRES_LOCAL') || '[]');
      const ag = list.find((a) => String(a.email || '').toLowerCase() === email);
      if (!ag) return null;
      const pwd = ag._authPassword || ag.password || '';
      if (!pwd || (pwd !== password && pwd !== password.trim())) return null;
      const fullName = ag.full_name || ag.nom_complet || ag.name || email;
      const initials = fullName.split(' ').filter(Boolean).map((n) => n[0]).join('').substring(0, 2).toUpperCase();
      return {
        id: ag.id || ('mem-' + Date.now()),
        nom: fullName,
        full_name: fullName,
        initials,
        email,
        role: ag.role || 'Membre',
        poste: ag.poste || ag.fonction || 'Collaborateur',
        matricule: ag.matricule || '',
        section_id: ag.section_id || 4,
        section_nom: ag.section_nom || ag.secteur || '',
        solde_conges: ag.solde_conges ?? 0,
        statut_equipe: 'Actif',
        token: 'jbf-member-local-' + Date.now()
      };
    } catch (_) {
      return null;
    }
  }

  window.JBFMemberLogin = { tryLocalMemberLogin };
})(window);
