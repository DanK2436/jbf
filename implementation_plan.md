# 🛠️ PLAN D'IMPLÉMENTATION GIT-SPEC — ÉCOSYSTÈME GLOBAL JBF SERVICES (RDC)

Spécification globale d'ingénierie et d'architecture pour l'écosystème multiplateforme **JBF SERVICES** (Web Public, Espace Membre Web, Espace Admin Web Test, Logiciels Desktop Flutter, Applications Mobiles Flutter, Backend API Node.js et Supabase BaaS).

---

## 🎨 Charte Graphique Unifiée (90% Rose Vif / 10% Blanc)

- **90% Rose Vif (`#E6007E`) & Nuances (`#FF2E99`, `#D00072`, `#C8006E`, `#FFF0F7`)** : Couleur dominante de marque (Heros, boutons d'action majeurs, accents, badges, barres de navigation, cartes actives). Le magenta est absorbé dans les nuances de Rose Vif.
- **10% Blanc (`#FFFFFF`) & Fonds clairs (`#F8F9FA`)** : Fonds de cartes, conteneurs épurés et respirations visuelles.
- **Zéro Quadrillage** : Aucun motif de grille n'est utilisé.

---

## 🎯 Périmètre de l'Écosystème Global

```
                                  +---------------------------------------+
                                  |      ÉCOSYSTÈME JBF SERVICES (RDC)    |
                                  |         90% Rose Vif / 10% Blanc      |
                                  +---------------------------------------+
                                                      |
        +-------------------------+-------------------+-------------------+-------------------------+
        |                         |                   |                   |                         |
        v                         v                   v                   v                         v
+---------------+       +------------------+  +---------------+   +-------------------+     +-------------------+
|  WEB PUBLIC   |       | ESPACE MEMBRE WEB|  | WEB ADMIN TEST|   |  FLUTTER DESKTOP  |     |  FLUTTER MOBILE   |
|  JBF Public/  |       | JBF Membre/      |  | JBF Admin/    |   |  JBF Desktop/     |     |  JBF App/         |
|  (11 Pages)   |       | (7 Pages Pro)    |  | (8 Pages)     |   | (Admin & Membre)  |     | (Public, Membre)  |
+---------------+       +------------------+  +---------------+   +-------------------+     +-------------------+
        |                         |                   |                   |                         |
        +-------------------------+-------------------+-------------------+-------------------------+
                                                      |
                                                      v
                                      +-------------------------------+
                                      |     BACKEND REST API & DB     |
                                      | - Node.js Enterprise API      |
                                      | - Supabase PostgreSQL + RLS   |
                                      +-------------------------------+
```

---

## 📌 Répertoire des Spécifications Git-Spec (`specs/`)

1. **[`CONDITIONS.md`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/specs/CONDITIONS.md)** : Règles globales (Ratio 90% Rose Vif / 10% Blanc, zéro quadrillage, masquage absolu des clés API).
2. **[`00_SYSTEM_ARCHITECTURE.md`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/specs/00_SYSTEM_ARCHITECTURE.md)** : Architecture système unifiée multiplateforme.
3. **[`01_DESIGN_SYSTEM_SPEC.md`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/specs/01_DESIGN_SYSTEM_SPEC.md)** : Tokens de couleurs (`#E6007E` Rose Vif / `#FFFFFF` Blanc).
4. **[`02_FRONTEND_PAGES_SPEC.md`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/specs/02_FRONTEND_PAGES_SPEC.md)** : Spécifications des pages web publiques, intranet membre et administration de test.
5. **[`03_BACKEND_API_SPEC.md`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/specs/03_BACKEND_API_SPEC.md)** : API REST Node.js/Express (`/api/config`, `/api/avis`, `/api/devis`, `/api/missions`, `/api/pointage`, `/api/conges`, `/api/admin/*`, `/api/stats`).
6. **[`04_DATABASE_SUPABASE_SPEC.md`](file:///c:/Users/is%20mlckl/Desktop/Sites_web/JBF%20Web/specs/04_DATABASE_SUPABASE_SPEC.md)** : Modèle PostgreSQL Supabase avec tables relationnelles et RLS.
7. **[`05_DESKTOP_FLUTTER_SPEC.md`](file:///c:/Users/is%20mlckl/Desktop/Logiciels/JBF%20Desktop/specs/05_DESKTOP_FLUTTER_SPEC.md)** : Spécifications des logiciels Desktop Flutter (`JBF Admin` & `JBF Membre`).
8. **[`06_MOBILE_FLUTTER_SPEC.md`](file:///A:/App_Mobiles/JBF%20App/specs/06_MOBILE_FLUTTER_SPEC.md)** : Spécifications des applications Mobiles Flutter (`JBF Public`, `JBF Membre`, `JBF Admin`).
