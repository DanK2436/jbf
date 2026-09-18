// =============================================================
// JBF SERVICES — MODULE SÉCURITÉ & ANTI-VPN CLIENT v8.0
// Détection de VPN / Proxy & Traçabilité IP pour Pointage
// =============================================================

(function () {
  const API_ENDPOINT = 'http://localhost:3001/api/verify-security';
  let isVpnActive = false;
  let clientSecurityInfo = null;

  // Création du conteneur de blocage dans le DOM
  function createBlockingOverlay(info) {
    let overlay = document.getElementById('jbf-vpn-blocking-overlay');
    if (!overlay) {
      overlay = document.createElement('div');
      overlay.id = 'jbf-vpn-blocking-overlay';
      overlay.style.position = 'fixed';
      overlay.style.inset = '0';
      overlay.style.zIndex = '999999';
      overlay.style.background = 'linear-gradient(135deg, rgba(125,8,69,0.98) 0%, rgba(230,0,126,0.98) 100%)';
      overlay.style.backdropFilter = 'blur(16px)';
      overlay.style.display = 'flex';
      overlay.style.alignItems = 'center';
      overlay.style.justifyContent = 'center';
      overlay.style.padding = '1.5rem';
      overlay.style.color = '#FFFFFF';
      overlay.style.fontFamily = "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif";
      document.body.appendChild(overlay);
    }

    const ip = info?.ip || 'Non identifiée';
    const isp = info?.isp || 'Fournisseur / Datacenter Masqué';
    const location = info?.city ? `${info.city}, ${info.country}` : (info?.country || 'Localisation Altérée');

    overlay.innerHTML = `
      <div style="background:#FFFFFF; color:#3B0421; border-radius:20px; max-width:540px; width:100%; padding:2.5rem 2rem; text-align:center; box-shadow:0 25px 60px rgba(0,0,0,0.35); border-top:6px solid #E6007E;">
        
        <div style="width:70px; height:70px; background:#FDF2F7; border:2px solid #F1BED7; border-radius:50%; display:flex; align-items:center; justify-content:center; margin:0 auto 1.25rem;">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#E6007E" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
          </svg>
        </div>

        <div style="display:inline-block; background:#FEE2E2; color:#DC2626; padding:0.35rem 0.9rem; border-radius:20px; font-size:0.75rem; font-weight:900; letter-spacing:1px; text-transform:uppercase; margin-bottom:0.75rem; border:1px solid #FECACA;">
          ● Sécurité Pointage Activée
        </div>

        <h1 style="font-size:1.45rem; font-weight:900; color:#3B0421; margin-bottom:0.6rem; line-height:1.2;">
          Accès Bloqué : VPN ou Proxy Détecté
        </h1>

        <p style="font-size:0.9rem; color:#6B7280; line-height:1.55; margin-bottom:1.5rem;">
          Pour garantir l'authenticité des <strong>pointages géolocalisés</strong> et la sécurité des opérations sur les chantiers en <strong>République Démocratique du Congo</strong>, l'utilisation d'un VPN ou d'un serveur mandataire est <strong>strictement interdite</strong>.
        </p>

        <div style="background:#FDF2F7; border:1px solid #F1BED7; border-radius:12px; padding:1.1rem; text-align:left; margin-bottom:1.75rem; font-size:0.82rem;">
          <div style="margin-bottom:0.4rem; display:flex; justify-content:space-between;">
            <span style="color:#7D0845; font-weight:700;">Adresse IP Détectée :</span>
            <strong style="color:#E6007E; font-family:monospace;">${ip}</strong>
          </div>
          <div style="margin-bottom:0.4rem; display:flex; justify-content:space-between;">
            <span style="color:#7D0845; font-weight:700;">Fournisseur / Datacenter :</span>
            <strong style="color:#3B0421;">${isp}</strong>
          </div>
          <div style="display:flex; justify-content:space-between;">
            <span style="color:#7D0845; font-weight:700;">Localisation IP :</span>
            <strong style="color:#3B0421;">${location}</strong>
          </div>
        </div>

        <div style="background:#FEF3C7; color:#D97706; padding:0.75rem 1rem; border-radius:10px; font-size:0.8rem; font-weight:700; margin-bottom:1.5rem; text-align:left; border:1px solid #FDE68A;">
          ⚠️ <strong>Consigne :</strong> Veuillez désactiver votre application VPN ou extension de navigateur, puis cliquer sur le bouton ci-dessous pour débloquer la plateforme.
        </div>

        <button id="jbf-retry-security-btn" style="width:100%; background:linear-gradient(135deg, #E6007E 0%, #9E1A59 100%); color:#FFFFFF; border:none; padding:0.9rem; border-radius:12px; font-size:0.95rem; font-weight:800; cursor:pointer; box-shadow:0 6px 20px rgba(230,0,126,0.4); transition:all 0.2s ease;">
          Vérifier à nouveau la connexion
        </button>
      </div>
    `;

    document.getElementById('jbf-retry-security-btn').onclick = () => {
      const btn = document.getElementById('jbf-retry-security-btn');
      btn.textContent = 'Vérification en cours...';
      btn.disabled = true;
      setTimeout(() => {
        checkSecurity();
      }, 1000);
    };
  }

  function removeBlockingOverlay() {
    const overlay = document.getElementById('jbf-vpn-blocking-overlay');
    if (overlay) {
      overlay.remove();
    }
  }

  // Contrôle de sécurité via l'API Backend
  async function checkSecurity() {
    try {
      const res = await fetch(API_ENDPOINT, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'X-Device-Fingerprint': navigator.userAgent
        }
      });

      const data = await res.json();

      if (res.status === 403 || data.is_vpn === true) {
        isVpnActive = true;
        clientSecurityInfo = data.details || data;
        createBlockingOverlay(clientSecurityInfo);
        console.warn('🔒 [JBF SECURITY] Accès bloqué : VPN / Proxy actif.');
      } else {
        isVpnActive = false;
        clientSecurityInfo = data;
        removeBlockingOverlay();
        console.log('✅ [JBF SECURITY] Connexion directe validée.');
      }
    } catch (err) {
      // En cas d'indisponibilité du serveur, ne bloque pas le dev local
      console.warn('⚠️ [JBF SECURITY] Serveur de contrôle non joignable:', err.message);
      removeBlockingOverlay();
    }
  }

  // Initialisation immédiate au chargement du DOM
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', checkSecurity);
  } else {
    checkSecurity();
  }

  // Polling de vérification en arrière-plan toutes les 15 secondes
  setInterval(checkSecurity, 15000);

  // Exposition globale pour les modules de pointage
  window.JBF_SECURITY = {
    isVpnActive: () => isVpnActive,
    getInfo: () => clientSecurityInfo,
    recheck: checkSecurity
  };
})();
