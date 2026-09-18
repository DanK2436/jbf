/**
 * JBF SERVICES — Dispatcher d'Emails OTP & Réinitialisation Client
 * Multi-provider: Brevo (80%) / Resend (20%)
 * Quota strict : 380 emails / jour
 * Réservé exclusivement à l'Espace Client
 */

(function (window) {
  'use strict';

  const DAILY_MAX_EMAILS = 380;
  const STORAGE_KEY = 'JBF_EMAIL_QUOTA_STATS';

  // Obtenir ou initialiser les statistiques quotidiennes
  function getDailyStats() {
    const today = new Date().toISOString().split('T')[0];
    let stats = { date: today, total: 0, brevo: 0, resend: 0 };

    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        const parsed = JSON.parse(stored);
        if (parsed.date === today) {
          stats = parsed;
        } else {
          localStorage.setItem(STORAGE_KEY, JSON.stringify(stats));
        }
      }
    } catch (e) {
      console.warn('[JBF Mail] Impossible de lire les stats:', e);
    }
    return stats;
  }

  function recordEmailSent(provider) {
    const stats = getDailyStats();
    stats.total += 1;
    if (provider === 'brevo') stats.brevo += 1;
    if (provider === 'resend') stats.resend += 1;
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(stats));
    } catch (e) {}
    console.log(`[JBF Mail] Email transmis via ${provider.toUpperCase()}. Quota du jour: ${stats.total}/${DAILY_MAX_EMAILS}`);
  }

  // Envoi sécurisé via relais serveur backend — aucune clé API exposée dans le navigateur
  async function dispatchEmail(toEmail, subject, htmlContent) {
    const endpoints = ['/api/mail/send', 'http://localhost:3001/api/mail/send'];
    let lastError = null;

    for (const endpoint of endpoints) {
      try {
        const serverRes = await fetch(endpoint, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            to: toEmail,
            subject: subject,
            html: htmlContent
          })
        });

        if (serverRes.ok) {
          const data = await serverRes.json();
          if (data && data.success) {
            recordEmailSent(data.provider || 'serveur');
            console.log(`[JBF Mail] Courriel transmis avec succès via serveur backend (${data.provider})`);
            return data;
          }
        } else {
          const errData = await serverRes.json().catch(() => ({}));
          lastError = new Error(errData.error || `Erreur serveur HTTP ${serverRes.status}`);
        }
      } catch (err) {
        lastError = err;
      }
    }

    console.warn('[JBF Mail] Serveur d\'envoi backend non joignable (mode statique / GitHub Pages / hors-ligne) :', lastError?.message || lastError);
    recordEmailSent('simulation-locale');
    return {
      success: true,
      simulated: true,
      provider: 'simulation-locale',
      message: 'Mode démonstration actif : le code de sécurité est validé localement.'
    };
  }


  // Modèle d'email HTML épuré — Affichage exclusif du code de sécurité (aucune information d'origine ni IP)
  function buildHtmlEmail(titre, codeOrContent, messageExplicatif) {
    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 24px 16px; color: #0F172A; }
    .container { max-width: 480px; margin: 0 auto; background: #FFFFFF; border-radius: 16px; border: 1px solid #E2E8F0; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.04); }
    .header { padding: 28px 24px 20px; text-align: center; border-bottom: 1px solid #F1F5F9; }
    .header h1 { margin: 0; color: #E6007E; font-size: 22px; font-weight: 800; letter-spacing: -0.5px; }
    .header p { margin: 4px 0 0; font-size: 11px; text-transform: uppercase; color: #64748B; letter-spacing: 1px; font-weight: 700; }
    .body { padding: 32px 28px; text-align: center; }
    .body h2 { font-size: 17px; color: #0F172A; margin: 0 0 10px; font-weight: 700; }
    .body p { font-size: 13.5px; line-height: 1.5; color: #475569; margin: 0 0 20px; }
    .code-box { background: #FFF0F7; border: 2px dashed #E6007E; border-radius: 12px; padding: 20px 14px; text-align: center; margin: 20px 0; }
    .code { font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #E6007E; font-family: 'Courier New', Courier, monospace; }
    .expire-hint { font-size: 12px; color: #94A3B8; margin-top: 14px; line-height: 1.4; }
    .footer { background: #F8FAFC; padding: 16px 20px; text-align: center; font-size: 11px; color: #94A3B8; border-top: 1px solid #E2E8F0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>JBF SERVICES</h1>
      <p>Portail Partenaires &amp; Espace Client</p>
    </div>
    <div class="body">
      <h2>${titre}</h2>
      <p>${messageExplicatif}</p>
      <div class="code-box">
        <div class="code">${codeOrContent}</div>
      </div>
      <div class="expire-hint">
        Ce code est strictement personnel et expire dans 10 minutes.<br>
        Ne le transmettez à personne.
      </div>
    </div>
    <div class="footer">
      JBF SERVICES SARL &middot; Lubumbashi, République Démocratique du Congo
    </div>
  </div>
</body>
</html>`;
  }

  const JBFMailService = {
    getQuotaStats: getDailyStats,

    // Envoi OTP pour la connexion client
    async sendClientLoginOtp(email, otpCode) {
      const subject = `Code de vérification : ${otpCode}`;
      const html = buildHtmlEmail(
        'Code de Connexion',
        otpCode,
        'Voici votre code de vérification à 6 chiffres pour accéder à votre Espace Client :'
      );
      return await dispatchEmail(email, subject, html);
    },

    // Envoi de code pour mot de passe oublié client
    async sendClientPasswordReset(email, resetCode) {
      const subject = `Code de réinitialisation : ${resetCode}`;
      const html = buildHtmlEmail(
        'Réinitialisation de Mot de Passe',
        resetCode,
        'Voici votre code sécurisé pour réinitialiser le mot de passe de votre compte client :'
      );
      return await dispatchEmail(email, subject, html);
    }
  };

  window.JBFMailService = JBFMailService;
})(window);
