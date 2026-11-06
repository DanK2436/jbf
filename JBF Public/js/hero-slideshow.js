/**
 * Diaporama d'accueil strictement manuel.
 * Aucun timer, aucun autoplay. Les pastilles restent utilisables au clavier.
 */
(function () {
  const SERVICES = [
    { code: '01', title: 'Alimentaire & Catering' },
    { code: '02', title: 'Sous-Traitance Minière' },
    { code: '03', title: 'BTP & Génie Civil' },
    { code: '04', title: 'Maintenance Industrielle' },
    { code: '05', title: 'Gardiennage & Sécurité' },
    { code: '06', title: 'Nettoyage Industriel' },
    { code: '07', title: 'Logistique & Transport' },
    { code: '08', title: 'Bases de Vie & Camps' },
    { code: '09', title: 'Main-d\'œuvre & Régie' },
    { code: '10', title: 'Équipements de Protection (EPI)' },
    { code: '11', title: 'Location d\'Engins de Chantier' },
    { code: '12', title: 'Informatique & Télécoms' },
    { code: '13', title: 'Ressources Humaines' },
    { code: '14', title: 'Espaces Verts & Paysager' },
    { code: '15', title: 'Électricité & Énergies Renouvelables' }
  ].map((s) => ({
    ...s,
    image: `assets/services/service-${s.code}.jpg`
  }));

  let index = 0;

  function prefersReducedMotion() {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }

  function applySlide(i) {
    const slide = SERVICES[i];
    const bg = document.querySelector('.hero-bg-photo');
    const chip = document.getElementById('heroServiceChip');
    const dots = document.getElementById('heroServiceDots');
    if (!bg || !slide) return;
    const gradient = 'linear-gradient(118deg, rgba(20, 20, 22, 0.55) 0%, rgba(122, 18, 72, 0.22) 42%, rgba(0, 0, 0, 0.5) 100%)';
    if (!prefersReducedMotion()) bg.classList.add('hero-bg-fading');
    bg.style.backgroundImage = `${gradient}, url('${slide.image}')`;
    if (chip) {
      chip.replaceChildren();
      const code = document.createElement('span');
      code.className = 'hero-chip-code';
      code.textContent = slide.code;
      const title = document.createElement('span');
      title.className = 'hero-chip-title';
      title.textContent = slide.title;
      chip.append(code, title);
    }
    if (dots) {
      dots.querySelectorAll('.hero-dot').forEach((dot, idx) => {
        const active = idx === i;
        dot.classList.toggle('active', active);
        dot.setAttribute('aria-current', active ? 'true' : 'false');
      });
    }
    const note = document.getElementById('heroMotionNote');
    if (note) note.textContent = `Visuel ${slide.code} : ${slide.title}`;
    if (!prefersReducedMotion()) {
      window.setTimeout(() => bg.classList.remove('hero-bg-fading'), 220);
    } else {
      bg.classList.remove('hero-bg-fading');
    }
  }

  function goTo(nextIndex) {
    index = nextIndex;
    applySlide(index);
  }

  document.addEventListener('DOMContentLoaded', () => {
    const wrap = document.getElementById('heroServiceDots');
    if (wrap) {
      wrap.replaceChildren();
      SERVICES.forEach((_, i) => {
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'hero-dot' + (i === 0 ? ' active' : '');
        btn.dataset.index = String(i);
        btn.setAttribute('aria-label', `Service ${i + 1} sur 15, ${SERVICES[i].title}`);
        btn.addEventListener('click', () => goTo(i));
        wrap.append(btn);
      });
    }
    applySlide(0);
    window.JBF_HERO = {
      isTimerRunning: () => false,
      goTo
    };
  });
})();
