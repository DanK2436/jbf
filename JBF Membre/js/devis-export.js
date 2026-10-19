/**
 * Export devis chef d'équipe — PDF (jsPDF) et Excel (SheetJS) avec identité JBF.
 */
(function (window) {
  'use strict';

  const DOCS_STORAGE_KEY = 'JBF_DEVIS_DOCS_LOCAL';
  const BRAND = {
    name: 'JBF SERVICES',
    tagline: 'Prestations multi-services — République Démocratique du Congo',
    site: 'www.jbf-services.cd',
    email: 'contact@jbf-services.cd'
  };

  function blobToDataUrl(blob) {
    return new Promise((resolve, reject) => {
      const r = new FileReader();
      r.onload = () => resolve(r.result);
      r.onerror = reject;
      r.readAsDataURL(blob);
    });
  }

  async function loadJbfLogoDataUrl(rootPath) {
    const base = rootPath || '';
    const candidates = [`${base}assets/logo.png`, `${base}../assets/logo.png`];
    for (const url of candidates) {
      try {
        const res = await fetch(url);
        if (res.ok) return blobToDataUrl(await res.blob());
      } catch (_) {}
    }
    return null;
  }

  function buildPayload(ctx) {
    return {
      titre: ctx.titre,
      client: ctx.client,
      chef: ctx.chefName,
      domaine: ctx.domaine,
      matricule: ctx.matricule || '',
      notes: ctx.notes || '',
      lines: ctx.lines || [],
      totalCdf: ctx.totalCdf || 0,
      totalUsd: ctx.totalUsd || 0,
      taux: ctx.taux || 1,
      date: new Date().toLocaleString('fr-FR', { timeZone: 'Africa/Lubumbashi' })
    };
  }

  async function generatePdf(payload, logoDataUrl) {
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF({ unit: 'mm', format: 'a4' });
    let y = 14;

    if (logoDataUrl) {
      try {
        doc.addImage(logoDataUrl, 'PNG', 14, y, 32, 18);
      } catch (_) {}
    }
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(16);
    doc.setTextColor(230, 0, 126);
    doc.text(BRAND.name, logoDataUrl ? 50 : 14, y + 8);
    doc.setFontSize(9);
    doc.setTextColor(80, 80, 80);
    doc.text(BRAND.tagline, logoDataUrl ? 50 : 14, y + 14);
    doc.text(BRAND.email + ' • ' + BRAND.site, logoDataUrl ? 50 : 14, y + 19);

    y += 28;
    doc.setDrawColor(230, 0, 126);
    doc.setLineWidth(0.4);
    doc.line(14, y, 196, y);
    y += 8;

    doc.setFontSize(13);
    doc.setTextColor(30, 30, 30);
    doc.text('DEVIS / CHIFFRAGE TECHNIQUE', 14, y);
    y += 7;
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(10);
    doc.text(`Date : ${payload.date}`, 14, y);
    doc.text(`Réf. : DEV-${Date.now().toString().slice(-8)}`, 120, y);
    y += 8;

    doc.setFont('helvetica', 'bold');
    doc.text('Projet :', 14, y);
    doc.setFont('helvetica', 'normal');
    doc.text(payload.titre, 32, y);
    y += 6;
    doc.setFont('helvetica', 'bold');
    doc.text('Client :', 14, y);
    doc.setFont('helvetica', 'normal');
    doc.text(payload.client, 32, y);
    y += 6;
    doc.setFont('helvetica', 'bold');
    doc.text('Chef d\'équipe :', 14, y);
    doc.setFont('helvetica', 'normal');
    doc.text(`${payload.chef}${payload.matricule ? ' (' + payload.matricule + ')' : ''}`, 42, y);
    y += 6;
    doc.setFont('helvetica', 'bold');
    doc.text('Domaine :', 14, y);
    doc.setFont('helvetica', 'normal');
    doc.text(payload.domaine || '—', 32, y);
    y += 8;

    const tableBody = (payload.lines || []).map((ln) => [
      ln.label || '',
      String(ln.qty ?? ''),
      (Number(ln.unit_price_cdf) || 0).toLocaleString('fr-FR'),
      (Number(ln.total_cdf) || 0).toLocaleString('fr-FR') + ' CDF'
    ]);

    doc.autoTable({
      startY: y,
      head: [['Désignation', 'Qté', 'P.U. CDF', 'Total CDF']],
      body: tableBody.length ? tableBody : [['—', '—', '—', '—']],
      styles: { fontSize: 9, cellPadding: 2 },
      headStyles: { fillColor: [230, 0, 126], textColor: 255 },
      margin: { left: 14, right: 14 }
    });

    y = doc.lastAutoTable.finalY + 8;
    doc.setFont('helvetica', 'bold');
    doc.text(`Total CDF : ${(payload.totalCdf || 0).toLocaleString('fr-FR')} CDF`, 14, y);
    y += 6;
    doc.setFont('helvetica', 'normal');
    doc.text(`Taux appliqué : 1 USD = ${payload.taux} CDF`, 14, y);
    y += 6;
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(230, 0, 126);
    doc.text(`Équivalent USD : $${(payload.totalUsd || 0).toLocaleString('fr-FR', { minimumFractionDigits: 2 })}`, 14, y);

    if (payload.notes) {
      y += 10;
      doc.setTextColor(60, 60, 60);
      doc.setFont('helvetica', 'bold');
      doc.text('Notes :', 14, y);
      y += 5;
      doc.setFont('helvetica', 'normal');
      const split = doc.splitTextToSize(payload.notes, 180);
      doc.text(split, 14, y);
    }

    y = 280;
    doc.setFontSize(8);
    doc.setTextColor(120, 120, 120);
    doc.text('Document généré par l\'Espace Chef d\'équipe JBF SERVICES — usage interne et transmission administration.', 14, y);

    return doc.output('datauristring');
  }

  async function generateExcel(payload, logoDataUrl) {
    const XLSX = window.XLSX;
    const wb = XLSX.utils.book_new();

    const meta = [
      [BRAND.name],
      [BRAND.tagline],
      [BRAND.email, BRAND.site],
      [],
      ['DEVIS / CHIFFRAGE TECHNIQUE'],
      ['Date', payload.date],
      ['Projet', payload.titre],
      ['Client', payload.client],
      ['Chef d\'équipe', payload.chef],
      ['Matricule', payload.matricule || ''],
      ['Domaine', payload.domaine || ''],
      []
    ];

    const header = ['Désignation', 'Quantité', 'P.U. (CDF)', 'Total (CDF)'];
    const rows = (payload.lines || []).map((ln) => [
      ln.label || '',
      ln.qty ?? 0,
      ln.unit_price_cdf ?? 0,
      ln.total_cdf ?? 0
    ]);
    const sheetData = meta.concat([header], rows, [
      [],
      ['Total CDF', '', '', payload.totalCdf],
      ['Taux (CDF/USD)', payload.taux],
      ['Total USD', payload.totalUsd],
      [],
      ['Notes', payload.notes || '']
    ]);

    const ws = XLSX.utils.aoa_to_sheet(sheetData);
    ws['!cols'] = [{ wch: 42 }, { wch: 12 }, { wch: 14 }, { wch: 16 }];
    XLSX.utils.book_append_sheet(wb, ws, 'Devis');

    if (logoDataUrl && XLSX.utils.aoa_to_sheet) {
      const info = XLSX.utils.aoa_to_sheet([['Logo JBF (voir PDF pour visuel)'], [BRAND.name]]);
      XLSX.utils.book_append_sheet(wb, info, 'Identité JBF');
    }

    const wbout = XLSX.write(wb, { bookType: 'xlsx', type: 'array' });
    const blob = new Blob([wbout], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    return blobToDataUrl(blob);
  }

  function saveDevisDocuments(devisId, docs) {
    let map = {};
    try {
      map = JSON.parse(localStorage.getItem(DOCS_STORAGE_KEY) || '{}');
    } catch (_) {}
    map[devisId] = { ...map[devisId], ...docs, updated_at: new Date().toISOString() };
    localStorage.setItem(DOCS_STORAGE_KEY, JSON.stringify(map));
  }

  function getDevisDocuments(devisId) {
    try {
      const map = JSON.parse(localStorage.getItem(DOCS_STORAGE_KEY) || '{}');
      return map[devisId] || null;
    } catch (_) {
      return null;
    }
  }

  function downloadDataUrl(dataUrl, fileName) {
    const a = document.createElement('a');
    a.href = dataUrl;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    a.remove();
  }

  window.JBFDevisExport = {
    BRAND,
    loadJbfLogoDataUrl,
    buildPayload,
    generatePdf,
    generateExcel,
    saveDevisDocuments,
    getDevisDocuments,
    downloadDataUrl,
    DOCS_STORAGE_KEY
  };
})(window);
