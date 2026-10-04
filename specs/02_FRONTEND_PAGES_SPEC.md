# 🌐 SPEC 02 : SPÉCIFICATION FRONTEND WEB (PUBLIC, MEMBRE & ADMIN)
**Écosystème Web JBF SERVICES**:
- **Site Web Public** : `C:\Users\is mlckl\Desktop\Sites_web\JBF Web\JBF Public\` (11 Pages)
- **Portail Intranet Membre** : `C:\Users\is mlckl\Desktop\Sites_web\JBF Web\JBF Membre\` (7 Pages)
- **Portail Web Admin (Test)** : `C:\Users\is mlckl\Desktop\Sites_web\JBF Web\JBF Admin\` (8 Pages)
- **Charte Graphique** : 90% Rose Vif (`#E6007E`), 10% Blanc (`#FFFFFF`)

---

## 1. STRUCTURE DES PAGES PUBLIC (`JBF Public/`)

| Fichier Page | Description Fonctionnelle | Raccordement Backend / API |
|---|---|---|
| [`index.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Public/index.html) | Accueil avec proposition de valeur, aperçu des 15 prestations et réassurance | Static / Dynamic CTA |
| [`services.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Public/services.html) | Catalogue filtrable des 15 prestations intégrées | JS Filter System |
| [`gallery.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Public/gallery.html) | Galerie de réalisations terrain par catégorie (Mines, Catering, BTP, etc.) | Supabase Storage / Media |
| [`blog.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Public/blog.html) | Actualités et retours de missions JBF en RDC | Static / CMS |
| [`avis.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Public/avis.html) | Avis clients certifiés, filtres par service et modale de soumission | `GET/POST /api/avis` |
| [`faq.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Public/faq.html) | Foire aux questions réparties par thématiques | Accordion JS |
| [`about.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Public/about.html) | Histoire, mission et couverture géographique à travers la RDC | Static |
| [`contact.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Public/contact.html) | Formulaire de demande de devis gratuit garanti sous 24h ouvrables | `POST /api/devis` |
| [`login.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Public/login.html) | Formulaire de connexion sécurisé à l'Espace Client | Supabase Auth API |
| [`register.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Public/register.html) | Création de compte client avec validation d'email | Supabase Auth API |
| [`dashboard.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Public/dashboard.html) | Tableau de bord client pour le suivi des contrats et devis | Supabase Auth + DB |

---

## 2. STRUCTURE DE L'INTRANET MEMBRE (`JBF Membre/`)

| Fichier Page | Description Fonctionnelle | Raccordement Backend |
|---|---|---|
| [`dashboard.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Membre/dashboard.html) | Tableau de bord exécutif collaborateur (KPIs réels, horloge digitale, terminal pointage GPS, missions du jour) | `/api/pointage`, `/api/missions` |
| [`missions.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Membre/missions.html) | Ordres de mission détaillés avec cahier des charges, filtres par statut, effectifs et dépôt de rapports | `/api/missions` |
| [`timesheet.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Membre/timesheet.html) | Relevé mensuel des pointages, calcul automatique des heures supplémentaires et export PDF | `/api/pointage` |
| [`leaves.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Membre/leaves.html) | Compteur de solde congés et formulaire officiel de demande d'absence | `POST /api/conges` |
| [`chat.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Membre/chat.html) | Canal de messagerie d'équipe avec filtrage par canal (#hse-securite, #general, #missions) | Supabase Realtime |
| [`resources.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Membre/resources.html) | Bibliothèque documentaire de conformité HSE, protocoles miniers et manuels HACCP avec recherche instantanée | Supabase Storage |
| [`auth/login.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Membre/auth/login.html) | Portail de connexion sécurisé pour collaborateurs et chefs de chantiers | Supabase Auth |

---

## 3. STRUCTURE DU PORTAIL ADMIN WEB (TEST) (`JBF Admin/`)

| Fichier Page | Description Fonctionnelle | Raccordement Backend |
|---|---|---|
| [`dashboard.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Admin/dashboard.html) | Vue de pilotage exécutif, KPIs temps réel (devis, missions, pointages), alertes anti-VPN | `GET /api/stats`, `GET /api/admin/*` |
| [`devis.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Admin/devis.html) | Gestion des demandes de devis, modification des statuts en direct, estimation de coût | `GET/PUT /api/devis` |
| [`missions.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Admin/missions.html) | Planification, création de missions, affectation des agents et suivi du statut | `GET/POST/PUT /api/missions` |
| [`pointages.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Admin/pointages.html) | Relevé des pointages GPS, traçabilité IP, alertes anti-VPN et export feuilles de temps | `GET /api/pointage` |
| [`conges.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Admin/conges.html) | Tableau de validation des congés (Approbation / Refus en 1 clic) | `GET/PUT /api/admin/conges` |
| [`avis.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Admin/avis.html) | Modération des avis clients (Approuver, masquer, supprimer) | `GET/PUT/DELETE /api/admin/avis` |
| [`membres.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Admin/membres.html) | Annuaire des agents et collaborateurs de terrain, gestion des rôles | `GET /api/admin/agents` |
| [`auth/login.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Admin/auth/login.html) | Authentification par mot de passe maître (`services@admin.jbf`), strictement zéro OTP | Supabase Auth / Direct Password |

---

## 4. STRUCTURE DE L'ESPACE CLIENT B2B (`JBF Client/`)

| Fichier Page | Description Fonctionnelle | Raccordement Backend & Sécurité |
|---|---|---|
| [`dashboard.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Client/dashboard.html) | Tableau de bord exécutif client (Pôles contractés, KPIs chantiers réels, devis récents dynamiques sans simulation) | Supabase `demandes_devis`, `missions` |
| [`devis.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Client/devis.html) | Consultation et soumission de devis pour les 15 pôles métiers (Enregistrement persistant local/Supabase) | Supabase `demandes_devis` |
| [`missions.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Client/missions.html) | Suivi en direct de l'avancement des chantiers et contact direct avec les chefs d'équipe JBF | Supabase `missions` |
| [`factures.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Client/factures.html) | Registre des factures, attestations de service fait et reçus certifiés | Supabase `orders` / `factures` |
| [`service-client.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Client/service-client.html) | Support direct, création de tickets d'assistance et contact WhatsApp opérationnel (sans bot simulé) | Supabase `tickets_support`, WhatsApp |
| [`avis.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Client/avis.html) | Dépôt et consultation des évaluations de satisfaction qualité | Supabase `avis_clients` |
| [`profil.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Client/profil.html) | Fiche signalétique de l'entreprise cliente, contacts et préférences | Supabase `profiles` |
| [`auth/login.html`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/JBF%20Client/auth/login.html) | Connexion Mot de passe ou Code OTP Email (Brevo 80% / Resend 20%) avec traçabilité de l'adresse IP cliente | `mail-service.js` + Supabase Auth |

---

## 5. RÈGLES D'INTÉGRATION DU LOGO CLIENT & AUDIT IP

1. **Dimensionnement Strict du Logo (`.client-brand-logo`)** :
   - Classe CSS obligatoire : `.client-brand-logo`.
   - Dimensions : `max-height: 38px !important; max-width: 48px !important; width: auto !important; object-fit: contain !important;`.
   - Attributs inline de sécurité imposés sur toutes les pages pour prévenir tout débordement en plein écran en cas de cache CSS.

2. **Traçabilité de l'Adresse IP Source** :
   - L'authentification client (OTP et mot de passe oublié) déclenche automatiquement une capture de l'adresse IP publique de la machine émettrice.
   - Cette adresse IP est injectée dans l'en-tête et le corps du courriel de sécurité afin de prémunir le client contre tout vol de session ou requête malveillante distante.
   - Les données de simulation (faux tickets, faux devis, faux messages instantanés de robots) sont proscrites au profit des flux temps réel.
