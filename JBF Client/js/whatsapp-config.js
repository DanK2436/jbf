// =============================================================
// JBF SERVICES — CONFIGURATION DE L'API WHATSAPP
// Prêt à recevoir vos identifiants d'API WhatsApp dès que vous les fournissez
// =============================================================

const WHATSAPP_API_CONFIG = {
  // Activez ou désactivez l'API réelle
  ENABLED: false, // true seulement avec une URL https et une clé réelle, hors dépôt

  // La démonstration n'authentifie jamais. Les deux drapeaux doivent être true
  // et la page servie en local pour afficher un message, sans créer de session.
  DEMO_MODE: false,
  ISOLATED_DEMO: false,

  // Fournisseur / Mode : 'meta' (Cloud API officiel), 'twilio', 'wati', ou 'custom'
  PROVIDER: 'custom',

  // URL de l'API fournie par votre prestataire WhatsApp
  API_URL: 'https://api.whatsapp.example/v1/messages',

  // Jeton d'autorisation Bearer ou Clé secrète de votre API
  API_KEY: 'VOTRE_CLE_API_WHATSAPP_ICI',

  // Identifiant du numéro WhatsApp Business (ex: Phone Number ID Meta)
  PHONE_NUMBER_ID: 'VOTRE_PHONE_NUMBER_ID_ICI',

  // Template / Modèle de message WhatsApp approuvé pour les codes OTP
  OTP_TEMPLATE_NAME: 'jbf_auth_otp',

  // Paramètres généraux
  DEFAULT_COUNTRY_CODE: '+243', // République Démocratique du Congo par défaut
  OTP_LENGTH: 6,
  OTP_EXPIRY_SECONDS: 300, // 5 minutes

  // Aucun code de démonstration n'est accepté comme authentification.

  // Numéro de support WhatsApp direct JBF SERVICES (RDC)
  OFFICIAL_WHATSAPP_SUPPORT: '+243810000000'
};
