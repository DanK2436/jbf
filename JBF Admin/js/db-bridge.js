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
      return data.map((row) => {
        const mapped = mapBlogRow(row);
        mapped._sourceTable = table;
        return mapped;
      });
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
  if (!res.error) return { ok: true, data: res.data, table: 'blog_posts' };

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
  return { ok: !res.error, data: res.data, table: 'actualites', error: res.error };
}

async function loadGalleryItemsAdmin() {
  if (!window.adminCore?.querySupabaseTable) return [];

  const merged = [];
  const seen = new Set();

  for (const table of ['gallery_images', 'galerie_items']) {
    const opts = { order: { column: 'created_at', ascending: false }, limit: 300 };
    const { data, error } = await window.adminCore.querySupabaseTable(table, opts);
    if (error || !Array.isArray(data)) continue;
    data.forEach((row) => {
      const mapped = mapGalleryRow(row);
      mapped._sourceTable = table;
      const key = String(mapped.id || mapped.url);
      if (seen.has(key)) return;
      seen.add(key);
      merged.push(mapped);
    });
  }
  return merged;
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
  if (!res.error) return { ok: true, data: res.data, table: 'gallery_images' };

  res = await client.from('galerie_items').insert([payload]).select();
  return { ok: !res.error, data: res.data, table: 'galerie_items', error: res.error };
}

async function updateGalleryItemAdmin(id, payload, sourceTable) {
  if (!window.adminCore?.resolveSupabaseClient || !id) return { ok: false };
  const client = await window.adminCore.resolveSupabaseClient();
  if (!client) return { ok: false };

  const tables = sourceTable ? [sourceTable] : ['gallery_images', 'galerie_items'];
  for (const table of tables) {
    const patch = table === 'gallery_images'
      ? {
        titre: payload.titre,
        categorie: payload.categorie,
        localite: payload.localite || 'RDC',
        description: payload.description || '',
        img_url: payload.url,
        publie: payload.publie !== false
      }
      : {
        titre: payload.titre,
        categorie: payload.categorie,
        type: payload.type,
        url: payload.url,
        description: payload.description,
        localite: payload.localite || 'RDC',
        publie: payload.publie !== false
      };
    const res = await client.from(table).update(patch).eq('id', id).select();
    if (!res.error && res.data && res.data.length) {
      return { ok: true, data: res.data, table };
    }
  }
  return { ok: false, error: 'Mise à jour impossible (id ou table introuvable).' };
}

async function deleteGalleryItemAdmin(id, sourceTable) {
  if (!window.adminCore?.resolveSupabaseClient || !id) return { ok: false };
  const client = await window.adminCore.resolveSupabaseClient();
  if (!client) return { ok: false };

  const tables = sourceTable ? [sourceTable] : ['gallery_images', 'galerie_items'];
  for (const table of tables) {
    const res = await client.from(table).delete().eq('id', id);
    if (!res.error) return { ok: true, table };
  }
  return { ok: false, error: 'Suppression Supabase impossible pour cet identifiant.' };
}

async function updateBlogArticleAdmin(id, payload, sourceTable) {
  if (!window.adminCore?.resolveSupabaseClient || !id) return { ok: false };
  const client = await window.adminCore.resolveSupabaseClient();
  if (!client) return { ok: false };

  const tables = sourceTable ? [sourceTable] : ['blog_posts', 'actualites'];
  for (const table of tables) {
    const patch = table === 'blog_posts'
      ? {
        titre: payload.titre,
        categorie: payload.categorie,
        resume: payload.excerpt || payload.description_courte || '',
        contenu: payload.contenu || payload.description_detaillee || '',
        img_url: payload.image,
        publie: payload.statut !== 'brouillon'
      }
      : {
        titre: payload.titre,
        categorie: payload.categorie,
        excerpt: payload.excerpt,
        description_courte: payload.description_courte,
        contenu: payload.contenu,
        description_detaillee: payload.description_detaillee,
        image: payload.image,
        video: payload.video || '',
        statut: payload.statut || 'publie'
      };
    const res = await client.from(table).update(patch).eq('id', id).select();
    if (!res.error && res.data && res.data.length) {
      return { ok: true, data: res.data, table };
    }
  }
  return { ok: false, error: 'Mise à jour article impossible.' };
}

async function deleteBlogArticleAdmin(id, sourceTable) {
  if (!window.adminCore?.resolveSupabaseClient || !id) return { ok: false };
  const client = await window.adminCore.resolveSupabaseClient();
  if (!client) return { ok: false };

  const tables = sourceTable ? [sourceTable] : ['blog_posts', 'actualites'];
  for (const table of tables) {
    const res = await client.from(table).delete().eq('id', id);
    if (!res.error) return { ok: true, table };
  }
  return { ok: false, error: 'Suppression article impossible.' };
}

window.jbfDbBridge = {
  loadBlogArticlesAdmin,
  insertBlogArticleAdmin,
  updateBlogArticleAdmin,
  deleteBlogArticleAdmin,
  loadGalleryItemsAdmin,
  insertGalleryItemAdmin,
  updateGalleryItemAdmin,
  deleteGalleryItemAdmin,
  mapBlogRow,
  mapGalleryRow
};
