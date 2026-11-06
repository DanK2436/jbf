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
    const style = getComputedStyle(ticker);
    const pause = document.getElementById('heroPause');
    pause.focus();
    return {
      animation: style.animationName,
      scroll: getComputedStyle(document.documentElement).scrollBehavior,
      timer: window.JBF_HERO?.isTimerRunning?.() || false,
      paused: pause.getAttribute('aria-pressed'),
      active: document.activeElement?.id || '',
      chip: document.querySelector('.hero-chip-title')?.textContent || ''
    };
  })()`);
  check('mode normal : ticker animé', normal.animation && normal.animation !== 'none', normal.animation);
  check('mode normal : scroll fluide', normal.scroll === 'smooth', normal.scroll);
  check('mode normal : timer démarré', normal.timer === true, String(normal.timer));
  check('pause focusable au clavier', normal.active === 'heroPause', normal.active);

  await page.eval(`document.getElementById('heroPause').click()`);
  const paused = await page.eval(`({
    pressed: document.getElementById('heroPause').getAttribute('aria-pressed'),
    timer: window.JBF_HERO.isTimerRunning(),
    label: document.getElementById('heroPause').textContent
  })`);
  check('pause clavier/clic arrête le timer', paused.pressed === 'true' && paused.timer === false, JSON.stringify(paused));

  const before = await page.eval(`document.querySelector('.hero-chip-title').textContent`);
  await page.eval(`document.querySelector('.hero-dot[data-index="2"]').click()`);
  const after = await page.eval(`document.querySelector('.hero-chip-title').textContent`);
  check('navigation manuelle pendant la pause', before !== after, `${before} -> ${after}`);

  await page.eval(`document.getElementById('heroPause').click()`);
  const resumed = await page.eval(`window.JBF_HERO.isTimerRunning()`);
  check('reprise explicite relance le timer', resumed === true, String(resumed));

  await page.send('Emulation.setEmulatedMedia', {
    features: [{ name: 'prefers-reduced-motion', value: 'reduce' }]
  });
  await sleep(250);
  const switched = await page.eval(`({
    timer: window.JBF_HERO.isTimerRunning(),
    pressed: document.getElementById('heroPause').getAttribute('aria-pressed'),
    animation: getComputedStyle(document.querySelector('.ticker-wrap')).animationName,
    scroll: getComputedStyle(document.documentElement).scrollBehavior,
    clone: getComputedStyle(document.querySelector('.ticker-clone')).display
  })`);
  check('changement système : timer arrêté', switched.timer === false, JSON.stringify(switched));
  check('changement système : ticker arrêté', switched.animation === 'none', switched.animation);
  check('changement système : scroll auto', switched.scroll === 'auto', switched.scroll);
  check('changement système : copie du ticker masquée', switched.clone === 'none', switched.clone);

  await page.eval(`document.getElementById('heroPause').click()`);
  const noAuto = await page.eval(`window.JBF_HERO.isTimerRunning()`);
  check('reprise refusée tant que le mouvement est réduit', noAuto === false, String(noAuto));
  const manual = await page.eval(`(() => {
    const dot = document.querySelector('.hero-dot[data-index="4"]');
    dot.focus();
    dot.click();
    return {
      focused: document.activeElement?.getAttribute('data-index') || '',
      chip: document.querySelector('.hero-chip-title').textContent
    };
  })()`);
  check('pastille clavier et navigation manuelle en mode réduit', manual.focused === '4' && manual.chip.length > 0, JSON.stringify(manual));

  await open('/JBF%20Public/index.html', 390, 844, true);
  const cold = await page.eval(`({
    timer: window.JBF_HERO?.isTimerRunning?.() || false,
    pressed: document.getElementById('heroPause')?.getAttribute('aria-pressed'),
    overflow: document.documentElement.scrollWidth - document.documentElement.clientWidth
  })`);
  check('chargement réduit : timer non démarré', cold.timer === false && cold.pressed === 'true', JSON.stringify(cold));
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

  await open('/JBF%20Public/contact.html', 1280, 900, false);
  await page.eval(`document.documentElement.style.zoom = '2'`);
  await sleep(200);
  const zoomed = await page.eval(`document.documentElement.scrollWidth - document.documentElement.clientWidth`);
  check('contact zoom CSS 200 % sans débordement de page', zoomed <= 2, String(zoomed));
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
