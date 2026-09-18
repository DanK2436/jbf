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

  // Envoyer le code OTP par WhatsApp
  async sendOTP(phone) {
    const formattedPhone = this.normalizePhone(phone);
    if (!formattedPhone || formattedPhone.length < 9) {
      return { success: false, message: 'Numéro de téléphone invalide.' };
    }

    const otpCode = this.config.ENABLED ? this.generateOTP() : this.config.DEMO_OTP_CODE;
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
          return { success: true, phone: formattedPhone, message: 'Code OTP envoyé par WhatsApp avec succès.' };
        } else {
          console.warn('[WhatsApp API] Erreur renvoyée:', data);
          return { success: false, message: data.message || "Échec de l'envoi WhatsApp." };
        }
      } catch (err) {
        console.warn('[WhatsApp API] Exception réseau:', err);
        return { success: false, message: 'Erreur de communication avec le serveur WhatsApp.' };
      }
    } else {
      // Mode simulation élégant pour démo et tests immédiats
      console.log(`%c[JBF WhatsApp Auth] Code OTP généré pour ${formattedPhone} : ${otpCode}`, 'color: #E6007E; font-weight: bold; font-size: 14px;');
      return {
        success: true,
        phone: formattedPhone,
        demoCode: otpCode,
        message: `Code envoyé par WhatsApp ! (En mode test immédiat, votre code est : ${otpCode})`
      };
    }
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
