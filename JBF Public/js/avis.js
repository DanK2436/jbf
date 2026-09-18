/* =============================================================
   JBF SERVICES — AVIS CLIENTS SCRIPT (js/avis.js)
   ============================================================= */

document.addEventListener('DOMContentLoaded', () => {
  initStarSelector();
  initReviewForm();
});

let selectedRating = 5;

function initStarSelector() {
  const stars = document.querySelectorAll('#starRatingSelector svg');
  stars.forEach(star => {
    star.addEventListener('click', () => {
      selectedRating = parseInt(star.dataset.star);
      stars.forEach(s => {
        if (parseInt(s.dataset.star) <= selectedRating) {
          s.classList.add('active');
        } else {
          s.classList.remove('active');
        }
      });
    });
  });
}

function filterReviews(cat, btn) {
  document.querySelectorAll('.fc').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');

  const cards = document.querySelectorAll('#reviewsGrid .review-card');
  cards.forEach(card => {
    if (cat === 'all' || card.dataset.cat === cat) {
      card.style.display = 'flex';
    } else {
      card.style.display = 'none';
    }
  });
}

function openReviewModal() {
  const modal = document.getElementById('reviewModal');
  if (modal) modal.classList.add('open');
}

function closeReviewModal() {
  const modal = document.getElementById('reviewModal');
  if (modal) modal.classList.remove('open');
}

function initReviewForm() {
  const form = document.getElementById('addReviewForm');
  if (!form) return;

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = document.getElementById('revName').value.trim();
    const company = document.getElementById('revCompany').value.trim() || 'Client JBF';
    const service = document.getElementById('revService').value;
    const comment = document.getElementById('revComment').value.trim();

    if (!name || !comment) {
      showToast('Veuillez remplir tous les champs obligatoires');
      return;
    }

    const newCard = document.createElement('div');
    newCard.className = 'review-card reveal visible';
    newCard.dataset.cat = service;

    const initials = name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
    const starsHtml = Array(selectedRating).fill('<svg class="star-icon" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>').join('');

    newCard.innerHTML = `
      <div class="review-header">
        <div class="review-author-info">
          <div class="review-avatar">${initials}</div>
          <div>
            <div class="review-author-name">${escapeHtml(name)}</div>
            <div class="review-author-company">${escapeHtml(company)}</div>
          </div>
        </div>
        <span class="verified-badge">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"></polyline></svg>
          Vérifié
        </span>
      </div>
      <div class="review-service-tag">${escapeHtml(service)}</div>
      <div class="rating-stars" style="justify-content:flex-start; margin-bottom:0.75rem;">
        ${starsHtml}
      </div>
      <p class="review-text">"${escapeHtml(comment)}"</p>
      <div class="review-date">Publié aujourd'hui</div>
    `;

    const grid = document.getElementById('reviewsGrid');
    grid.insertBefore(newCard, grid.firstChild);

    closeReviewModal();
    form.reset();
    showToast('Merci ! Votre avis a été publié avec succès.');
  });
}

function escapeHtml(str) {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function showToast(msg) {
  let toast = document.getElementById('toastMsg');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'toastMsg';
    toast.className = 'toast-msg';
    document.body.appendChild(toast);
  }
  toast.textContent = msg;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 3500);
}
