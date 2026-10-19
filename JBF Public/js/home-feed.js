/**
 * Flux d'accueil — actualités & avis depuis Supabase (blog_posts / avis_clients)
 */
(function () {
  const SUPABASE_URL = 'https://dvzwqxcaiagczyonrhsg.supabase.co';
  const SUPABASE_ANON_KEY =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2endxeGNhaWFnY3p5b25yaHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1ODEzNzIsImV4cCI6MjEwNTE1NzM3Mn0.uam5Z-d6SWS9-4Ly9f0ircJPryFJwOXbNp9_alHHl-o';

  function escapeHtml(str) {
    return String(str || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function stars(n) {
    const v = Math.max(1, Math.min(5, Number(n) || 5));
    return '★'.repeat(v) + '☆'.repeat(5 - v);
  }

  async function getClient() {
    if (typeof supabase === 'undefined') return null;
    return supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  }

  async function loadArticles(client) {
    let { data, error } = await client
      .from('blog_posts')
      .select('id, titre, categorie, resume, img_url, created_at')
      .eq('publie', true)
      .order('created_at', { ascending: false })
      .limit(3);

    if (error || !data?.length) {
      const legacy = await client.from('actualites').select('*').order('created_at', { ascending: false }).limit(3);
      data = legacy.data;
    }
    return data || [];
  }

  async function loadAvis(client) {
    const { data } = await client
      .from('avis_clients')
      .select('nom, entreprise, service, note, commentaire, created_at')
      .eq('approuve', true)
      .order('created_at', { ascending: false })
      .limit(3);
    return data || [];
  }

  function renderArticles(articles) {
    const el = document.getElementById('homeNewsGrid');
    if (!el) return;
    if (!articles.length) {
      el.innerHTML =
        '<p class="home-feed-empty">Les dernières analyses seront publiées prochainement. Consultez la page <a href="blog.html">Actualités</a>.</p>';
      return;
    }
    el.innerHTML = articles
      .map((a) => {
        const img = a.img_url || a.image || 'assets/gallery_construction.jpg';
        const excerpt = (a.resume || a.excerpt || a.description_courte || '').slice(0, 120);
        return `
        <article class="home-feed-card reveal">
          <div class="home-feed-thumb" style="background-image:url('${escapeHtml(img)}')"></div>
          <div class="home-feed-body">
            <span class="home-feed-tag">${escapeHtml(a.categorie || 'Actualité')}</span>
            <h3>${escapeHtml(a.titre || a.title || 'Publication JBF')}</h3>
            <p>${escapeHtml(excerpt)}${excerpt.length >= 120 ? '…' : ''}</p>
            <a href="blog.html" class="home-feed-link">Lire sur le blog →</a>
          </div>
        </article>`;
      })
      .join('');
  }

  function renderAvis(list) {
    const el = document.getElementById('homeAvisGrid');
    if (!el) return;
    if (!list.length) {
      el.innerHTML =
        '<p class="home-feed-empty">Soyez le premier à laisser un témoignage sur la page <a href="avis.html">Avis Clients</a>.</p>';
      return;
    }
    el.innerHTML = list
      .map(
        (a) => `
      <blockquote class="home-avis-card reveal">
        <div class="home-avis-stars" aria-label="Note ${a.note || 5} sur 5">${stars(a.note)}</div>
        <p>"${escapeHtml((a.commentaire || '').slice(0, 160))}${(a.commentaire || '').length > 160 ? '…' : ''}"</p>
        <footer>
          <strong>${escapeHtml(a.nom || 'Client JBF')}</strong>
          <span>${escapeHtml(a.entreprise || a.service || 'Partenaire industriel')}</span>
        </footer>
      </blockquote>`
      )
      .join('');
  }

  document.addEventListener('DOMContentLoaded', async () => {
    const client = await getClient();
    if (!client) return;
    try {
      const [articles, avis] = await Promise.all([loadArticles(client), loadAvis(client)]);
      renderArticles(articles);
      renderAvis(avis);
      document.querySelectorAll('#homeLiveSection .reveal').forEach((el) => {
        if (typeof IntersectionObserver !== 'undefined') {
          /* laisser l'observer existant gérer les nouvelles cartes */
        }
        el.classList.add('visible');
      });
    } catch (err) {
      console.warn('[Accueil Supabase]', err);
    }
  });
})();
