# ⚙️ SPEC 03 : SPÉCIFICATION API BACKEND (NODE.JS / EXPRESS)
**Serveur**: `backend/server.js`  
**Port**: `3001` (Développement) | Configurable via `PORT`

---

## 1. ENDPOINTS D'API ET SÉCURITÉ

### A. GET `/api/config`
- **Description** : Transmet au front-end l'URL Supabase et la clé publique (`Anon Key`).
- **Sécurité** : Ne révèle JAMAIS la `Service Role Key`.
- **Réponse HTTP 200** :
  ```json
  {
    "supabaseUrl": "https://dvzwqxcaiagczyonrhsg.supabase.co",
    "supabaseAnonKey": "eyJhbGciOiJIUzI..."
  }
  ```

### B. GET `/api/avis`
- **Description** : Récupère la liste des avis clients validés (`approuve = true`).
- **Filtres** : Tri par date décroissante, limite 50 résultats.
- **Réponse HTTP 200** :
  ```json
  {
    "avis": [
      {
        "id": "uuid",
        "nom": "Michel Kabamba",
        "entreprise": "Kolwezi Mining",
        "service": "Mines",
        "note": 5,
        "commentaire": "...",
        "created_at": "2026-08-12T17:00:00Z"
      }
    ]
  }
  ```

### C. POST `/api/avis`
- **Description** : Enregistre un nouvel avis soumis par un client.
- **Corps de requête (JSON)** :
  ```json
  {
    "nom": "Jean Mukendi",
    "entreprise": "Sometal RDC",
    "service": "Catering",
    "note": 5,
    "commentaire": "Prestation d'excellente qualité."
  }
  ```
- **Statut HTTP 201** : Avis créé avec succès en base de données.

### D. POST `/api/devis`
- **Description** : Enregistre une demande de devis pour les 15 prestations.
- **Corps de requête (JSON)** :
  ```json
  {
    "nom": "Patrick Ntambwe",
    "societe": "Batimex RDC",
    "telephone": "+243 81 000 0000",
    "email": "p.ntambwe@batimex.cd",
    "services": ["BTP", "Maintenance"],
    "localite": "Likasi",
    "message": "Demande de devis pour réhabilitation."
  }
  ```
- **Statut HTTP 201** : Demande transmise avec succès.

---

## 2. PROTECTION DES SÉCRETS
- Fichier `.env` strictement exclu du suivi Git via `.gitignore`.
- Limitation du nombre de requêtes (`express-rate-limit`) : 100 requêtes max par tranche de 15 minutes par IP.

---

## 3. SERVICE EMAIL MULTI-PROVIDER & CONTRÔLE IP (CLIENTS)

### A. Spécifications du Dispatcher d'Emails
- **Prestataires autorisés** :
  1. **Brevo API** (clé `BREVO_API_KEY` dans `backend/.env`)
  2. **Resend API** (clé `RESEND_API_KEY` dans `backend/.env`)
- **Pondération** : 80% des envois via Brevo, 20% via Resend avec basculement automatique (failover).
- **Plafond strict** : 380 emails / 24 heures glissantes.
- **Périmètre d'application** : Strictement réservé aux clients (`JBF Client`). Les collaborateurs internes (`JBF Membre`) et l'administration (`JBF Admin`) ne reçoivent aucun email OTP.

### B. Format Épuré des Emails OTP (Directive Client)
- Les emails OTP affichent uniquement le code de validation à 6 chiffres.
- Aucune adresse IP, aucun métadonnée superflue dans le corps du message client afin d'assurer une lisibilité maximale et une confidentialité stricte.
