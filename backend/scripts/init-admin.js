// =============================================================
// JBF SERVICES — INITIALISATION ADMINISTRATEUR SUPABASE
// Identifiants chargés dynamiquement depuis backend/.env
// =============================================================

require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://dvzwqxcaiagczyonrhsg.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ Clé SUPABASE_SERVICE_ROLE_KEY manquante dans backend/.env');
  process.exit(1);
}

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false }
});

async function initOfficialAdmin() {
  const adminEmail = (process.env.ADMIN_OFFICIAL_EMAIL || 'services@admin.jbf').trim().toLowerCase();
  const adminPassword = process.env.ADMIN_OFFICIAL_PASSWORD || 'Services+243JBF';

  console.log(`🔐 Initialisation du compte Administrateur officiel : ${adminEmail}...`);

  try {
    // 1. Vérifier si l'utilisateur existe déjà dans auth.users
    const { data: usersList, error: listError } = await supabaseAdmin.auth.admin.listUsers();
    if (listError) throw listError;

    let existingUser = usersList.users.find(u => u.email?.toLowerCase() === adminEmail.toLowerCase());
    let userId;

    if (existingUser) {
      console.log(`ℹ️ L'utilisateur ${adminEmail} existe déjà (ID: ${existingUser.id}). Mise à jour du mot de passe...`);
      userId = existingUser.id;
      const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(userId, {
        password: adminPassword,
        email_confirm: true,
        user_metadata: {
          full_name: 'Direction Générale JBF SERVICES',
          role: 'admin',
          phone: '+243971306666'
        }
      });
      if (updateError) throw updateError;
      console.log('✅ Mot de passe et métadonnées mis à jour dans Supabase Auth.');
    } else {
      console.log(`🆕 Création du compte ${adminEmail} dans Supabase Auth...`);
      const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
        email: adminEmail,
        password: adminPassword,
        email_confirm: true,
        user_metadata: {
          full_name: 'Direction Générale JBF SERVICES',
          role: 'admin',
          phone: '+243971306666'
        }
      });
      if (createError) throw createError;
      userId = newUser.user.id;
      console.log(`✅ Utilisateur créé dans Supabase Auth avec succès (ID: ${userId}).`);
    }

    // 2. Synchroniser dans la table public.profiles
    const { error: profileError } = await supabaseAdmin.from('profiles').upsert([{
      id: userId,
      email: adminEmail,
      full_name: 'Direction Générale JBF SERVICES',
      phone: '+243971306666',
      poste: 'Super Administrateur',
      role: 'admin',
      is_verified: true,
      updated_at: new Date().toISOString()
    }]);

    if (profileError) {
      console.warn('⚠️ Avertissement profil :', profileError.message);
    } else {
      console.log('✅ Profil synchronisé dans public.profiles.');
    }

    // 3. Synchroniser dans la table public.admin_accounts
    const { error: accountError } = await supabaseAdmin.from('admin_accounts').upsert([{
      full_name: 'Direction Générale JBF SERVICES',
      email: adminEmail,
      phone: '+243971306666',
      role: 'super_admin',
      permissions: ['*'],
      is_active: true,
      updated_at: new Date().toISOString()
    }], { onConflict: 'email' });

    if (accountError) {
      console.warn('⚠️ Avertissement admin_accounts :', accountError.message);
    } else {
      console.log('✅ Compte enregistré dans public.admin_accounts avec permissions complètes.');
    }

    console.log('\n🎉 INITIALISATION RÉUSSIE :');
    console.log(`   Email        : ${adminEmail}`);
    console.log(`   Mot de passe : [${adminPassword}]`);
    console.log('   Rôle         : Super Administrateur');

  } catch (err) {
    console.error('❌ Erreur lors de l\'initialisation de l\'admin :', err.message || err);
  }
}

if (require.main === module) {
  initOfficialAdmin();
}

module.exports = { initOfficialAdmin };
