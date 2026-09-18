/* ========================================================
   JBF SERVICES - SUPABASE JS CLIENT CONFIG & HELPERS
   Version: 1.0.0
   100% Supabase Architecture - No External Services
   Colors: Rose Vif (#E6007E), Magenta Fonce (#B6005E), Noir (#000000), Blanc (#FFFFFF)
   Sans aucun emoji
   ======================================================== */

// Supabase Credentials Config
let SUPABASE_URL = window.ENV_SUPABASE_URL || "https://dvzwqxcaiagczyonrhsg.supabase.co";
let SUPABASE_ANON_KEY = window.ENV_SUPABASE_ANON_KEY || "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2endxeGNhaWFnY3p5b25yaHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1ODEzNzIsImV4cCI6MjEwNTE1NzM3Mn0.uam5Z-d6SWS9-4Ly9f0ircJPryFJwOXbNp9_alHHl-o";

// Initialize Supabase Client
let supabaseClient = null;
async function initSupabaseClient() {
    if (supabaseClient) return supabaseClient;
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
    if (typeof supabase !== 'undefined' && SUPABASE_ANON_KEY) {
        try {
            supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
        } catch(e) {}
    }
    return supabaseClient;
}
initSupabaseClient();

// Authentication Helpers
async function jbfLogin(email, password) {
    try {
        const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password });
        if (error) throw error;
        return { success: true, data };
    } catch (err) {
        return { success: false, message: err.message };
    }
}

async function jbfRegister(email, password, fullName, phone, userType, companyName) {
    try {
        const { data, error } = await supabaseClient.auth.signUp({
            email,
            password,
            options: {
                data: {
                    full_name: fullName,
                    phone: phone,
                    user_type: userType || 'particulier',
                    company_name: companyName || '',
                    role: 'client'
                }
            }
        });
        if (error) throw error;
        return { success: true, data };
    } catch (err) {
        return { success: false, message: err.message };
    }
}

async function jbfLogout() {
    if (!supabaseClient) return;
    await supabaseClient.auth.signOut();
    window.location.href = '/auth/login.html';
}

async function jbfGetCurrentUser() {
    if (!supabaseClient) return null;
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) return null;
    
    const { data: profile } = await supabaseClient
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();
        
    return { ...user, profile };
}

// Services Helpers
async function jbfGetServices() {
    if (!supabaseClient) return getFallbackServices();
    const { data, error } = await supabaseClient
        .from('services')
        .select('*')
        .eq('active', true)
        .order('service_code', { ascending: true });
        
    if (error || !data || data.length === 0) return getFallbackServices();
    return data;
}

// Order & Mission Helpers
async function jbfCreateOrder(orderData) {
    if (!supabaseClient) return { success: false, message: "Client non initialise" };
    const user = await jbfGetCurrentUser();
    if (!user) return { success: false, message: "Veuillez vous connecter" };

    const orderNumber = "CMD-" + Date.now().toString().slice(-6);
    const { data, error } = await supabaseClient
        .from('orders')
        .insert([{
            order_number: orderNumber,
            client_id: user.id,
            service_id: orderData.service_id,
            title: orderData.title,
            description: orderData.description,
            location: orderData.location,
            attachments: orderData.attachments || []
        }])
        .select()
        .single();

    if (error) return { success: false, message: error.message };
    return { success: true, data };
}

async function jbfGetClientOrders() {
    const user = await jbfGetCurrentUser();
    if (!user || !supabaseClient) return [];
    
    const { data } = await supabaseClient
        .from('orders')
        .select('*, services(title, category)')
        .eq('client_id', user.id)
        .order('created_at', { ascending: false });
        
    return data || [];
}

// Realtime Notification Subscription
function jbfSubscribeNotifications(userId, onNotification) {
    if (!supabaseClient) return null;
    return supabaseClient
        .channel('public:notifications')
        .on('postgres_changes', {
            event: 'INSERT',
            schema: 'public',
            table: 'notifications',
            filter: `user_id=eq.${userId}`
        }, payload => {
            if (onNotification) onNotification(payload.new);
        })
        .subscribe();
}

// Fallback Services Data (Local offline guarantee)
function getFallbackServices() {
    return [
        { service_code: 1, title: "Fourniture de produits alimentaires", slug: "fourniture-produits-alimentaires", category: "Alimentaire", description: "Distribution et fourniture en gros et demi-gros de denrees alimentaires fraiches et seches pour entreprises, cantines et chantiers." },
        { service_code: 2, title: "Placement de ressources humaines dans les entreprises", slug: "placement-ressources-humaines", category: "RH & Recrutement", description: "Service de recrutement, selection et mise a disposition de personnel qualifie pour differents secteurs d activite." },
        { service_code: 3, title: "Prestations de sous-traitance dans le domaine alimentaire", slug: "sous-traitance-alimentaire", category: "Alimentaire", description: "Prise en charge complete ou partielle des operations de transformation, conditionnement et gestion alimentaire." },
        { service_code: 4, title: "Prestations de sous-traitance dans le domaine minier", slug: "sous-traitance-miniere", category: "Industrie & Mines", description: "Assistance operationnelle, logistique de chantier et sous-traitance technique pour les compagnies minieres." },
        { service_code: 5, title: "Prestations de service de maintenance", slug: "service-maintenance", category: "Maintenance", description: "Maintenance preventive et curative des installations electriques, mecaniques, batiments et equipements industriels." },
        { service_code: 6, title: "Soudure", slug: "soudure-industrielle", category: "Technique", description: "Travaux de soudure industrielle, charpente metallique, tuyauterie et reparation d equipements metalliques." },
        { service_code: 7, title: "Housekeeping et assainissement", slug: "housekeeping-assainissement", category: "Nettoyage & Hygiene", description: "Services de nettoyage professionnel, entretien des locaux, desinfection, gestion des dechets et assainissement." },
        { service_code: 8, title: "Construction et genie civil", slug: "construction-genie-civil", category: "BTP & Construction", description: "Realisation de travaux de construction, renovation de batiments, ouvrages de genie civil et amenagement." },
        { service_code: 9, title: "Restauration et agroalimentaire", slug: "restauration-agroalimentaire", category: "Alimentaire", description: "Service de catering, gestion de cantines d entreprises et preparation de repas pour grands effectifs." },
        { service_code: 10, title: "Jardinage", slug: "jardinage-espaces-verts", category: "Espaces Verts", description: "Amenagement, entretien des jardins, espaces verts, elagage et embellissement des espaces exterieurs d entreprises." },
        { service_code: 11, title: "Gardiennage", slug: "gardiennage-securite", category: "Securite", description: "Securisation des sites, gardiennage physique, controle d acces et surveillance d installations industrielles et privees." },
        { service_code: 12, title: "Depot (logistique et stockage)", slug: "depot-logistique-stockage", category: "Logistique", description: "Mise a disposition d espaces de stockage securises, gestion d entrepot et manutention de marchandises." },
        { service_code: 13, title: "Transport des biens et des personnes", slug: "transport-biens-personnes", category: "Transport", description: "Services de transport de personnel d entreprise, navettes, transport de fret et logistique de deplacement." },
        { service_code: 14, title: "Informatique", slug: "informatique-services-tech", category: "Technologies", description: "Support informatique, installation de reseaux, maintenance de parc informatique, securite et developpement de solutions." },
        { service_code: 15, title: "Livraison des consommables et pieces de rechanges", slug: "livraison-consommables-pieces", category: "Logistique & Approvisionnement", description: "Fourniture et livraison express de consommables de bureau, pieces de rechange industrielles et outillage." }
    ];
}
