/** Connexion membre — repli local (GitHub Pages) */
(function (window) {
  'use strict';

  function tryLocalMemberLogin(email, password) {
    try {
      const list = JSON.parse(localStorage.getItem('JBF_ADMIN_MEMBRES_LOCAL') || '[]');
      const ag = list.find((a) => String(a.email || '').toLowerCase() === email);
      if (!ag) return null;
      const pwd = String(ag._authPassword || ag.password || '').trim();
      const passTry = String(password || '').trim();
      if (!pwd || pwd !== passTry) return null;
      const fullName = ag.full_name || ag.nom_complet || ag.name || email;
      const initials = fullName.split(' ').filter(Boolean).map((n) => n[0]).join('').substring(0, 2).toUpperCase();
      return {
        id: ag.id || ('mem-' + Date.now()),
        nom: fullName,
        full_name: fullName,
        initials,
        email,
        role: ag.statut_equipe === 'chef_equipe' || ag.role === 'chef_equipe' ? 'chef_equipe' : (ag.role || 'membre'),
        poste: ag.poste || ag.fonction || 'Collaborateur',
        matricule: ag.matricule || '',
        section_id: ag.section_id || 4,
        section_nom: ag.section_nom || ag.secteur || '',
        solde_conges: ag.solde_conges ?? 0,
        statut_equipe: ag.statut_equipe || (ag.role === 'chef_equipe' ? 'chef_equipe' : 'membre'),
        token: 'jbf-member-local-' + Date.now()
      };
    } catch (_) {
      return null;
    }
  }

  window.JBFMemberLogin = { tryLocalMemberLogin };
})(window);
