/**
 * Hero accueil — rotation des 15 pôles de services (15 secondes)
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

  const INTERVAL_MS = 15000;
  let index = 0;
  let timer = null;

  function applySlide(i, animate) {
    const slide = SERVICES[i];
    const bg = document.querySelector('.hero-bg-photo');
    const chip = document.getElementById('heroServiceChip');
    const dots = document.getElementById('heroServiceDots');
    if (!bg || !slide) return;

    const gradient =
      'linear-gradient(118deg, rgba(230, 0, 126, 0.42) 0%, rgba(139, 0, 74, 0.35) 38%, rgba(0, 0, 0, 0.55) 100%)';

    if (animate) bg.classList.add('hero-bg-fading');
    bg.style.backgroundImage = `${gradient}, url('${slide.image}')`;

    if (chip) {
      chip.innerHTML = `<span class="hero-chip-code">${slide.code}</span><span class="hero-chip-title">${slide.title}</span>`;
    }

    if (dots) {
      dots.querySelectorAll('.hero-dot').forEach((dot, idx) => {
        dot.classList.toggle('active', idx === i);
        dot.setAttribute('aria-current', idx === i ? 'true' : 'false');
      });
    }

    if (animate) {
      window.setTimeout(() => bg.classList.remove('hero-bg-fading'), 900);
    }
  }

  function buildDots() {
    const wrap = document.getElementById('heroServiceDots');
    if (!wrap) return;
    wrap.innerHTML = SERVICES.map((_, i) =>
      `<button type="button" class="hero-dot${i === 0 ? ' active' : ''}" data-index="${i}" aria-label="Service ${i + 1}"></button>`
    ).join('');
    wrap.querySelectorAll('.hero-dot').forEach(btn => {
      btn.addEventListener('click', () => {
        index = Number(btn.getAttribute('data-index')) || 0;
        applySlide(index, true);
        restartTimer();
      });
    });
  }

  function restartTimer() {
    if (timer) clearInterval(timer);
    timer = setInterval(() => {
      index = (index + 1) % SERVICES.length;
      applySlide(index, true);
    }, INTERVAL_MS);
  }

  document.addEventListener('DOMContentLoaded', () => {
    buildDots();
    applySlide(0, false);
    restartTimer();
  });
})();
