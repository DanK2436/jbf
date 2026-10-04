# 📋 GIT-SPEC : FICHIER DE CONDITIONS ET RÈGLES DE DÉVELOPPEMENT
## Écosystème Global JBF SERVICES (Web, Desktop & Mobile RDC)
**Version**: 8.0 (Ratio 90% Rose Vif / 10% Blanc)  
**Statut**: Actif  
**Périmètres**:
- **Site Web Public** : `C:\Users\is mlckl\Desktop\Sites_web\JBF Web\JBF Public`
- **Espace Membre Web** : `C:\Users\is mlckl\Desktop\Sites_web\JBF Web\JBF Membre`
- **Espace Admin Web (Test)** : `C:\Users\is mlckl\Desktop\Sites_web\JBF Web\JBF Admin`
- **Logiciels Desktop (Flutter)** : `C:\Users\is mlckl\Desktop\Logiciels\JBF Desktop` (`JBF Admin`, `JBF Membre`)
- **Applications Mobiles (Flutter)** : `A:\App_Mobiles\JBF App` (`JBF Public`, `JBF Membre`, `JBF Admin`)
- **Back-End API** : `C:\Users\is mlckl\Desktop\Sites_web\JBF Web\backend`
- **Base de Données** : `C:\Users\is mlckl\Desktop\Sites_web\JBF Web\supabase`

---

## 1. RÈGLES D'ARCHITECTURE PLATEFORME UNIFIÉE

### A. Web (`JBF Public`, `JBF Membre` & `JBF Admin`)
- HTML5, CSS3 modulaires, JavaScript ES6+.
- Les pages HTML publiques sont centralisées dans `JBF Public/pages/` (ou racine `JBF Public/`).
- Les pages du portail membre web sont structurées dans `JBF Membre/`.
- Les pages du portail d'administration de test sont structurées dans `JBF Admin/`.

### B. Logiciels Desktop (`JBF Desktop`)
- Développés en **Flutter (Dart)** pour Windows, macOS et Linux (`JBF Admin`, `JBF Membre`).

### C. Applications Mobiles (`JBF App`)
- Développées en **Flutter (Dart)** pour Android et iOS (`JBF Public`, `JBF Membre`, `JBF Admin`).

---

## 2. CHARTE GRAPHIQUE UNIFIÉE (90% ROSE VIF / 10% BLANC)
- **Palette de marque officielle** :
  - **90% Rose Vif (`#E6007E`) & Nuances (`#FF2E99`, `#D00072`, `#C8006E`, `#FFF0F7`)** : Couleur principale dominante et nuances d'action (Heros, boutons majeurs, accents, barres de navigation, cartes actives, badges). Le magenta est intégralement absorbé dans la palette de Rose Vif.
  - **10% Blanc (`#FFFFFF`) & Fonds clairs (`#F8F9FA`)** : Éléments épurés, fond de cartes et lisibilité parfaite.
- **Interdictions** :
  - Aucun arrière-plan noir/sombre pur.
  - Aucun motif de quadrillage (grid lines) sur aucune plateforme.
  - Le logo officiel (`assets/logo.png`) conserve une apparence naturelle sans filtre destructeur.

---

## 3. RÈGLES STRICTES DE SÉCURITÉ DES CLÉS API
1. Aucune clé d'administration `service_role` ne doit être présente dans le code client Web, Flutter Desktop ou Flutter Mobile.
2. Toutes les clés sensibles sont stockées dans `backend/.env` et dans la table Supabase `config_cles_api` verrouillée par Row Level Security (RLS).

---

## 4. RÈGLES D'ENVOI D'EMAILS & ROUTAGE MULTI-FOURNISSEUR
1. **Prestataires agréés** : Brevo API et Resend API.
2. **Répartition de charge** : Mécanisme automatique garantissant 80% des envois via Brevo et 20% via Resend, avec basculement automatique en cas de panne temporaire d'un prestataire.
3. **Plafond strict** : Quota maximal de **380 emails par jour calendaire**.
4. **Périmètre exclusif** : Ce mécanisme d'emails (OTP et réinitialisation de mot de passe) s'applique **UNIQUEMENT** à l'espace Client (`JBF Client`).
   - L'espace Membre (`JBF Membre`) utilise des sessions intranet et l'authentification Supabase interne sans envoi de mails OTP.
   - L'espace Admin (`JBF Admin`) est strictement verrouillé par mot de passe maître direct (`services@admin.jbf`), **zéro OTP**.

---

## 5. TRAÇABILITÉ OBLIGATOIRE DE L'ADRESSE IP & AUDIT
1. Chaque envoi de code OTP ou de lien de réinitialisation capture l'adresse IP publique de la requête.
2. L'adresse IP détectée, l'horodatage précis (fuseau RDC Lubumbashi) et l'environnement applicatif sont obligatoirement injectés dans l'objet et le corps de chaque email de sécurité.
3. Le destinataire est explicitement averti : si l'adresse IP mentionnée dans l'email ne correspond pas à son terminal, il peut immédiatement déclencher une alerte de sécurité.

---

## 6. INTÉGRITÉ GRAPHIQUE DU LOGO ESPACE CLIENT
1. Le logo officiel (`assets/logo.png`) dans l'espace client ne doit **JAMAIS** s'étendre en plein écran.
2. Il est contraint à une hauteur stricte de `38px` (`max-height: 38px !important; width: auto !important; max-width: 48px !important; object-fit: contain !important;`).
3. La classe `.client-brand-logo` ainsi que les styles inline de sécurité doivent être présents sur toutes les pages de l'espace client.

---

## 7. PROSCRIPTION ABSOLUE DES DONNÉES DE SIMULATION
1. Aucune donnée factice hardcodée (faux devis `DEMO_*`, fausses réponses automatiques de bots, fausses missions ou faux sous-administrateurs) ne doit subsister dans les interfaces.
2. Les tables et vues doivent restituer fidèlement les données réelles (Supabase ou stockage dynamique persistant), et présenter un état vide propre (« Aucun élément ») lorsque la base est vierge.
