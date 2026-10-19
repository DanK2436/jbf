// =============================================================
// JBF ADMIN — Pont Supabase (tables canoniques + alias legacy)
// =============================================================

function mapBlogRow(row) {
  return {
    id: row.id,
    titre: row.titre || row.title,
    categorie: row.categorie || 'Général',
    excerpt: row.resume || row.excerpt || row.description_courte || '',
    description_courte: row.resume || row.excerpt || row.description_courte || '',
    contenu: row.contenu || row.content || row.description_detaillee || '',
    description_detaillee: row.contenu || row.content || row.description_detaillee || '',
    image: row.img_url || row.image || row.image_url || '../assets/gallery_mining.jpg',
    video: row.video_url || row.video || '',
    auteur: row.auteur || 'Direction JBF',
    created_at: row.created_at || row.date_publication || new Date().toISOString(),
    statut: row.publie === false ? 'brouillon' : 'publie'
  };
}

function mapGalleryRow(row) {
  const url = row.img_url || row.url || row.image_url || '';
  const isVideo = row.type === 'video' || (url && /\.(mp4|webm|mov)(\?|$)/i.test(url));
  return {
    id: row.id,
    titre: row.titre || row.title || 'Réalisation JBF',
    categorie: row.categorie || 'Général',
    type: isVideo ? 'video' : (row.type || 'photo'),
    url,
    description: row.description || row.desc || '',
    localite: row.localite || 'RDC',
    publie: row.publie !== false,
    created_at: row.created_at || new Date().toISOString()
  };
}

async function loadBlogArticlesAdmin() {
  if (!window.adminCore?.querySupabaseTable) return [];

  const tables = ['blog_posts', 'actualites'];
  for (const table of tables) {
    const opts = { order: { column: 'created_at', ascending: false }, limit: 200 };
    const { data, error } = await window.adminCore.querySupabaseTable(table, opts);
    if (!error && Array.isArray(data) && data.length > 0) {
      return data.map(mapBlogRow);
    }
  }
  return [];
}

async function insertBlogArticleAdmin(payload) {
  if (!window.adminCore?.resolveSupabaseClient) return { ok: false };
  const client = await window.adminCore.resolveSupabaseClient();
  if (!client) return { ok: false };
  return insertBlogWithClient(client, payload);
}

async function insertBlogWithClient(client, payload) {
  const canonical = {
    titre: payload.titre,
    categorie: payload.categorie,
    resume: payload.excerpt || payload.description_courte || '',
    contenu: payload.contenu || payload.description_detaillee || '',
    img_url: payload.image,
    publie: true,
    temps_lecture: '5 min de lecture'
  };

  let res = await client.from('blog_posts').insert([canonical]).select();
  if (!res.error) return { ok: true, data: res.data };

  const legacy = {
    titre: payload.titre,
    categorie: payload.categorie,
    excerpt: payload.excerpt,
    description_courte: payload.description_courte,
    contenu: payload.contenu,
    description_detaillee: payload.description_detaillee,
    image: payload.image,
    video: payload.video || '',
    auteur: payload.auteur || 'Direction JBF',
    statut: 'publie',
    created_at: payload.created_at || new Date().toISOString()
  };
  res = await client.from('actualites').insert([legacy]).select();
  return { ok: !res.error, data: res.data, error: res.error };
}

async function loadGalleryItemsAdmin() {
  if (!window.adminCore?.querySupabaseTable) return [];

  for (const table of ['gallery_images', 'galerie_items']) {
    const opts = { order: { column: 'created_at', ascending: false }, limit: 300 };
    if (table === 'gallery_images') opts.eq = { publie: true };
    const { data, error } = await window.adminCore.querySupabaseTable(table, opts);
    if (!error && Array.isArray(data) && data.length > 0) {
      return data.map(mapGalleryRow);
    }
  }
  return [];
}

async function insertGalleryItemAdmin(payload) {
  if (!window.adminCore?.resolveSupabaseClient) return { ok: false };
  const client = await window.adminCore.resolveSupabaseClient();
  if (!client) return { ok: false };

  const canonical = {
    titre: payload.titre,
    categorie: payload.categorie,
    localite: payload.localite || 'RDC',
    description: payload.description || '',
    img_url: payload.url,
    publie: true
  };

  let res = await client.from('gallery_images').insert([canonical]).select();
  if (!res.error) return { ok: true, data: res.data };

  res = await client.from('galerie_items').insert([payload]).select();
  return { ok: !res.error, data: res.data, error: res.error };
}

window.jbfDbBridge = {
  loadBlogArticlesAdmin,
  insertBlogArticleAdmin,
  loadGalleryItemsAdmin,
  insertGalleryItemAdmin,
  mapBlogRow,
  mapGalleryRow
};
