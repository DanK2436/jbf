# 🏛️ SPEC 00 : SPÉCIFICATION D'ARCHITECTURE SYSTÈME GLOBAL
**Écosystème**: JBF SERVICES (Web, Desktop Flutter, Mobile Flutter, Node.js Backend, Supabase BaaS)

---

## 1. SCHÉMA GLOBAL DE L'ÉCOSYSTÈME MULTIPLATEFORME

```
+---------------------------------------------------------------------------------------------------+
|                                        APPLICATIONS CLIENTS                                       |
|                                                                                                   |
|  [ WEB PUBLIC, MEMBRE & ADMIN ]  [ LOGICIELS DESKTOP (FLUTTER) ]    [ APPS MOBILES (FLUTTER) ]    |
|  - JBF Public (Vitrine 15 Serv)  - JBF Admin Desktop (Win/Mac/Lin)  - JBF Public App (iOS/Android)|
|  - JBF Membre (Intranet Pro)     - JBF Membre Desktop              - JBF Membre Agent App        |
|  - JBF Admin (Portail Test Web)                                     - JBF Admin Mobile App        |
+---------------------------------------------------------------------------------------------------+
                                         |
                                         | REST API (HTTPS) & Supabase Realtime WSS
                                         v
+---------------------------------------------------------------------------------------------------+
|                                     BACKEND CENTRAL UNIFIÉ                                        |
|                                                                                                   |
|  1. NODE.JS / EXPRESS API SERVER (backend/server.js)                                              |
|     - Authentification & Middleware de sécurité                                                   |
|     - Endpoints: /api/config, /api/avis, /api/devis, /api/missions, /api/pointage, /api/admin/*    |
|     - Variables d'environnement masquées (.env)                                                   |
|                                                                                                   |
|  2. BASE DE DONNÉES SUPABASE (PostgreSQL + Auth + Storage + Realtime)                             |
|     - Tables: avis_clients, demandes_devis, membres, missions, feuilles_temps, demandes_conges    |
|     - Table Sécurisée RLS: config_cles_api (Clés API protégées)                                   |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. DÉTAIL DES COMPOSANTS PAR PLATEFORME

### A. Plateforme Web (`Sites_web/JBF Web/`)
1. **`JBF Public/`** : Site web vitrine public, catalogue des 15 prestations, devis, avis clients, galerie, actualités, FAQ, contact.
2. **`JBF Client/`** : Espace client et partenaires B2B (`dashboard.html`, `devis.html`, `missions.html`, `factures.html`, `service-client.html`, `avis.html`, `profil.html`). Authentification par mot de passe ou code OTP par email avec traçabilité IP obligatoire.
3. **`JBF Membre/`** : Portail intranet web des collaborateurs (`dashboard.html`, `missions.html`, `timesheet.html`, `leaves.html`, `chat.html`, `resources.html`). Authentification Supabase interne / PIN (zéro envoi d'email OTP).
4. **`JBF Admin/`** : Portail web d'administration générale (`dashboard.html`, `devis.html`, `missions.html`, `conges.html`, `avis.html`, `membres.html`, `ressources.html`, `service-client.html`, `sous-admins.html`). Authentification stricte par mot de passe maître (`services@admin.jbf`), zéro OTP.

### B. Logiciels Desktop (`Logiciels/JBF Desktop/` — Flutter)
1. **`JBF Admin Desktop`** : Application lourde de direction générale pour le pilotage des 15 prestations, validation des contrats, facturation, supervision HSE.
2. **`JBF Membre Desktop`** : Application de bureau pour le personnel administratif et technique (pointage des heures, rapports de missions, messagerie interne).

### C. Applications Mobiles (`App_Mobiles/JBF App/` — Flutter)
1. **`JBF Public Mobile App`** : Application client pour la réservation instantanée de prestations, le suivi en direct des demandes de devis et notifications Push.
2. **`JBF Membre Mobile App`** : Application pour les agents et équipes déployées sur le terrain (chantiers miniers, bases de vie, transport) avec géolocalisation, pointage QR code et mode hors-ligne.
3. **`JBF Admin Mobile App`** : Application de supervision sur smartphone pour la direction et les chefs de chantiers.

---

## 3. INFRASTRUCTURE D'ENVOI D'EMAILS & SÉCURITÉ IP

```
                          [ REQUÊTE CLIENT (OTP / RESET) ]
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
     [ DÉTECTION ADRESSE IP ]                         [ CONTRÔLE DE QUOTA ]
  • API ipify / icanhazip                          • Max 380 emails / jour
  • Horodatage Lubumbashi/RDC                      • Quota journalier partagé
  • User-Agent / Empreinte                         • Stockage persistant
                 │                                               │
                 └───────────────────────┬───────────────────────┘
                                         ▼
                     [ SÉLECTEUR DYNAMIQUE PONDÉRÉ ]
                         Ratio: 80% Brevo / 20% Resend
                                         │
                   ┌─────────────────────┴─────────────────────┐
                   ▼ (80%)                                     ▼ (20%)
           [ API BREVO ]                               [ API RESEND ]
      (Clé: xkeysib-a54b...)                      (Clé: re_LJuEYq...)
                   │                                           │
                   └─────────────────────┬─────────────────────┘
                                         │  (Basculement automatique en cas d'échec)
                                         ▼
                    [ EMAIL HTML SÉCURISÉ LIVRÉ ]
                   • Code OTP à 6 chiffres
                   • Cartouche audit : IP source + Date + Appareil
                   • Alerte anti-fraude en cas d'IP inconnue
```

### Règles Impératives du Service Mail :
1. **Périmètre Strict** : Réservé exclusivement aux clients (espace `JBF Client`). Les collaborateurs (`JBF Membre`) et l'administrateur (`JBF Admin`) ne sont **PAS** concernés par l'envoi d'emails OTP.
2. **Pondération 80 / 20** : 80% du volume est routé via Brevo, 20% via Resend avec basculement transparent (failover) si l'un des prestataires est indisponible.
3. **Plafond Quotidien** : Limite stricte de 380 emails par jour calendaire.
4. **Traçabilité IP dans les Emails** : Chaque email généré par la plateforme intègre explicitement l'adresse IP publique de la machine émettrice, la date/heure locale (Lubumbashi) et l'environnement navigateur pour une traçabilité auditée et la détection immédiate de requêtes frauduleuses.

---

## 4. ADRESSES ET EMPLACEMENTS DES PROJETS DANS LE SYSTÈME
- **Site Web Public, Client & Backend** : `C:\Users\is mlckl\Desktop\Sites_web\JBF Web\`
- **Espace Membre Web** : `C:\Users\is mlckl\Desktop\Sites_web\JBF Web\JBF Membre\`
- **Espace Admin Web (Supervision)** : `C:\Users\is mlckl\Desktop\Sites_web\JBF Web\JBF Admin\`
- **Service Mail & Supabase** : `C:\Users\is mlckl\Desktop\Sites_web\JBF Web\supabase\`
- **Logiciels Desktop** : `C:\Users\is mlckl\Desktop\Logiciels\JBF Desktop\`
- **Applications Mobiles** : `A:\App_Mobiles\JBF App\`
