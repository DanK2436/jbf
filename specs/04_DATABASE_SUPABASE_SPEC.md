# 🗄️ SPEC 04 : SPÉCIFICATION BASE DE DONNÉES (SUPABASE / POSTGRESQL)
**Projet Supabase**: `https://dvzwqxcaiagczyonrhsg.supabase.co`  
**Fichier Schéma**: `supabase/schema.sql`

---

## 1. TABLES & SCHÉMA DE BASE DE DONNÉES

### Table `avis_clients`
| Colonne | Type | Modificateurs | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Identifiant unique |
| `nom` | `VARCHAR(120)` | `NOT NULL` | Nom complet de l'auteur |
| `entreprise` | `VARCHAR(150)` | - | Société / Organisation |
| `service` | `VARCHAR(100)` | `NOT NULL` | Prestation concernée (Mines, Catering...) |
| `note` | `INT` | `CHECK (note >= 1 AND note <= 5)` | Évaluation attribuée |
| `commentaire` | `TEXT` | `NOT NULL` | Texte détaillé de l'avis |
| `approuve` | `BOOLEAN` | `DEFAULT true` | Validation de l'avis |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT now()` | Date de publication |

### Table `demandes_devis`
| Colonne | Type | Modificateurs | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Identifiant unique |
| `nom` | `VARCHAR(120)` | `NOT NULL` | Nom du demandeur |
| `societe` | `VARCHAR(150)` | - | Entreprise cliente |
| `telephone` | `VARCHAR(40)` | `NOT NULL` | Numéro de téléphone |
| `email` | `VARCHAR(150)` | - | Email de contact |
| `services` | `TEXT[]` | - | Tableau des services sélectionnés |
| `localite` | `VARCHAR(100)` | - | Ville/Zone d'intervention en RDC |
| `message` | `TEXT` | - | Détail du besoin |
| `statut` | `VARCHAR(30)` | `DEFAULT 'nouveau'` | Statut (nouveau, en_cours, traite) |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT now()` | Horodatage |

### Table `admin_accounts` (Comptes Administrateurs & Sous-Admins)
| Colonne | Type | Modificateurs | Description |
|---|---|---|---|
| `id` | `VARCHAR(50)` | `PRIMARY KEY` | Identifiant administrateur |
| `full_name` | `VARCHAR(150)` | `NOT NULL` | Nom complet / Titre |
| `email` | `VARCHAR(150)` | `UNIQUE NOT NULL` | Email officiel (`services@admin.jbf`) |
| `role` | `VARCHAR(50)` | `DEFAULT 'sous_admin'` | `super_admin` ou `sous_admin` |
| `permissions` | `TEXT[]` | `DEFAULT '{}'` | Modules autorisés (`['*']` pour super admin) |
| `is_active` | `BOOLEAN` | `DEFAULT true` | Autorisation d'accès |

### Table `tickets_support` (Assistance Client & Audit Sécurité)
| Colonne | Type | Modificateurs | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Identifiant ticket |
| `client_nom` | `VARCHAR(150)` | `NOT NULL` | Société ou contact |
| `client_telephone` | `VARCHAR(50)` | - | Numéro de téléphone |
| `client_email` | `VARCHAR(150)` | - | Email du demandeur |
| `sujet` | `VARCHAR(200)` | `NOT NULL` | Objet du ticket |
| `message` | `TEXT` | `NOT NULL` | Message détaillé |
| `ip_source` | `VARCHAR(60)` | - | Adresse IP de la requête de support |
| `priorite` | `VARCHAR(20)` | `DEFAULT 'normal'` | `urgent`, `normal`, `faible` |
| `statut` | `VARCHAR(30)` | `DEFAULT 'ouvert'` | `ouvert`, `en_cours`, `resolu` |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT now()` | Date de création |

### Table `devis_equipes` (Équipes et Devis Chiffrés)
| Colonne | Type | Modificateurs | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Identifiant chiffrage |
| `devis_ref` | `VARCHAR(50)` | `NOT NULL` | Référence devis associée |
| `client_nom` | `VARCHAR(150)` | `NOT NULL` | Entreprise cliente |
| `prestation` | `VARCHAR(150)` | `NOT NULL` | Pôle métier |
| `effectif_attribue`| `INT` | `DEFAULT 0` | Nombre d'agents mobilisés |
| `chef_equipe` | `VARCHAR(150)` | - | Superviseur désigné |
| `montant_usd` | `NUMERIC(12,2)` | - | Montant total chiffré en USD |
| `statut` | `VARCHAR(30)` | `DEFAULT 'etude'` | `etude`, `valide`, `deployee` |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT now()` | Date |

---

## 2. POLITIQUES DE SÉCURITÉ ROW LEVEL SECURITY (RLS)
```sql
ALTER TABLE config_cles_api ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Securite Cles API" ON config_cles_api
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
```
- **Principe** : Accès strictement interdit pour les requêtes publiques ou anonymes (`anon`). Seul le serveur API Node.js utilisant le privilège `service_role` peut interroger cette table.
- **Audit IP** : L'adresse IP publique de chaque demande de support ou d'authentification client est enregistrée pour traçabilité et prévention anti-fraude.
