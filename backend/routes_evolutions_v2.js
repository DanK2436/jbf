// ==============================================================================
// ROUTES ÉVOLUTIONS V2 — JBF SERVICES (ADMIN, MEMBRE, CLIENT, RH & FINANCE)
// ==============================================================================

const express = require('express');
const router = express.Router();
const { packJbfFile, unpackJbfFile } = require('./jbf_format');

module.exports = function({ supabaseAdmin, supabasePublic, sendTransactionalEmail }) {

  // ============================================================================
  // 1. RECRUTEMENT PUBLIC & CANDIDATURES SANS CONNEXION
  // ============================================================================

  // GET /api/recrutement/statut — Vérifier si la page de recrutement est active
  router.get('/recrutement/statut', async (req, res) => {
    try {
      const { data, error } = await supabaseAdmin
        .from('config_cles_api')
        .select('*')
        .eq('cle_nom', 'recrutement_actif')
        .single();

      let estActif = true;
      let messageSuspension = 'Les candidatures spontanées sont actuellement suspendues par la Direction RH.';

      if (data) {
        estActif = data.cle_valeur === 'true' || data.is_active === true;
        if (data.description) messageSuspension = data.description;
      }

      res.json({ success: true, recrutement_actif: estActif, message_suspension: messageSuspension });
    } catch (_) {
      res.json({ success: true, recrutement_actif: true });
    }
  });

  // PUT /api/admin/recrutement/toggle — Activer ou désactiver les candidatures publiques
  router.put('/admin/recrutement/toggle', async (req, res) => {
    try {
      const isActif = req.body.actif !== undefined 
        ? Boolean(req.body.actif) 
        : (req.body.ouvert !== undefined ? Boolean(req.body.ouvert) : true);
      const message_suspension = req.body.message_suspension || req.body.motif;

      const { data, error } = await supabaseAdmin
        .from('config_cles_api')
        .upsert([{
          cle_nom: 'recrutement_actif',
          cle_valeur: isActif ? 'true' : 'false',
          is_active: isActif,
          description: message_suspension || 'Statut des campagnes de recrutement public JBF Service',
          updated_at: new Date().toISOString()
        }], { onConflict: 'cle_nom' })
        .select()
        .single();

      if (error) throw error;
      res.json({ success: true, recrutement_actif: isActif, message: isActif ? 'Recrutement activé' : 'Recrutement suspendu' });
    } catch (err) {
      console.error('Erreur toggle recrutement:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // POST /api/candidatures/postuler — Soumission publique de CV et dossier
  router.post('/candidatures/postuler', async (req, res) => {
    try {
      // Vérifier si le recrutement est actif
      const { data: cfg } = await supabaseAdmin
        .from('config_cles_api')
        .select('*')
        .eq('cle_nom', 'recrutement_actif')
        .single();

      if (cfg && (cfg.cle_valeur === 'false' || cfg.is_active === false)) {
        return res.status(403).json({
          success: false,
          error: 'Les candidatures sont actuellement suspendues par la Direction des Ressources Humaines.'
        });
      }
      const nom_complet = req.body.nom_complet || (req.body.nom ? `${req.body.prenom || ''} ${req.body.nom}`.trim() : null);
      const email = req.body.email;
      const telephone = req.body.telephone;
      const province_residence = req.body.province_residence || req.body.province || 'Haut-Katanga';
      const domaine_expertise = req.body.domaine_expertise || req.body.poste_convoite || req.body.poste || 'Général';
      const annees_experience = req.body.annees_experience || req.body.experience_annees || 0;
      const cv_url = req.body.cv_url || req.body.cv || 'https://jbf-service.com/uploads/candidatures/cv-transmis.pdf';
      const lettre_motivation_url = req.body.lettre_motivation_url || req.body.lettre_motivation || null;
      const diplomes_attestations_urls = req.body.diplomes_attestations_urls || req.body.diplomes || [];

      if (!nom_complet || !email || !telephone) {
        return res.status(400).json({
          success: false,
          error: 'Champs obligatoires manquants : nom complet, email et téléphone.'
        });
      }

      const { data, error } = await supabaseAdmin
        .from('candidatures')
        .insert([{
          nom_complet,
          email: email.trim().toLowerCase(),
          telephone: telephone.trim(),
          province_residence,
          domaine_expertise,
          annees_experience: parseInt(annees_experience, 10) || 0,
          cv_url,
          lettre_motivation_url: lettre_motivation_url || null,
          diplomes_attestations_urls: diplomes_attestations_urls || [],
          statut: 'en_attente'
        }])
        .select()
        .single();

      if (error) throw error;

      // Email de confirmation automatique au candidat
      try {
        const emailHtml = `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
            <div style="text-align: center; margin-bottom: 20px;">
              <h2 style="color: #E6007E; margin: 0;">JBF SERVICES SARL</h2>
              <p style="color: #666; font-size: 13px;">Direction des Ressources Humaines & Talents</p>
            </div>
            <p>Bonjour <strong>${nom_complet}</strong>,</p>
            <p>Nous accusons bonne réception de votre candidature pour le domaine <strong>${domaine_expertise}</strong> (Province de ${province_residence}).</p>
            <p>Votre dossier est actuellement en cours d'évaluation par notre équipe RH. Si votre profil est retenu, vous recevrez une convocation officielle directement par email et sur votre portail.</p>
            <div style="background-color: #f8f9fa; padding: 15px; border-radius: 6px; margin: 20px 0;">
              <p style="margin: 0; font-size: 12px; color: #555;"><strong>Référence Dossier :</strong> JBF-REC-${data.id.substring(0, 8).toUpperCase()}</p>
            </div>
            <p style="font-size: 13px; color: #777;">Cordialement,<br><strong>Département Recrutement — JBF Services RDC</strong></p>
          </div>
        `;
        await sendTransactionalEmail(email, 'Confirmation de réception de votre candidature — JBF Services', emailHtml);
      } catch (mailErr) {
        console.warn('Notice email accusé candidature:', mailErr.message);
      }

      res.status(201).json({
        success: true,
        message: 'Votre candidature a été transmise avec succès à la Direction RH de JBF Services.',
        candidature: data
      });
    } catch (err) {
      console.error('Erreur POST /candidatures/postuler:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // GET /api/admin/candidatures — Liste des candidatures avec filtres
  router.get('/admin/candidatures', async (req, res) => {
    try {
      const { statut, province, search } = req.query;
      let query = supabaseAdmin.from('candidatures').select('*').order('created_at', { ascending: false });

      if (statut) query = query.eq('statut', statut);
      if (province) query = query.eq('province_residence', province);
      if (search) query = query.or(`nom_complet.ilike.%${search}%,email.ilike.%${search}%,domaine_expertise.ilike.%${search}%`);

      const { data, error } = await query;
      if (error) throw error;

      res.json({ success: true, count: data.length, candidatures: data });
    } catch (err) {
      console.error('Erreur GET /admin/candidatures:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // POST /api/admin/candidatures/:id/convoquer — Envoi d'une convocation officielle
  router.post('/admin/candidatures/:id/convoquer', async (req, res) => {
    try {
      const { id } = req.params;
      const { date_convocation, lieu_ou_visio, message_consignes, envoyee_par } = req.body;

      if (!date_convocation || !lieu_ou_visio) {
        return res.status(400).json({ success: false, error: 'Date et lieu/lien de convocation obligatoires.' });
      }

      const { data: cand, error: fetchErr } = await supabaseAdmin
        .from('candidatures')
        .select('*')
        .eq('id', id)
        .single();

      if (fetchErr || !cand) {
        return res.status(404).json({ success: false, error: 'Candidature introuvable.' });
      }

      const convocationDetails = {
        date_convocation,
        lieu_ou_visio,
        message_consignes: message_consignes || 'Veuillez vous munir de vos pièces d\'identité et originaux de diplômes.',
        envoyee_par: envoyee_par || 'Direction des Ressources Humaines JBF',
        date_envoi: new Date().toISOString()
      };

      const { data: updated, error: updateErr } = await supabaseAdmin
        .from('candidatures')
        .update({
          statut: 'convoque',
          convocation_details: convocationDetails,
          date_convocation_envoyee: new Date().toISOString()
        })
        .eq('id', id)
        .select()
        .single();

      if (updateErr) throw updateErr;

      // Envoi du mail de convocation
      const emailHtml = `
        <div style="font-family: Arial, sans-serif; max-width: 620px; margin: 0 auto; padding: 25px; border: 2px solid #E6007E; border-radius: 10px;">
          <div style="text-align: center; border-bottom: 2px solid #f0f0f0; padding-bottom: 15px; margin-bottom: 20px;">
            <h1 style="color: #E6007E; margin: 0; font-size: 24px;">CONVOCATION OFFICIELLE</h1>
            <p style="color: #333; font-weight: bold; margin-top: 5px;">JBF SERVICES SARL — ENTRETIEN DE RECRUTEMENT</p>
          </div>
          <p>Cher(ère) <strong>${cand.nom_complet}</strong>,</p>
          <p>Faisant suite à votre candidature pour le poste/domaine <strong>${cand.domaine_expertise}</strong>, nous avons le plaisir de vous convoquer à un entretien avec notre comité de recrutement.</p>
          
          <div style="background-color: #FFF0F6; border-left: 4px solid #E6007E; padding: 15px; margin: 20px 0; border-radius: 4px;">
            <p style="margin: 0 0 8px 0;"><strong>Date & Heure :</strong> ${date_convocation}</p>
            <p style="margin: 0 0 8px 0;"><strong>Lieu ou Lien :</strong> ${lieu_ou_visio}</p>
            <p style="margin: 0;"><strong>Consignes :</strong> ${convocationDetails.message_consignes}</p>
          </div>

          <p>Merci de nous confirmer votre disponibilité en répondant à cet e-mail.</p>
          <p style="font-size: 13px; color: #777; margin-top: 25px;">La Direction Générale & Ressources Humaines<br><strong>JBF SERVICES SARL</strong></p>
        </div>
      `;

      await sendTransactionalEmail(cand.email, `Convocation à un entretien — JBF SERVICES (${cand.nom_complet})`, emailHtml);

      res.json({
        success: true,
        message: 'Convocation enregistrée et expédiée au candidat avec succès.',
        candidature: updated
      });
    } catch (err) {
      console.error('Erreur POST /admin/candidatures/:id/convoquer:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // PUT /api/admin/candidatures/:id/statut — Mise à jour de statut
  router.put('/admin/candidatures/:id/statut', async (req, res) => {
    try {
      const { id } = req.params;
      const { statut, commentaires_recruteur } = req.body;

      const { data, error } = await supabaseAdmin
        .from('candidatures')
        .update({
          statut,
          commentaires_recruteur: commentaires_recruteur || null,
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      res.json({ success: true, candidature: data });
    } catch (err) {
      console.error('Erreur PUT /admin/candidatures/:id/statut:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ============================================================================
  // 2. GESTION DES UTILISATEURS (ADMIN : CLIENTS, MEMBRES, SOUS-ADMINS)
  // ============================================================================

  // GET /api/admin/users — Liste unifiée des utilisateurs
  router.get('/admin/users', async (req, res) => {
    try {
      const { role, statut, search } = req.query;
      let query = supabaseAdmin.from('profiles').select('*').order('created_at', { ascending: false });

      if (role && role !== 'tous') query = query.eq('role', role);
      if (statut === 'desactive') query = query.eq('is_disabled', true);
      if (statut === 'actif') query = query.eq('is_disabled', false);
      if (search) {
        query = query.or(`full_name.ilike.%${search}%,email.ilike.%${search}%,telephone.ilike.%${search}%,company.ilike.%${search}%`);
      }

      const { data, error } = await query;
      if (error) throw error;

      res.json({ success: true, count: data.length, users: data });
    } catch (err) {
      console.error('Erreur GET /admin/users:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // POST /api/admin/users/creer — Création d'un utilisateur par l'Admin
  router.post('/admin/users/creer', async (req, res) => {
    try {
      const { email, password, full_name, role, phone, company, poste, province, permissions } = req.body;

      if (!email || !password || !full_name) {
        return res.status(400).json({ success: false, error: 'Email, mot de passe et nom obligatoires.' });
      }

      const cleanEmail = email.trim().toLowerCase();

      // Création compte Auth
      const { data: authData, error: authErr } = await supabaseAdmin.auth.admin.createUser({
        email: cleanEmail,
        password: password,
        email_confirm: true,
        user_metadata: { full_name, role: role || 'client' }
      });

      if (authErr) throw authErr;

      const userId = authData.user.id;

      // Insertion dans profiles
      const { data: profile, error: profErr } = await supabaseAdmin
        .from('profiles')
        .upsert([{
          id: userId,
          user_id: userId,
          email: cleanEmail,
          full_name,
          role: role || 'client',
          phone: phone || '',
          company: company || '',
          poste: poste || '',
          province: province || 'Haut-Katanga',
          is_disabled: false,
          statut_compte: 'actif',
          permissions_detaillees: permissions || { all: role === 'super_admin' },
          updated_at: new Date().toISOString()
        }])
        .select()
        .single();

      if (profErr) throw profErr;

      res.status(201).json({ success: true, message: 'Utilisateur créé avec succès.', user: profile });
    } catch (err) {
      console.error('Erreur POST /admin/users/creer:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // PUT /api/admin/users/:id/desactiver — Activer / Désactiver un utilisateur
  router.put('/admin/users/:id/desactiver', async (req, res) => {
    try {
      const { id } = req.params;
      const { desactiver } = req.body; // boolean

      const isDisabled = Boolean(desactiver);

      const { data, error } = await supabaseAdmin
        .from('profiles')
        .update({
          is_disabled: isDisabled,
          statut_compte: isDisabled ? 'desactive' : 'actif',
          token_invalidation_ts: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;

      res.json({
        success: true,
        message: isDisabled ? 'Compte désactivé et sessions révoquées.' : 'Compte réactivé.',
        user: data
      });
    } catch (err) {
      console.error('Erreur PUT /admin/users/:id/desactiver:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // DELETE /api/admin/users/:id — Suppression d'un utilisateur
  router.delete('/admin/users/:id', async (req, res) => {
    try {
      const { id } = req.params;

      // Supprimer de auth.users si possible
      try {
        await supabaseAdmin.auth.admin.deleteUser(id);
      } catch (_) {}

      // Supprimer du profil
      const { error } = await supabaseAdmin.from('profiles').delete().eq('id', id);
      if (error) throw error;

      res.json({ success: true, message: 'Utilisateur supprimé définitivement.' });
    } catch (err) {
      console.error('Erreur DELETE /admin/users/:id:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ============================================================================
  // 3. GESTION RH & COMPÉTENCES
  // ============================================================================

  // GET /api/admin/rh/collaborateurs — Base de données collaborateurs
  router.get('/admin/rh/collaborateurs', async (req, res) => {
    try {
      const { disponibilite, competence } = req.query;
      let query = supabaseAdmin
        .from('rh_collaborateurs')
        .select(`
          *,
          profile:profiles(id, full_name, email, phone, province, avatar_url)
        `)
        .order('created_at', { ascending: false });

      if (disponibilite) query = query.eq('statut_disponibilite', disponibilite);
      if (competence) query = query.contains('competences', [competence]);

      const { data, error } = await query;
      if (error) throw error;

      res.json({ success: true, count: data.length, collaborateurs: data });
    } catch (err) {
      console.error('Erreur GET /admin/rh/collaborateurs:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // POST /api/admin/rh/collaborateurs — Ajout ou mise à jour fiche RH
  router.post('/admin/rh/collaborateurs', async (req, res) => {
    try {
      const {
        profile_id,
        matricule,
        type_contrat,
        salaire_base,
        devise_salaire,
        competences,
        niveau_qualification,
        statut_disponibilite,
        site_actuel,
        province_affectation
      } = req.body;

      if (!profile_id || !matricule) {
        return res.status(400).json({ success: false, error: 'profile_id et matricule requis.' });
      }

      const { data, error } = await supabaseAdmin
        .from('rh_collaborateurs')
        .upsert([{
          profile_id,
          matricule,
          type_contrat: type_contrat || 'CDI',
          salaire_base: parseFloat(salaire_base) || 0,
          devise_salaire: devise_salaire || 'USD',
          competences: Array.isArray(competences) ? competences : [],
          niveau_qualification: niveau_qualification || 'Technicien',
          statut_disponibilite: statut_disponibilite || 'disponible',
          site_actuel: site_actuel || null,
          province_affectation: province_affectation || 'Haut-Katanga',
          updated_at: new Date().toISOString()
        }], { onConflict: 'matricule' })
        .select()
        .single();

      if (error) throw error;
      res.json({ success: true, collaborateur: data });
    } catch (err) {
      console.error('Erreur POST /admin/rh/collaborateurs:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ============================================================================
  // 4. GESTION FINANCIÈRE & REÇUS
  // ============================================================================

  // GET /api/admin/finance/ecritures — Journal des écritures & totaux
  router.get('/admin/finance/ecritures', async (req, res) => {
    try {
      const { type_operation, categorie, date_debut, date_fin } = req.query;
      let query = supabaseAdmin.from('comptabilite_ecritures').select('*').order('date_ecriture', { ascending: false });

      if (type_operation) query = query.eq('type_operation', type_operation);
      if (categorie) query = query.eq('categorie', categorie);
      if (date_debut) query = query.gte('date_ecriture', date_debut);
      if (date_fin) query = query.lte('date_ecriture', date_fin);

      const { data, error } = await query;
      if (error) throw error;

      let totalRecettes = 0;
      let totalDepenses = 0;
      data.forEach(e => {
        const montant = parseFloat(e.montant) || 0;
        if (e.type_operation === 'recette_client') {
          totalRecettes += montant;
        } else {
          totalDepenses += montant;
        }
      });

      res.json({
        success: true,
        count: data.length,
        solde_net: totalRecettes - totalDepenses,
        total_recettes: totalRecettes,
        total_depenses: totalDepenses,
        ecritures: data
      });
    } catch (err) {
      console.error('Erreur GET /admin/finance/ecritures:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // POST /api/admin/finance/ecritures — Nouvelle écriture comptable
  router.post('/admin/finance/ecritures', async (req, res) => {
    try {
      const {
        type_operation,
        categorie,
        montant,
        devise,
        tiers_nom,
        reference_piece,
        mode_paiement,
        mission_associee_id,
        justificatif_url
      } = req.body;

      if (!type_operation || !categorie || !montant || !tiers_nom) {
        return res.status(400).json({ success: false, error: 'Champs obligatoires manquants pour l\'écriture.' });
      }

      const numEcriture = `ECR-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

      const { data, error } = await supabaseAdmin
        .from('comptabilite_ecritures')
        .insert([{
          numero_ecriture: numEcriture,
          type_operation,
          categorie,
          montant: parseFloat(montant),
          devise: devise || 'USD',
          tiers_nom,
          reference_piece: reference_piece || numEcriture,
          mode_paiement: mode_paiement || 'virement',
          mission_associee_id: mission_associee_id || null,
          justificatif_url: justificatif_url || null
        }])
        .select()
        .single();

      if (error) throw error;

      // Si c'est une recette liée à une mission, on met à jour le statut paiement mission
      if (type_operation === 'recette_client' && mission_associee_id) {
        await supabaseAdmin
          .from('missions')
          .update({
            statut_paiement_client: 'paye_integralement',
            progression_debloquee_client: true,
            updated_at: new Date().toISOString()
          })
          .eq('id', mission_associee_id);
      }

      res.status(201).json({ success: true, ecriture: data });
    } catch (err) {
      console.error('Erreur POST /admin/finance/ecritures:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // POST /api/admin/finance/recus/generer — Émission et envoi d'un reçu au client
  router.post('/admin/finance/recus/generer', async (req, res) => {
    try {
      const { client_nom, client_email, montant, devise, motif, reference_paiement, mission_id } = req.body;

      if (!client_email || !montant) {
        return res.status(400).json({ success: false, error: 'Email client et montant requis.' });
      }

      const recuNumero = `RECU-JBF-${new Date().getFullYear()}-${Math.floor(100000 + Math.random() * 900000)}`;
      const dateEmission = new Date().toLocaleDateString('fr-FR');

      const recuHtml = `
        <div style="font-family: Arial, sans-serif; max-width: 650px; margin: 0 auto; padding: 30px; border: 2px solid #E6007E; border-radius: 12px;">
          <div style="display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #f0f0f0; padding-bottom: 20px;">
            <div>
              <h2 style="color: #E6007E; margin: 0;">JBF SERVICES SARL</h2>
              <p style="margin: 2px 0; font-size: 11px; color: #555;">Sous-traitance & Services Industriels en RDC</p>
              <p style="margin: 2px 0; font-size: 11px; color: #777;">NIF: A2314569B — RCCM: CD/LSH/RCCM/20-B-0123</p>
            </div>
            <div style="text-align: right;">
              <span style="background: #E6007E; color: white; padding: 6px 12px; border-radius: 6px; font-weight: bold; font-size: 14px;">REÇU OFFICIEL</span>
              <p style="margin: 6px 0 0 0; font-size: 12px; font-weight: bold;">N° ${recuNumero}</p>
            </div>
          </div>

          <div style="margin: 25px 0;">
            <p><strong>Reçu de :</strong> ${client_nom || 'Client Partenaire'}</p>
            <p><strong>Date d'encaissement :</strong> ${dateEmission}</p>
            <p><strong>Motif du règlement :</strong> ${motif || 'Prestation de services industriels / Devis JBF'}</p>
            <p><strong>Référence de transaction :</strong> ${reference_paiement || 'Paiement direct vérifié'}</p>
          </div>

          <div style="background-color: #FAFAFA; border: 1px dashed #ccc; padding: 20px; border-radius: 8px; text-align: center; margin: 25px 0;">
            <p style="margin: 0; font-size: 14px; color: #666;">Montant Total Encaissé :</p>
            <h1 style="color: #0C0C0E; margin: 8px 0; font-size: 32px;">${parseFloat(montant).toLocaleString('fr-FR', { minimumFractionDigits: 2 })} ${devise || 'USD'}</h1>
            <p style="color: #2e7d32; font-weight: bold; font-size: 12px; margin: 0;">✓ Paiement validé & comptabilisé</p>
          </div>

          <div style="border-top: 1px solid #eee; padding-top: 15px; font-size: 11px; color: #888; text-align: center;">
            <p>Ce reçu électronique fait foi de preuve de paiement. Pour toute réclamation : services@admin.jbf | +243 971 306 666</p>
          </div>
        </div>
      `;

      await sendTransactionalEmail(client_email, `Reçu de Paiement Officiel ${recuNumero} — JBF Services`, recuHtml);

      // Si lié à une mission, débloquer immédiatement la visibilité du projet
      if (mission_id) {
        await supabaseAdmin
          .from('missions')
          .update({
            statut_paiement_client: 'acompte_regle',
            progression_debloquee_client: true,
            updated_at: new Date().toISOString()
          })
          .eq('id', mission_id);
      }

      res.json({
        success: true,
        message: 'Reçu officiel généré et expédié au client avec succès.',
        recu_numero: recuNumero
      });
    } catch (err) {
      console.error('Erreur POST /admin/finance/recus/generer:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ============================================================================
  // 5. GESTION DU CATALOGUE DE SERVICES
  // ============================================================================

  // GET /api/services — Liste publique des services
  router.get('/services', async (req, res) => {
    try {
      const { data, error } = await supabaseAdmin
        .from('services_catalogue')
        .select('*')
        .eq('est_actif', true)
        .order('ordre_affichage', { ascending: true });

      if (error) throw error;
      res.json({ success: true, count: data.length, services: data });
    } catch (err) {
      console.error('Erreur GET /services:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // POST /api/admin/services — Ajout de service
  router.post('/admin/services', async (req, res) => {
    try {
      const { code_service, titre, categorie, description_courte, description_complete, icone_nom, tarification_indicative } = req.body;
      const { data, error } = await supabaseAdmin
        .from('services_catalogue')
        .insert([{
          code_service: code_service || `SRV-${Date.now().toString().slice(-4)}`,
          titre,
          categorie,
          description_courte,
          description_complete,
          icone_nom: icone_nom || 'construction',
          tarification_indicative,
          est_actif: true
        }])
        .select()
        .single();

      if (error) throw error;
      res.status(201).json({ success: true, service: data });
    } catch (err) {
      console.error('Erreur POST /admin/services:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // PUT /api/admin/services/:id — Mise à jour ou désactivation
  router.put('/admin/services/:id', async (req, res) => {
    try {
      const { id } = req.params;
      const updates = req.body;
      updates.updated_at = new Date().toISOString();

      const { data, error } = await supabaseAdmin
        .from('services_catalogue')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      res.json({ success: true, service: data });
    } catch (err) {
      console.error('Erreur PUT /admin/services/:id:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // DELETE /api/admin/services/:id — Suppression
  router.delete('/admin/services/:id', async (req, res) => {
    try {
      const { id } = req.params;
      const { error } = await supabaseAdmin.from('services_catalogue').delete().eq('id', id);
      if (error) throw error;
      res.json({ success: true, message: 'Service supprimé du catalogue.' });
    } catch (err) {
      console.error('Erreur DELETE /admin/services/:id:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ============================================================================
  // 6. PROGRESSION TRIPARTITE DES MISSIONS & JALONS
  // ============================================================================

  // GET /api/missions/:id/etapes — Récupérer les jalons d'une mission
  router.get('/missions/:id/etapes', async (req, res) => {
    try {
      const { id } = req.params;
      const { data, error } = await supabaseAdmin
        .from('mission_etapes')
        .select('*')
        .eq('mission_id', id)
        .order('ordre_etape', { ascending: true });

      if (error) throw error;
      res.json({ success: true, count: data.length, etapes: data });
    } catch (err) {
      console.error('Erreur GET /missions/:id/etapes:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // POST /api/admin/missions/:id/etapes — Créer des jalons (WBS)
  router.post('/admin/missions/:id/etapes', async (req, res) => {
    try {
      const { id } = req.params;
      const { titre_etape, description, ordre_etape } = req.body;

      const { data, error } = await supabaseAdmin
        .from('mission_etapes')
        .insert([{
          mission_id: id,
          titre_etape,
          description: description || null,
          ordre_etape: parseInt(ordre_etape, 10) || 1
        }])
        .select()
        .single();

      if (error) throw error;
      res.status(201).json({ success: true, etape: data });
    } catch (err) {
      console.error('Erreur POST /admin/missions/:id/etapes:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // PUT /api/membre/missions/:id/etapes/:etapeId/valider — Membre valide étape avec preuves
  router.put('/membre/missions/:id/etapes/:etapeId/valider', async (req, res) => {
    try {
      const { etapeId } = req.params;
      const { membre_id, preuves_photos, coordonnees_gps, observations_membre } = req.body;

      const { data, error } = await supabaseAdmin
        .from('mission_etapes')
        .update({
          est_acheve_par_membre: true,
          valide_par_membre_id: membre_id || null,
          date_achevement_membre: new Date().toISOString(),
          preuves_photos: preuves_photos || [],
          coordonnees_gps: coordonnees_gps || null,
          observations_membre: observations_membre || null,
          updated_at: new Date().toISOString()
        })
        .eq('id', etapeId)
        .select()
        .single();

      if (error) throw error;
      res.json({ success: true, message: 'Étape transmise pour validation administrative.', etape: data });
    } catch (err) {
      console.error('Erreur validation membre etape:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // PUT /api/admin/missions/:id/etapes/:etapeId/approuver — Admin approuve l'étape et publie au client
  router.put('/admin/missions/:id/etapes/:etapeId/approuver', async (req, res) => {
    try {
      const { id, etapeId } = req.params;
      const { admin_id, commentaires_admin } = req.body;

      const { data: step, error: stepErr } = await supabaseAdmin
        .from('mission_etapes')
        .update({
          est_approuve_par_admin: true,
          approuve_par_admin_id: admin_id || null,
          date_approbation_admin: new Date().toISOString(),
          visible_par_client: true,
          commentaires_admin: commentaires_admin || null,
          updated_at: new Date().toISOString()
        })
        .eq('id', etapeId)
        .select()
        .single();

      if (stepErr) throw stepErr;

      // Calculer nouveau % d'avancement de la mission
      const { data: allSteps } = await supabaseAdmin
        .from('mission_etapes')
        .select('id, est_approuve_par_admin')
        .eq('mission_id', id);

      if (allSteps && allSteps.length > 0) {
        const approvedCount = allSteps.filter(s => s.est_approuve_par_admin).length;
        const newPct = Math.round((approvedCount / allSteps.length) * 100);

        await supabaseAdmin
          .from('missions')
          .update({
            progression_pct: newPct,
            statut: newPct === 100 ? 'terminee' : 'en_cours',
            updated_at: new Date().toISOString()
          })
          .eq('id', id);
      }

      res.json({ success: true, message: 'Étape approuvée et transmise au client.', etape: step });
    } catch (err) {
      console.error('Erreur approbation admin etape:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // GET /api/client/missions/:id/progression — Vue progression sous condition de paiement validé
  router.get('/client/missions/:id/progression', async (req, res) => {
    try {
      const { id } = req.params;

      const { data: mission, error: missErr } = await supabaseAdmin
        .from('missions')
        .select('*')
        .eq('id', id)
        .single();

      if (missErr || !mission) {
        return res.status(404).json({ success: false, error: 'Mission introuvable.' });
      }

      // VÉRIFICATION DU PAIEMENT ET VALIDATION ADMIN
      const isPaid = mission.statut_paiement_client === 'acompte_regle' || mission.statut_paiement_client === 'paye_integralement';
      const isUnlocked = mission.progression_debloquee_client === true || isPaid;

      if (!isUnlocked) {
        return res.status(403).json({
          success: false,
          acces_bloque: true,
          raison: 'PAIEMENT_EN_ATTENTE',
          message: 'La progression détaillée et les livrables de ce projet seront accessibles dès confirmation de l\'acompte ou du règlement par la Direction JBF.',
          statut_paiement: mission.statut_paiement_client
        });
      }

      const { data: etapes } = await supabaseAdmin
        .from('mission_etapes')
        .select('*')
        .eq('mission_id', id)
        .eq('visible_par_client', true)
        .order('ordre_etape', { ascending: true });

      res.json({
        success: true,
        acces_bloque: false,
        mission,
        progression_pct: mission.progression_pct,
        etapes: etapes || []
      });
    } catch (err) {
      console.error('Erreur GET /client/missions/:id/progression:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // ============================================================================
  // 7. FORMAT SÉCURISÉ PROPRIÉTAIRE .jbf
  // ============================================================================

  // POST /api/fichiers/jbf-pack — Encapsule et chiffre un document au format .jbf
  router.post('/fichiers/jbf-pack', (req, res) => {
    try {
      const { titre, typeOriginal, contenu, emetteur, missionCode } = req.body;
      if (!contenu) {
        return res.status(400).json({ success: false, error: 'Contenu obligatoire à chiffrer.' });
      }

      const jbfBuffer = packJbfFile({ titre, typeOriginal, contenu, emetteur, missionCode });
      res.json({
        success: true,
        nom_fichier: `${(titre || 'document').replace(/[^a-zA-Z0-9_-]/g, '_')}.jbf`,
        format: 'jbf',
        taille_octets: jbfBuffer.length,
        jbf_base64: jbfBuffer.toString('base64')
      });
    } catch (err) {
      console.error('Erreur pack .jbf:', err.message);
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // POST /api/fichiers/jbf-unpack — Déchiffre un document .jbf pour consultation in-app
  router.post('/fichiers/jbf-unpack', (req, res) => {
    try {
      const { jbf_base64 } = req.body;
      if (!jbf_base64) {
        return res.status(400).json({ success: false, error: 'Buffer jbf_base64 manquant.' });
      }

      const buffer = Buffer.from(jbf_base64, 'base64');
      const decoded = unpackJbfFile(buffer);

      res.json({
        success: true,
        document: {
          titre: decoded.titre,
          typeOriginal: decoded.typeOriginal,
          emetteur: decoded.emetteur,
          missionCode: decoded.missionCode,
          dateCreation: decoded.dateCreation,
          checksum: decoded.checksum,
          contenuTexte: decoded.contenuTexte
        }
      });
    } catch (err) {
      console.error('Erreur unpack .jbf:', err.message);
      res.status(400).json({ success: false, error: err.message });
    }
  });

  return router;
};
