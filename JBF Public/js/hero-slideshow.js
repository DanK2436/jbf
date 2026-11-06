/**
 * Hero accueil — rotation des 15 pôles de services.
 * Le défilement automatique respecte prefers-reduced-motion
 * et ne reprend pas tout seul quand la préférence change.
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
  const motionQuery = window.matchMedia('(prefers-reduced-motion: reduce)');

  let index = 0;
  let timer = null;
  let pausedByUser = motionQuery.matches;

  function prefersReducedMotion() {
    return motionQuery.matches;
  }

  function shouldRunTimer(reduced, userPaused) {
    return !reduced && !userPaused;
  }

  function applySlide(i, animate) {
    const slide = SERVICES[i];
    const bg = document.querySelector('.hero-bg-photo');
    const chip = document.getElementById('heroServiceChip');
    const dots = document.getElementById('heroServiceDots');
    if (!bg || !slide) return;

    const gradient =
      'linear-gradient(118deg, rgba(20, 20, 22, 0.55) 0%, rgba(122, 18, 72, 0.22) 42%, rgba(0, 0, 0, 0.5) 100%)';
    const motionOk = animate && !prefersReducedMotion();

    if (motionOk) bg.classList.add('hero-bg-fading');
    bg.style.backgroundImage = `${gradient}, url('${slide.image}')`;

    if (chip) {
      chip.innerHTML = `<span class="hero-chip-code">${slide.code}</span><span class="hero-chip-title">${slide.title}</span>`;
    }

    if (dots) {
      dots.querySelectorAll('.hero-dot').forEach((dot, idx) => {
        const active = idx === i;
        dot.classList.toggle('active', active);
        dot.setAttribute('aria-current', active ? 'true' : 'false');
      });
    }

    if (motionOk) {
      window.setTimeout(() => bg.classList.remove('hero-bg-fading'), 220);
    } else {
      bg.classList.remove('hero-bg-fading');
    }
  }

  function stopTimer() {
    if (timer) {
      clearInterval(timer);
      timer = null;
    }
  }

  function startTimerIfAllowed() {
    stopTimer();
    if (!shouldRunTimer(prefersReducedMotion(), pausedByUser)) return;
    timer = setInterval(() => {
      if (!shouldRunTimer(prefersReducedMotion(), pausedByUser)) {
        stopTimer();
        return;
      }
      index = (index + 1) % SERVICES.length;
      applySlide(index, true);
    }, INTERVAL_MS);
  }

  function announce(message) {
    const note = document.getElementById('heroMotionNote');
    if (note) note.textContent = message;
  }

  function syncPauseButton() {
    const btn = document.getElementById('heroPause');
    if (!btn) return;
    const reduced = prefersReducedMotion();
    const paused = pausedByUser || reduced;
    btn.setAttribute('aria-pressed', paused ? 'true' : 'false');
    btn.textContent = paused ? 'Reprendre le diaporama' : 'Mettre le diaporama en pause';
    if (reduced) {
      btn.setAttribute('aria-describedby', 'heroMotionNote');
    } else {
      btn.removeAttribute('aria-describedby');
    }
  }

  function onMotionChange() {
    stopTimer();
    if (prefersReducedMotion()) {
      pausedByUser = true;
      announce('Animations réduites : le diaporama reste en pause. Les pastilles permettent de changer de visuel.');
    } else {
      announce('Les animations sont de nouveau autorisées. Le diaporama ne reprend que si vous activez la lecture.');
    }
    syncPauseButton();
  }

  function togglePause() {
    if (prefersReducedMotion()) {
      stopTimer();
      pausedByUser = true;
      announce('Le diaporama reste en pause : votre système demande de réduire les animations. Utilisez les pastilles pour changer de visuel.');
      syncPauseButton();
      return;
    }
    pausedByUser = !pausedByUser;
    if (pausedByUser) {
      stopTimer();
      announce('Diaporama en pause.');
    } else {
      startTimerIfAllowed();
      announce('Diaporama en lecture.');
    }
    syncPauseButton();
  }

  function goTo(nextIndex) {
    index = nextIndex;
    applySlide(index, true);
    if (shouldRunTimer(prefersReducedMotion(), pausedByUser)) startTimerIfAllowed();
    else stopTimer();
  }

  function buildDots() {
    const wrap = document.getElementById('heroServiceDots');
    if (!wrap) return;
    wrap.innerHTML = SERVICES.map((_, i) =>
      `<button type="button" class="hero-dot${i === 0 ? ' active' : ''}" data-index="${i}" aria-label="Service ${i + 1} sur 15"></button>`
    ).join('');
    wrap.querySelectorAll('.hero-dot').forEach((btn) => {
      btn.addEventListener('click', () => {
        goTo(Number(btn.getAttribute('data-index')) || 0);
      });
    });
  }

  document.addEventListener('DOMContentLoaded', () => {
    buildDots();
    applySlide(0, false);
    const pauseBtn = document.getElementById('heroPause');
    if (pauseBtn) pauseBtn.addEventListener('click', togglePause);
    if (typeof motionQuery.addEventListener === 'function') {
      motionQuery.addEventListener('change', onMotionChange);
    } else if (typeof motionQuery.addListener === 'function') {
      motionQuery.addListener(onMotionChange);
    }
    if (prefersReducedMotion()) {
      pausedByUser = true;
      stopTimer();
      announce('Animations réduites : le diaporama ne démarre pas automatiquement.');
    } else {
      startTimerIfAllowed();
    }
    syncPauseButton();
    window.JBF_HERO = {
      shouldRunTimer,
      isTimerRunning: () => Boolean(timer),
      isPaused: () => pausedByUser || prefersReducedMotion(),
      goTo,
      togglePause
    };
  });
})();
