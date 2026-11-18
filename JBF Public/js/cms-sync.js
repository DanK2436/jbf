/**
 * ============================================================================
 * JBF SERVICE — CMS SYNCHRONISATION DYNAMIQUE TEMPS RÉEL (cms-sync.js)
 * Permet au site public de refléter instantanément toutes les modifications,
 * désactivations de sections et ajouts d'éléments effectués par l'Admin.
 * ============================================================================
 */

(function () {
  const SUPABASE_URL = 'https://dvzwqxcaiagczyonrhsg.supabase.co';
  const SUPABASE_ANON_KEY =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2endxeGNhaWFnY3p5b25yaHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1ODEzNzIsImV4cCI6MjEwNTE1NzM3Mn0.uam5Z-d6SWS9-4Ly9f0ircJPryFJwOXbNp9_alHHl-o';

  async function fetchCmsConfig() {
    try {
      const res = await fetch(`${SUPABASE_URL}/rest/v1/config_cles_api?select=*`, {
        headers: {
          apikey: SUPABASE_ANON_KEY,
          Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        },
      });
      if (!res.ok) return null;
      return await res.json();
    } catch (err) {
      console.warn('[CMS Sync] Impossible de contacter Supabase:', err);
      return null;
    }
  }

  function applyCmsConfig(rows) {
    if (!Array.isArray(rows) || rows.length === 0) return;

    const configMap = {};
    rows.forEach((r) => {
      if (r.cle_nom) configMap[r.cle_nom] = r.cle_valeur;
    });

    // 1. GESTION DES SECTIONS & COMPOSANTS DÉSACTIVÉS PAR L'ADMIN
    // Hero 3D Canvas
    if (configMap['hero_3d_experience'] === 'false') {
      const heroCanvas = document.getElementById('hero3DCanvas') || document.querySelector('.hero-3d-canvas');
      if (heroCanvas) heroCanvas.style.display = 'none';
      if (window._hero3DAnimationId) cancelAnimationFrame(window._hero3DAnimationId);
    }

    // Bannière Recrutement
    if (configMap['banniere_recrutement'] === 'false') {
      document.querySelectorAll('.hero-recrutement-badge, .recrutement-banner, [data-cms-section="banniere_recrutement"]').forEach((el) => {
        el.style.display = 'none';
      });
    }

    // Catalogue des 15 Services
    if (configMap['section_15_services'] === 'false') {
      document.querySelectorAll('.sectors-section, [data-cms-section="section_15_services"]').forEach((el) => {
        el.style.display = 'none';
      });
    }

    // Témoignages & Avis Clients
    if (configMap['section_temoignages_avis'] === 'false') {
      document.querySelectorAll('#homeAvisGrid, [data-cms-section="section_temoignages_avis"]').forEach((el) => {
        const parentCol = el.closest('.home-live-col') || el;
        parentCol.style.display = 'none';
      });
    }

    // Fil Actualités & Blog
    if (configMap['section_actualites_blog'] === 'false') {
      document.querySelectorAll('#homeNewsGrid, [data-cms-section="section_actualites_blog"]').forEach((el) => {
        const parentCol = el.closest('.home-live-col') || el;
        parentCol.style.display = 'none';
      });
    }

    // Galerie Réalisations
    if (configMap['section_galerie_photos'] === 'false') {
      document.querySelectorAll('#galerie, #gallery, [data-cms-section="section_galerie_photos"]').forEach((el) => {
        el.style.display = 'none';
      });
    }

    // Formulaire / Bouton Devis Public
    if (configMap['formulaire_devis_public'] === 'false') {
      document.querySelectorAll('.cta-final, [data-cms-section="formulaire_devis_public"]').forEach((el) => {
        el.style.display = 'none';
      });
    }

    // Page Carrières & Recrutement Actif
    const isRecrutementOff = configMap['recrutement_actif'] === 'false' || configMap['page_carrieres_active'] === 'false';
    if (isRecrutementOff) {
      const jobForm = document.getElementById('jobForm');
      const closedBanner = document.getElementById('closedBanner');
      const noticeBox = document.getElementById('jobNoticeBox');
      if (jobForm) jobForm.style.display = 'none';
      if (noticeBox) noticeBox.style.display = 'none';
      if (closedBanner) closedBanner.style.display = 'block';

      // Masquer ou annoter les liens Carrières dans la navbar si désactivé
      document.querySelectorAll('a[href*="recrutement.html"]').forEach((link) => {
        link.setAttribute('data-cms-disabled', 'true');
      });
    }

    // 2. CONTACTS OFFICIELS MIS À JOUR PAR L'ADMIN
    if (configMap['contact_whatsapp']) {
      const cleanWa = configMap['contact_whatsapp'].replace(/[^0-9]/g, '');
      document.querySelectorAll('a[href*="wa.me"]').forEach((a) => {
        a.href = `https://wa.me/${cleanWa}?text=${encodeURIComponent('Bonjour JBF Service SARL')}`;
        if (a.textContent.includes('WhatsApp')) {
          a.textContent = `WhatsApp : ${configMap['contact_whatsapp']}`;
        }
      });
      document.querySelectorAll('.cms-contact-whatsapp').forEach((el) => {
        el.textContent = configMap['contact_whatsapp'];
      });
    }

    if (configMap['contact_appels']) {
      const cleanTel = configMap['contact_appels'].replace(/[^0-9+]/g, '');
      document.querySelectorAll('a[href^="tel:"]').forEach((a) => {
        a.href = `tel:${cleanTel}`;
        if (a.textContent.includes('Appels') || a.textContent.includes('+243')) {
          a.textContent = `Appels : ${configMap['contact_appels']}`;
        }
      });
      document.querySelectorAll('.cms-contact-appels').forEach((el) => {
        el.textContent = configMap['contact_appels'];
      });
    }

    if (configMap['contact_email']) {
      document.querySelectorAll('a[href^="mailto:"]').forEach((a) => {
        a.href = `mailto:${configMap['contact_email']}`;
        if (!a.querySelector('svg') && !a.querySelector('i')) {
          a.textContent = configMap['contact_email'];
        }
      });
      document.querySelectorAll('.cms-contact-email').forEach((el) => {
        el.textContent = configMap['contact_email'];
      });
    }

    if (configMap['contact_adresse']) {
      document.querySelectorAll('.cms-contact-adresse').forEach((el) => {
        el.textContent = configMap['contact_adresse'];
      });
    }

    // 3. TITRES & SLOGANS HERO MODIFIABLES
    if (configMap['titre_hero_principal']) {
      const h1 = document.querySelector('.hero-h1');
      if (h1) {
        h1.innerHTML = configMap['titre_hero_principal'].replace(/\n/g, '<br>');
      }
    }
    if (configMap['soustitre_hero_principal']) {
      const lead = document.querySelector('.hero-lead');
      if (lead) {
        lead.textContent = configMap['soustitre_hero_principal'];
      }
    }

    // 5. SYNCHRONISATION FAQ & SERVICES VIA CMS CONFIG
    if (configMap['cms_faq_items_json'] && typeof window.syncFaqFromSupabase === 'function') {
      try {
        const parsedFaq = JSON.parse(configMap['cms_faq_items_json']);
        if (Array.isArray(parsedFaq) && parsedFaq.length > 0 && typeof window.renderFAQ === 'function') {
          window.JBF_FAQ_DATA = parsedFaq.map(item => ({
            id: item.id || `faq_${item.ordre_affichage || 1}`,
            category: item.categorie || 'general',
            order: item.ordre_affichage || 1,
            question: item.question || '',
            answer: item.reponse || '',
            est_actif: item.est_actif !== false
          }));
          window.renderFAQ();
        }
      } catch (_) {}
    }

    if (configMap['cms_services_catalogue_json'] && typeof window.renderServices === 'function' && Array.isArray(window.JBF_SERVICES_DATA)) {
      try {
        const parsedServices = JSON.parse(configMap['cms_services_catalogue_json']);
        if (Array.isArray(parsedServices) && parsedServices.length > 0) {
          parsedServices.forEach(dbS => {
            const cleanDbCode = (dbS.code_service || '').replace(/[^0-9]/g, '');
            const dbTitleNorm = (dbS.titre || '').toLowerCase().trim();

            let target = window.JBF_SERVICES_DATA.find(s => {
              const cleanCode = (s.code || '').replace(/[^0-9]/g, '');
              return (cleanDbCode && cleanCode && cleanDbCode === cleanCode) ||
                     (s.code === dbS.code_service) ||
                     (s.title.toLowerCase().trim() === dbTitleNorm);
            });

            if (target) {
              if (dbS.titre) target.title = dbS.titre;
              if (dbS.categorie) target.category = dbS.categorie;
              if (dbS.description_courte) target.summary = dbS.description_courte;
              if (dbS.description_complete) target.description = dbS.description_complete;
              if (dbS.certifications) target.cert = dbS.certifications;
              if (dbS.delai_mobilisation) target.delay = dbS.delai_mobilisation;
              if (dbS.image_url) target.image = dbS.image_url;
              if (dbS.points_forts) {
                if (typeof dbS.points_forts === 'string') {
                  target.features = dbS.points_forts.split('\n').map(l => l.trim()).filter(Boolean);
                } else if (Array.isArray(dbS.points_forts)) {
                  target.features = dbS.points_forts;
                }
              }
              target._disabled = (dbS.est_actif === false);
            }
          });
          window.renderServices();
        }
      } catch (_) {}
    }
  }
    if (configMap['cms_custom_elements_json']) {
      try {
        const customElements = JSON.parse(configMap['cms_custom_elements_json']);
        if (Array.isArray(customElements)) {
          customElements.forEach((item) => {
            const selector = `[data-cms-key="${item.key}"], #cms-${item.key}, .cms-${item.key}`;
            const existingNodes = document.querySelectorAll(selector);

            // Si l'élément est désactivé par l'admin, on le cache
            if (item.isActive === false) {
              existingNodes.forEach((node) => (node.style.display = 'none'));
              return;
            }

            // S'il est actif : mise à jour ou injection
            if (existingNodes.length > 0) {
              existingNodes.forEach((node) => {
                node.style.display = '';
                if (item.type === 'texte') {
                  node.textContent = item.value;
                } else if (item.type === 'image') {
                  if (node.tagName === 'IMG') node.src = item.value;
                  else node.style.backgroundImage = `url("${item.value}")`;
                } else if (item.type === 'background') {
                  node.style.background = item.value;
                } else if (item.type === 'section' || item.type === 'formulaire') {
                  node.innerHTML = item.value;
                }
              });
            } else if (item.isActive && (item.type === 'section' || item.type === 'texte')) {
              // Création dynamique si conteneur dédié présent
              const dynamicContainer = document.getElementById('cmsDynamicContainer');
              if (dynamicContainer) {
                const div = document.createElement('div');
                div.id = `cms-${item.key}`;
                div.setAttribute('data-cms-key', item.key);
                div.className = 'cms-dynamic-injected-block';
                div.innerHTML = item.value;
                dynamicContainer.appendChild(div);
              }
            }
          });
        }
      } catch (e) {
        console.warn('[CMS Sync] Erreur parsing custom elements:', e);
      }
    }
  }

  // Lancement automatique au chargement
  document.addEventListener('DOMContentLoaded', async () => {
    const configRows = await fetchCmsConfig();
    if (configRows) {
      applyCmsConfig(configRows);
    }
  });

  // Expose globalement
  window.jbfCmsSync = {
    fetchCmsConfig,
    applyCmsConfig,
  };
})();
