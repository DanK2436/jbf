# 🛡️ SPEC 07 : SERVICE D'EMAILS MULTI-FOURNISSEUR, AUDIT IP & SÉCURITÉ CLIENT
**Plateforme**: JBF SERVICES SARL (Portail Web, Intranet & Applications)  
**Date d'entrée en vigueur**: Septembre 2026  
**Statut**: Actif & Déployé  

---

## 1. VUE D'ENSEMBLE & OBJECTIFS SÉCURITAIRES

Le système d'authentification et de notification par email de la plateforme **JBF SERVICES** intègre un protocole de sécurité renforcé à double niveau :
1. **Haute Disponibilité & Répartition de Charge** : Dispatcher d'emails hybride multi-fournisseurs (Brevo & Resend) avec basculement automatique en cas de défaillance.
2. **Contrôle Strict des Quotas** : Plafond journalier infranchissable de **380 emails par jour**.
3. **Traçabilité des Connexions & Audit d'Adresse IP** : Capture systématique de l'adresse IP publique de la machine émettrice lors de toute demande de code OTP ou de réinitialisation de mot de passe, avec injection automatique de ces informations dans le courriel à destination du client.
4. **Cloisonnement Strict des Rôles** : L'envoi de codes OTP par email est exclusivement dédié aux clients (`JBF Client`). Les collaborateurs internes (`JBF Membre`) et les administrateurs généraux (`JBF Admin`) en sont strictement exemptés.

---

## 2. ARCHITECTURE DU DISPATCHER MULTI-FOURNISSEURS

### A. Clés API et Prestataires Intégrés
- **Prestataire Principal (80%) : Brevo (ex-Sendinblue)**
  - Clé API : `BREVO_API_KEY` (stockée de manière sécurisée dans `backend/.env`)
  - Endpoint : `https://api.brevo.com/v3/smtp/email`
  - Expéditeur : `JBF SERVICES Client <contact@jbf-services.cd>`
- **Prestataire Secondaire (20%) : Resend**
  - Clé API : `RESEND_API_KEY` (stockée de manière sécurisée dans `backend/.env`)
  - Endpoint : `https://api.resend.com/emails`
  - Expéditeur : `JBF SERVICES <onboarding@resend.dev>`

### B. Algorithme de Répartition Pondérée 80% / 20%
1. Pour chaque requête d'envoi, le service consulte les statistiques journalières :
   - Total quotidien maximum : **380 emails**.
   - Plafond Brevo : 304 emails (80%).
   - Plafond Resend : 76 emails (20%).
2. Si le total atteint 380, toute nouvelle tentative est bloquée jusqu'au lendemain 00:00 (Fuseau RDC).
3. En situation normale sous les quotas, le routage s'effectue aléatoirement avec une probabilité de **0.80 pour Brevo** et **0.20 pour Resend**.
4. **Basculement Automatique (Failover)** : Si l'API primaire renvoie une erreur (réseau, indisponibilité), le dispatcher bascule instantanément sur l'autre prestataire sans impacter l'utilisateur.

---

## 3. PROTOCOLE D'AUDIT ET TRAÇABILITÉ DE L'ADRESSE IP

### A. Détection en Temps Réel
Avant chaque émission d'email, la fonction `detectClientSecurityContext()` résout en arrière-plan :
- L'**adresse IP publique réelle** du demandeur (via API certifiée avec timeout strict de 2 secondes pour ne jamais bloquer le flux).
- L'**horodatage précis** au fuseau horaire de Lubumbashi / République Démocratique du Congo (`Africa/Lubumbashi`).
- L'**empreinte navigateur et système d'exploitation** (`navigator.userAgent`).

### B. Injection dans le Courriel Client
Chaque email reçu par le client comporte :
1. **Dans l'Objet** : La mention explicite de l'adresse IP source, par exemple :  
   `Votre code de connexion JBF Client : 482910 (IP: 102.164.x.x)`
2. **Dans le Corps du Message** : Un cartouche officiel de traçabilité :
   ```
   ┌───────────────────────────────────────────────────────────┐
   │ TRAÇABILITÉ & SÉCURITÉ DE LA REQUÊTE                      │
   │ Adresse IP source  : 102.164.x.x                          │
   │ Horodatage         : Lundi 14 Septembre 2026 à 22:30 (RDC) │
   │ Environnement      : Mozilla/5.0 (Windows NT 10.0; Win64) │
   │                                                           │
   │ ⚠️ ALERTE : Si vous n'êtes pas à l'origine de cette      │
   │ demande émise depuis l'IP ci-dessus, contactez sans délai │
   │ notre cellule d'intervention : +243 971 306 666.          │
   └───────────────────────────────────────────────────────────┘
   ```

---

## 4. MATRICE D'AUTHENTIFICATION PAR RÔLE

| Rôle Utilisateur | Interface | Mode d'Authentification | Envoi d'Email OTP | Justification Sécuritaire |
|---|---|---|:---:|---|
| **Client Entreprise** | `JBF Client` | Mot de passe OU Code OTP Email | **OUI** (Brevo/Resend) | Flexibilité pour les partenaires miniers et chantiers avec traçabilité IP obligatoire |
| **Collaborateur / Agent** | `JBF Membre` | Identifiant interne / Supabase Auth | **NON** | Sessions professionnelles intranet avec traçabilité GPS sur chantiers |
| **Administrateur Général** | `JBF Admin` | Mot de passe maître direct (`services@admin.jbf`) | **NON** (0 OTP) | Accès direct sécurisé sans dépendance aux flux emails externes |

---

## 5. ASSAINISSEMENT DES INTERFACES & INTÉGRITÉ DU LOGO

1. **Suppression des Données de Simulation** :
   - Nettoyage des tableaux de devis, missions, tickets d'assistance et ressources HSE de toute donnée hardcodée factice.
   - Les données affichées proviennent exclusivement de la base Supabase ou des saisies directes persistées.
   - Suppression du faux robot d'assistance dans le service client au profit des canaux de contact directs (WhatsApp opérationnel & tickets tracés).
2. **Dimensionnement Strict du Logo** :
   - Logo contraint à `max-height: 38px !important; width: auto !important; max-width: 48px !important; object-fit: contain !important;` sur l'ensemble des pages de l'espace client.
   - Présence conjointe de la classe CSS `.client-brand-logo` et d'attributs de style inline pour neutraliser définitivement tout problème de cache navigateur.
