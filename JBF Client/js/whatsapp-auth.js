// =============================================================
// JBF SERVICES — MODULE D'AUTHENTIFICATION WHATSAPP
// Envoi, validation OTP et connexion instantanée
// =============================================================

class WhatsAppAuthService {
  constructor() {
    this.config = WHATSAPP_API_CONFIG;
    this.sessionKey = 'jbf_whatsapp_pending_auth';
  }

  // Normaliser le numéro au format international E.164
  normalizePhone(phone) {
    if (!phone) return '';
    let cleaned = phone.replace(/[^\d+]/g, '');
    if (cleaned.startsWith('0')) {
      cleaned = this.config.DEFAULT_COUNTRY_CODE + cleaned.substring(1);
    } else if (!cleaned.startsWith('+')) {
      cleaned = this.config.DEFAULT_COUNTRY_CODE + cleaned;
    }
    return cleaned;
  }

  // Générer un code OTP sécurisé
  generateOTP() {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  providerReady() {
    const cfg = this.config || {};
    if (cfg.ENABLED !== true) return false;
    const url = String(cfg.API_URL || '');
    const key = String(cfg.API_KEY || '');
    if (!url.startsWith('https://') || /example/i.test(url)) return false;
    if (!key || /VOTRE_|CHANGE_ME|ICI|placeholder/i.test(key)) return false;
    return true;
  }

  isolatedDemoRequested() {
    const cfg = this.config || {};
    const host = (window.location && window.location.hostname) || '';
    const local = host === 'localhost' || host === '127.0.0.1';
    return cfg.DEMO_MODE === true && cfg.ISOLATED_DEMO === true && local;
  }

  // Envoyer le code OTP par WhatsApp
  async sendOTP(phone) {
    const formattedPhone = this.normalizePhone(phone);
    if (!formattedPhone || formattedPhone.length < 9) {
      return { success: false, message: 'Numéro de téléphone invalide.' };
    }

    if (!this.providerReady()) {
      if (this.isolatedDemoRequested()) {
        return {
          success: false,
          demonstration: true,
          authenticated: false,
          phone: formattedPhone,
          message: 'Démonstration isolée : aucun code n\'est émis et cette voie n\'ouvre pas de session.'
        };
      }
      return {
        success: false,
        authenticated: false,
        message: 'WhatsApp n\'est pas configuré. Aucun code de démonstration n\'est accepté.'
      };
    }

    const otpCode = this.generateOTP();
    const expiresAt = Date.now() + this.config.OTP_EXPIRY_SECONDS * 1000;

    // Sauvegarder l'état temporaire
    const pendingData = {
      phone: formattedPhone,
      otp: otpCode,
      expiresAt: expiresAt,
      attempts: 0
    };
    sessionStorage.setItem(this.sessionKey, JSON.stringify(pendingData));

    // Si l'API réelle est activée, effectuer l'appel HTTP vers le prestataire WhatsApp
    if (this.config.ENABLED) {
      try {
        const response = await fetch(this.config.API_URL, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.config.API_KEY}`
          },
          body: JSON.stringify({
            messaging_product: 'whatsapp',
            to: formattedPhone.replace('+', ''),
            type: 'template',
            template: {
              name: this.config.OTP_TEMPLATE_NAME,
              language: { code: 'fr' },
              components: [
                {
                  type: 'body',
                  parameters: [{ type: 'text', text: otpCode }]
                },
                {
                  type: 'button',
                  sub_type: 'url',
                  index: '0',
                  parameters: [{ type: 'text', text: otpCode }]
                }
              ]
            }
          })
        });

        const data = await response.json();
        if (response.ok) {
          return { success: true, phone: formattedPhone, authenticated: false, message: 'Code OTP envoyé par WhatsApp avec succès.' };
        }
        sessionStorage.removeItem(this.sessionKey);
        console.warn('[WhatsApp API] Erreur renvoyée:', data && data.message);
        return { success: false, message: data.message || "Échec de l'envoi WhatsApp." };
      } catch (err) {
        sessionStorage.removeItem(this.sessionKey);
        console.warn('[WhatsApp API] Exception réseau:', err.message || err);
        return { success: false, message: 'Erreur de communication avec le serveur WhatsApp.' };
      }
    }
    return { success: false, message: 'Fournisseur WhatsApp indisponible.' };
  }

  // Vérifier le code OTP saisi
  verifyOTP(enteredCode) {
    const raw = sessionStorage.getItem(this.sessionKey);
    if (!raw) {
      return { success: false, message: 'Aucune demande de code en cours. Veuillez recommencer.' };
    }

    const data = JSON.parse(raw);
    if (Date.now() > data.expiresAt) {
      sessionStorage.removeItem(this.sessionKey);
      return { success: false, message: 'Ce code a expiré. Veuillez en redemander un.' };
    }

    data.attempts++;
    if (data.attempts > 5) {
      sessionStorage.removeItem(this.sessionKey);
      return { success: false, message: 'Trop de tentatives incorrectes. Veuillez recommencer.' };
    }

    if (!this.providerReady() || data.demonstration) {
      return { success: false, authenticated: false, message: 'Un code de démonstration n\'authentifie pas.' };
    }

    if (enteredCode.trim() === data.otp.trim()) {
      sessionStorage.removeItem(this.sessionKey);

      // Créer la session client connectée
      const clientSession = {
        id: 'cli-' + Date.now().toString().slice(-4),
        companyName: 'Société Partenaire JBF',
        contactName: 'Responsable Opérations',
        phone: data.phone,
        whatsapp: data.phone,
        authProvider: 'whatsapp',
        city: 'Kinshasa / Katanga',
        avatar: 'WA',
        token: 'jbf-client-token-' + Math.random().toString(36).substring(2)
      };

      clientSession.name = clientSession.contactName;
      clientSession.role = 'client';
      const sessionJson = JSON.stringify(clientSession);
      localStorage.setItem('JBF_CLIENT_SESSION', sessionJson);
      localStorage.setItem('jbf_client_session', sessionJson);
      return { success: true, session: clientSession };
    } else {
      sessionStorage.setItem(this.sessionKey, JSON.stringify(data));
      return { success: false, message: 'Code OTP incorrect. Veuillez réessayer.' };
    }
  }

  // Obtenir le numéro en attente
  getPendingPhone() {
    const raw = sessionStorage.getItem(this.sessionKey);
    return raw ? JSON.parse(raw).phone : null;
  }
}

window.whatsappAuth = new WhatsAppAuthService();
