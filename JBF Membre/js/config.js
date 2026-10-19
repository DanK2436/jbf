const JBF_MEMBER_CONFIG = {
  SUPABASE_URL: window.ENV_SUPABASE_URL || 'https://dvzwqxcaiagczyonrhsg.supabase.co',
  SUPABASE_ANON_KEY: window.ENV_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2endxeGNhaWFnY3p5b25yaHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1ODEzNzIsImV4cCI6MjEwNTE1NzM3Mn0.uam5Z-d6SWS9-4Ly9f0ircJPryFJwOXbNp9_alHHl-o',
  /** Clé de synchro création collaborateur → table member_portal_accounts (RPC Supabase). */
  MEMBER_SYNC_KEY: window.ENV_MEMBER_SYNC_KEY || 'jbf-member-sync-v1'
};
window.JBF_MEMBER_CONFIG = JBF_MEMBER_CONFIG;
