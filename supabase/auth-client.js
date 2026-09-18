/**
 * JBF Services - Unified Supabase Auth Client
 * Gestion centralisée de l'authentification (OTP, Password, Session, Reset)
 * Compatible avec les espaces: Client, Membre, Admin
 */

(function (window) {
    'use strict';

    let SUPABASE_URL = window.ENV_SUPABASE_URL || 'https://dvzwqxcaiagczyonrhsg.supabase.co';
    let SUPABASE_ANON_KEY = window.ENV_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2endxeGNhaWFnY3p5b25yaHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1ODEzNzIsImV4cCI6MjEwNTE1NzM3Mn0.uam5Z-d6SWS9-4Ly9f0ircJPryFJwOXbNp9_alHHl-o';
    const ADMIN_STRICT_EMAIL = 'services@admin.jbf';
    const API_BASE_URL = 'http://localhost:3001/api';

    let _supabase = null;

    async function initAuthSupabase() {
        if (_supabase) return _supabase;
        if (!SUPABASE_ANON_KEY) {
            try {
                const endpoints = ['/api/config', 'http://localhost:3001/api/config', 'http://127.0.0.1:8080/api/config'];
                for (const ep of endpoints) {
                    try {
                        const res = await fetch(ep);
                        if (res.ok) {
                            const d = await res.json();
                            if (d.supabaseUrl) SUPABASE_URL = d.supabaseUrl;
                            if (d.supabaseAnonKey) SUPABASE_ANON_KEY = d.supabaseAnonKey;
                            break;
                        }
                    } catch(e) {}
                }
            } catch(e) {}
        }
        if (window.supabase && typeof window.supabase.createClient === 'function' && SUPABASE_ANON_KEY) {
            _supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
        }
        return _supabase;
    }

    function getSupabase() {
        if (!_supabase) {
            if (window.supabase && typeof window.supabase.createClient === 'function' && SUPABASE_ANON_KEY) {
                _supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
            } else {
                initAuthSupabase();
            }
        }
        return _supabase;
    }

    const JBFAuth = {
        get client() {
            return getSupabase();
        },

        async sendOtp(email) {
            const client = getSupabase();
            if (!client) throw new Error('Supabase SDK indisponible');
            const cleanEmail = email.trim().toLowerCase();

            const { data, error } = await client.auth.signInWithOtp({
                email: cleanEmail,
                options: {
                    shouldCreateUser: false
                }
            });

            if (error) {
                if (error.message && error.message.toLowerCase().includes('signups not allowed')) {
                    throw new Error("Ce compte n'existe pas. Veuillez vous inscrire au préalable.");
                }
                throw error;
            }
            return data;
        },

        async verifyOtp(email, token, targetSpace) {
            const client = getSupabase();
            if (!client) throw new Error('Supabase SDK indisponible');
            const cleanEmail = email.trim().toLowerCase();

            const { data, error } = await client.auth.verifyOtp({
                email: cleanEmail,
                token: token.trim(),
                type: 'email'
            });

            if (error) throw error;
            if (!data.user) throw new Error('Échec de validation du code OTP.');

            return await this.handlePostLogin(data.user, data.session, targetSpace);
        },

        async loginWithPassword(email, password, targetSpace) {
            const client = getSupabase();
            if (!client) throw new Error('Supabase SDK indisponible');
            const cleanEmail = email.trim().toLowerCase();

            if (targetSpace === 'admin' && cleanEmail !== ADMIN_STRICT_EMAIL) {
                throw new Error('Accès refusé : Seul le compte Super Admin officiel est autorisé.');
            }

            const { data, error } = await client.auth.signInWithPassword({
                email: cleanEmail,
                password: password
            });

            if (error) throw error;
            if (!data.user) throw new Error('Identifiants incorrects.');

            return await this.handlePostLogin(data.user, data.session, targetSpace);
        },

        async handlePostLogin(user, session, targetSpace) {
            const client = getSupabase();
            let role = 'client';
            let profileData = null;

            try {
                const { data: profile } = await client
                    .from('profiles')
                    .select('*')
                    .eq('id', user.id)
                    .maybeSingle();

                if (profile) {
                    profileData = profile;
                    role = profile.role || 'client';
                }
            } catch (err) {
                console.warn('[JBF Auth] Impossible de charger le profil Supabase:', err);
            }

            if (user.email === ADMIN_STRICT_EMAIL) {
                role = 'admin';
            }

            if (targetSpace === 'admin') {
                if (user.email !== ADMIN_STRICT_EMAIL && role !== 'admin') {
                    await client.auth.signOut();
                    throw new Error("Accès interdit : Vous n'avez pas les droits Administrateur.");
                }
                const adminUser = {
                    id: user.id,
                    email: user.email,
                    nom: profileData ? (profileData.nom + ' ' + (profileData.prenom || '')) : 'Super Administrateur',
                    role: 'Super Administrateur',
                    permissions: ['*'],
                    token: session.access_token
                };
                localStorage.setItem('JBF_ADMIN_USER', JSON.stringify(adminUser));
                localStorage.setItem('jbf_admin_token', session.access_token);
                return { user: adminUser, redirect: '/JBF Admin/dashboard.html' };
            }

            if (targetSpace === 'membre') {
                if (role !== 'membre' && role !== 'admin') {
                    await client.auth.signOut();
                    throw new Error("Accès interdit : Ce compte n'est pas enregistré comme Membre.");
                }
                const memberUser = {
                    id: user.id,
                    email: user.email,
                    nom: profileData ? (profileData.prenom + ' ' + profileData.nom) : user.email,
                    role: profileData?.role || 'Membre',
                    statut_equipe: profileData?.statut_equipe || 'Membre',
                    token: session.access_token
                };
                localStorage.setItem('JBF_MEMBER_SESSION', JSON.stringify(memberUser));
                return { user: memberUser, redirect: '/JBF Membre/dashboard.html' };
            }

            // Client par défaut
            const clientUser = {
                id: user.id,
                email: user.email,
                nom: profileData ? (profileData.prenom + ' ' + profileData.nom) : user.email,
                telephone: profileData?.telephone || '',
                role: 'client',
                token: session.access_token
            };
            localStorage.setItem('JBF_CLIENT_SESSION', JSON.stringify(clientUser));
            return { user: clientUser, redirect: '/JBF Client/dashboard.html' };
        },

        async sendPasswordReset(email) {
            const client = getSupabase();
            if (!client) throw new Error('Supabase SDK indisponible');
            const cleanEmail = email.trim().toLowerCase();

            const { data, error } = await client.auth.resetPasswordForEmail(cleanEmail);
            if (error) throw error;
            return data;
        },

        async updatePassword(newPassword) {
            const client = getSupabase();
            if (!client) throw new Error('Supabase SDK indisponible');

            const { data, error } = await client.auth.updateUser({
                password: newPassword
            });
            if (error) throw error;
            return data;
        },

        async logout(targetSpace) {
            const client = getSupabase();
            if (client) {
                try {
                    await client.auth.signOut();
                } catch (e) {
                    console.warn('[JBF Auth] Déconnexion Supabase échouée:', e);
                }
            }
            if (targetSpace === 'admin') {
                localStorage.removeItem('JBF_ADMIN_USER');
                localStorage.removeItem('jbf_admin_token');
                window.location.href = '/JBF Admin/auth/login.html';
            } else if (targetSpace === 'membre') {
                localStorage.removeItem('JBF_MEMBER_SESSION');
                window.location.href = '/JBF Membre/auth/login.html';
            } else {
                localStorage.removeItem('JBF_CLIENT_SESSION');
                window.location.href = '/JBF Client/auth/login.html';
            }
        }
    };

    window.JBFAuth = JBFAuth;
})(window);
