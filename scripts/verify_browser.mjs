/**
 * Vérifie le diaporama, le ticker, le débordement et le focus clavier.
 * Les résultats sont ceux de cette exécution, pas ceux de la revue App.
 */
import { spawn } from 'node:child_process';

const BASE = 'http://127.0.0.1:8765';
const PORT = 9333;

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function waitJson(url) {
  for (let i = 0; i < 40; i += 1) {
    try {
      const res = await fetch(url);
      if (res.ok) return res.json();
    } catch (_) {}
    await sleep(200);
  }
  throw new Error('Chrome DevTools indisponible');
}

class Cdp {
  constructor(ws) {
    this.ws = ws;
    this.seq = 0;
    this.pending = new Map();
    ws.addEventListener('message', (event) => {
      const msg = JSON.parse(event.data);
      if (msg.id && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        if (msg.error) reject(new Error(msg.error.message));
        else resolve(msg.result);
      }
    });
  }
  send(method, params = {}) {
    const id = ++this.seq;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }
  async eval(expression) {
    const result = await this.send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
    if (result.exceptionDetails) {
      throw new Error(result.exceptionDetails.text || 'eval error');
    }
    return result.result?.value;
  }
}

const chrome = spawn('/usr/local/bin/google-chrome', [
  '--headless=new',
  '--disable-gpu',
  '--no-sandbox',
  '--disable-dev-shm-usage',
  `--remote-debugging-port=${PORT}`,
  '--user-data-dir=/tmp/chrome-jbf-verify',
  'about:blank'
], { stdio: 'ignore' });

const report = { checks: [], failures: [] };

function check(name, ok, detail) {
  report.checks.push({ name, ok, detail });
  if (!ok) report.failures.push(name + (detail ? ` — ${detail}` : ''));
}

try {
  const version = await waitJson(`http://127.0.0.1:${PORT}/json/version`);
  const browser = new WebSocket(version.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    browser.addEventListener('open', resolve);
    browser.addEventListener('error', reject);
  });
  const bcdp = new Cdp(browser);
  const { targetId } = await bcdp.send('Target.createTarget', { url: 'about:blank' });
  const { webSocketDebuggerUrl } = (await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json())
    .find((t) => t.id === targetId);
  const pageWs = new WebSocket(webSocketDebuggerUrl);
  await new Promise((resolve) => pageWs.addEventListener('open', resolve));
  const page = new Cdp(pageWs);
  await page.send('Page.enable');
  await page.send('Runtime.enable');
  await page.send('Page.addScriptToEvaluateOnNewDocument', {
    source: `try { localStorage.setItem('JBF_CLIENT_SESSION', JSON.stringify({ email: 'verification.locale@example.com', name: 'Vérification locale', companyName: 'Contrôle UI' })); } catch (e) {}`
  });

  async function open(path, width, height, reduced) {
    await page.send('Emulation.setDeviceMetricsOverride', {
      width, height, deviceScaleFactor: 1, mobile: width < 800
    });
    await page.send('Emulation.setEmulatedMedia', {
      features: [{ name: 'prefers-reduced-motion', value: reduced ? 'reduce' : 'no-preference' }]
    });
    await page.send('Page.navigate', { url: BASE + path });
    await sleep(path.includes('dashboard') ? 2200 : 900);
  }

  await open('/JBF%20Public/index.html', 1280, 900, false);
  const normal = await page.eval(`(() => {
    const ticker = document.querySelector('.ticker-wrap');
    const dot = document.querySelector('.hero-dot');
    dot.focus();
    return {
      animation: getComputedStyle(ticker).animationName,
      scroll: getComputedStyle(document.documentElement).scrollBehavior,
      timer: window.JBF_HERO?.isTimerRunning?.() === true,
      pause: Boolean(document.getElementById('heroPause')),
      label: dot.getAttribute('aria-label') || '',
      chip: document.querySelector('.hero-chip-title')?.textContent || ''
    };
  })()`);
  check('mode normal : ticker animé', normal.animation && normal.animation !== 'none', normal.animation);
  check('mode normal : scroll fluide', normal.scroll === 'smooth', normal.scroll);
  check('diaporama manuel sans timer', normal.timer === false && normal.pause === false, JSON.stringify(normal));
  check('pastille avec libellé', normal.label.includes('Service'), normal.label);

  const before = await page.eval(`document.querySelector('.hero-chip-title').textContent`);
  await page.eval(`document.querySelector('.hero-dot[data-index="2"]').click()`);
  const after = await page.eval(`document.querySelector('.hero-chip-title').textContent`);
  check('navigation manuelle', before !== after, `${before} -> ${after}`);
  await sleep(1200);
  const stayed = await page.eval(`document.querySelector('.hero-chip-title').textContent`);
  check('pas d autoplay', stayed === after, stayed);

  await page.send('Emulation.setEmulatedMedia', {
    features: [{ name: 'prefers-reduced-motion', value: 'reduce' }]
  });
  await sleep(250);
  const switched = await page.eval(`({
    timer: window.JBF_HERO.isTimerRunning(),
    animation: getComputedStyle(document.querySelector('.ticker-wrap')).animationName,
    scroll: getComputedStyle(document.documentElement).scrollBehavior,
    clone: getComputedStyle(document.querySelector('.ticker-clone')).display,
    boot: getComputedStyle(document.querySelector('.boot-logo') || document.body).animationName
  })`);
  check('changement système : pas de timer', switched.timer === false, JSON.stringify(switched));
  check('changement système : ticker arrêté', switched.animation === 'none', switched.animation);
  check('changement système : scroll auto', switched.scroll === 'auto', switched.scroll);
  check('changement système : copie du ticker masquée', switched.clone === 'none', switched.clone);
  const manual = await page.eval(`(() => {
    const dot = document.querySelector('.hero-dot[data-index="4"]');
    dot.focus();
    dot.click();
    return {
      focused: document.activeElement?.getAttribute('data-index') || '',
      chip: document.querySelector('.hero-chip-title').textContent
    };
  })()`);
  check('pastille clavier en mouvement réduit', manual.focused === '4' && manual.chip.length > 0, JSON.stringify(manual));

  await open('/JBF%20Public/index.html', 390, 844, true);
  const cold = await page.eval(`({
    timer: window.JBF_HERO?.isTimerRunning?.() === true,
    pause: Boolean(document.getElementById('heroPause')),
    overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth
  })`);
  check('accueil réduit sans autoplay', cold.timer === false && cold.pause === false, JSON.stringify(cold));
  check('accueil mobile 390 sans débordement', cold.overflow <= 1, String(cold.overflow));

  const pages = [
    ['/JBF%20Public/index.html', 'accueil'],
    ['/JBF%20Public/services.html', 'services'],
    ['/JBF%20Public/contact.html', 'contact'],
    ['/JBF%20Public/avis.html', 'avis'],
    ['/JBF%20Client/dashboard.html', 'tableau client'],
    ['/JBF%20Client/auth/login.html', 'connexion client']
  ];
  for (const width of [320, 768, 1280]) {
    for (const [path, name] of pages) {
      await open(path, width, 900, false);
      const delta = await page.eval(`document.documentElement.scrollWidth - document.documentElement.clientWidth`);
      check(`${name} ${width}px sans débordement`, delta <= 1, String(delta));
    }
  }

  await open('/JBF%20Public/contact.html', 390, 844, false);
  const contactNarrow = await page.eval(`document.documentElement.scrollWidth - document.documentElement.clientWidth`);
  check('contact 390 sans débordement', contactNarrow <= 1, String(contactNarrow));
  const contrast = await page.eval(`(() => {
    function lum(rgb) {
      const m = rgb.match(/[\\d.]+/g).map(Number);
      const c = m.slice(0, 3).map((v) => {
        const s = v / 255;
        return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
      });
      return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
    }
    function ratio(a, b) {
      const L1 = lum(a); const L2 = lum(b);
      const hi = Math.max(L1, L2); const lo = Math.min(L1, L2);
      return (hi + 0.05) / (lo + 0.05);
    }
    function pair(sel, bgSel) {
      const el = document.querySelector(sel);
      const bg = document.querySelector(bgSel);
      if (!el || !bg) return 0;
      return ratio(getComputedStyle(el).color, getComputedStyle(bg).backgroundColor);
    }
    return {
      title: pair('.contact-info-title', '.contact-info-panel'),
      type: pair('.contact-card-type', '.contact-card-box'),
      form: pair('.contact-form-title', '.contact-form-panel'),
      focus: getComputedStyle(document.querySelector('.contact-submit-btn')).outlineStyle || 'none'
    };
  })()`);
  check('contraste titre contact AA', contrast.title >= 4.5, String(contrast.title));
  check('contraste libellé carte AA', contrast.type >= 4.5, String(contrast.type));
  check('contraste titre formulaire AA', contrast.form >= 4.5, String(contrast.form));

  await page.send('Emulation.setDeviceMetricsOverride', {
    width: 640,
    height: 450,
    deviceScaleFactor: 2,
    mobile: false
  });
  await sleep(300);
  const zoomed = await page.eval(`({
    inner: window.innerWidth,
    dpr: window.devicePixelRatio,
    overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth
  })`);
  check('contact zoom navigateur 200 % (viewport CSS réduit, DPR 2)', zoomed.inner <= 660 && zoomed.dpr >= 1.9 && zoomed.overflow <= 1, JSON.stringify(zoomed));
  const form = await page.eval(`(() => {
    const form = document.getElementById('contactForm');
    form.requestSubmit();
    const error = document.querySelector('#contactForm .field-error');
    const invalid = document.querySelector('#contactForm [aria-invalid="true"]');
    return { text: error?.textContent || '', id: invalid?.id || '' };
  })()`);
  check('contact : erreur de champ explicite', Boolean(form.text) && form.id === 'contactNom', JSON.stringify(form));

  await open('/JBF%20Client/dashboard.html', 390, 900, false);
  const charts = await page.eval(`({
    captions: [...document.querySelectorAll('.chart-direct')].map(n => n.textContent.trim()).filter(Boolean).length,
    canvases: document.querySelectorAll('canvas').length,
    overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth
  })`);
  check('graphiques : libellés directs présents', charts.captions === charts.canvases && charts.captions >= 4, JSON.stringify(charts));
  check('tableau de bord mobile sans débordement de page', charts.overflow <= 1, String(charts.overflow));

  console.log(JSON.stringify(report, null, 2));
  if (report.failures.length) process.exitCode = 1;
} catch (error) {
  console.error('Vérification navigateur interrompue:', error);
  process.exitCode = 1;
} finally {
  chrome.kill('SIGKILL');
}
