/**
 * Ressources HSE — fusion local / Supabase et masquage côté membre.
 */
(function (window) {
  'use strict';

  const STORAGE_KEY = 'JBF_RESSOURCES_LOCAL';
  const HIDDEN_MEMBER_KEY = 'JBF_RESSOURCES_HIDDEN_MEMBER';
  const MAX_ID_LEN = 120;

  function hashFingerprint(str) {
    let h = 2166136261;
    const s = String(str || '').slice(0, 600);
    for (let i = 0; i < s.length; i++) {
      h ^= s.charCodeAt(i);
      h = Math.imul(h, 16777619);
    }
    return (h >>> 0).toString(36);
  }

  function idLooksUnsafe(id) {
    const s = String(id || '');
    if (!s) return true;
    if (s.length > MAX_ID_LEN) return true;
    if (/^data:[\w/+.-]+;base64,/i.test(s)) return true;
    return false;
  }

  function stableIdForRow(row) {
    const created = row.created_at || '';
    const fileSlice = String(row.fichier_url || '').slice(0, 160);
    const label = row._fileLabel || row.document_nom || '';
    return `res-stab-${hashFingerprint(`${created}|${fileSlice}|${label}`)}`;
  }

  function ensureStableResourceRow(row) {
    if (!row || typeof row !== 'object') return row;
    let r = { ...row };
    if (window.JBFResourceDisplay?.normalizeResourceRow) {
      r = window.JBFResourceDisplay.normalizeResourceRow(r);
    }
    if (idLooksUnsafe(r.id)) {
      r.id = stableIdForRow(r);
    } else {
      r.id = String(r.id);
    }
    return r;
  }

  function getResourceAliasIds(row) {
    const ids = new Set();
    if (!row) return ids;
    const raw = row.id;
    if (raw != null && raw !== '') ids.add(String(raw));
    ids.add(stableIdForRow(row));
    if (row.created_at && row.titre != null) {
      ids.add(`${row.created_at}-${row.titre}`);
    }
    return ids;
  }

  function readLocal() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      return raw ? JSON.parse(raw) : [];
    } catch (_) {
      return [];
    }
  }

  function writeLocal(list) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(list || []));
    } catch (_) {}
  }

  function getHiddenMemberIds() {
    try {
      const raw = localStorage.getItem(HIDDEN_MEMBER_KEY);
      return raw ? JSON.parse(raw) : [];
    } catch (_) {
      return [];
    }
  }

  function addHiddenMemberId(id) {
    const set = new Set(getHiddenMemberIds().map(String));
    set.add(String(id));
    localStorage.setItem(HIDDEN_MEMBER_KEY, JSON.stringify(Array.from(set)));
  }

  function isHiddenRow(row, hidden) {
    return getResourceAliasIds(row).some((aid) => hidden.has(aid));
  }

  function mergeResourceLists(remote, local, hiddenIds) {
    const hidden = new Set((hiddenIds || []).map(String));
    const map = new Map();
    [...(local || []), ...(remote || [])].forEach((raw) => {
      if (!raw) return;
      const r = ensureStableResourceRow(raw);
      if (isHiddenRow(r, hidden)) return;
      const id = String(r.id);
      const prev = map.get(id);
      map.set(id, prev ? { ...prev, ...r, id } : r);
    });
    let list = Array.from(map.values());
    if (window.JBFResourceDisplay?.normalizeResourceList) {
      list = window.JBFResourceDisplay.normalizeResourceList(list);
    }
    return list.sort(
      (a, b) => new Date(b.created_at || 0) - new Date(a.created_at || 0)
    );
  }

  function removeResourceEverywhere(id) {
    const sid = String(id);
    addHiddenMemberId(sid);
    const local = readLocal();
    let matched = null;
    const next = local.filter((raw) => {
      const r = ensureStableResourceRow(raw);
      const aliases = getResourceAliasIds(r);
      if (aliases.has(sid) || String(r.id) === sid) {
        matched = r;
        return false;
      }
      return true;
    });
    if (matched) {
      getResourceAliasIds(matched).forEach((aid) => addHiddenMemberId(aid));
    }
    writeLocal(next);
    return next;
  }

  function prepareResourceForSave(row) {
    let r = { ...row };
    if (window.JBFResourceDisplay) {
      r = window.JBFResourceDisplay.normalizeResourceRow(r);
      if (window.JBFResourceDisplay.looksLikeDataUrl(r.titre)) {
        r.titre = r._fileLabel || 'Document partagé';
      }
      if (window.JBFResourceDisplay.looksLikeDataUrl(r.description)) {
        r.description = '';
      }
    }
    if (r.fichier_url && r.description === r.fichier_url) r.description = '';
    return r;
  }

  window.JBFResourcesSync = {
    STORAGE_KEY,
    HIDDEN_MEMBER_KEY,
    readLocal,
    writeLocal,
    getHiddenMemberIds,
    mergeResourceLists,
    removeResourceEverywhere,
    prepareResourceForSave,
    ensureStableResourceRow,
    getResourceAliasIds,
    stableIdForRow
  };
})(window);
