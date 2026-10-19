import 'dart:convert';

/// Secrets / URLs injectés au build (`--dart-define`) et dans la WebView admin.
class PortalRuntime {
  const PortalRuntime({
    this.portalBase = '',
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.memberSyncKey = '',
    this.messageNotifications = false,
  });

  final String portalBase;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String memberSyncKey;
  final bool messageNotifications;

  /// Valeurs par défaut alignées sur `JBF Admin/js/config.js` (clé anon publique Supabase).
  static const defaultSupabaseUrl =
      'https://dvzwqxcaiagczyonrhsg.supabase.co';
  static const defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2endxeGNhaWFnY3p5b25yaHNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1ODEzNzIsImV4cCI6MjEwNTE1NzM3Mn0.uam5Z-d6SWS9-4Ly9f0ircJPryFJwOXbNp9_alHHl-o';
  static const defaultMemberSyncKey = 'jbf-member-sync-v1';

  factory PortalRuntime.fromEnvironment({required bool adminApp}) {
    const base = String.fromEnvironment('JBF_PORTAL_BASE');
    const url = String.fromEnvironment(
      'JBF_SUPABASE_URL',
      defaultValue: defaultSupabaseUrl,
    );
    const key = String.fromEnvironment(
      'JBF_SUPABASE_ANON_KEY',
      defaultValue: defaultSupabaseAnonKey,
    );
    const sync = String.fromEnvironment(
      'JBF_MEMBER_SYNC_KEY',
      defaultValue: defaultMemberSyncKey,
    );
    const notify = bool.fromEnvironment(
      'JBF_ADMIN_MESSAGE_NOTIFICATIONS',
      defaultValue: true,
    );
    return PortalRuntime(
      portalBase: base,
      supabaseUrl: url,
      supabaseAnonKey: key,
      memberSyncKey: sync,
      messageNotifications: adminApp && notify,
    );
  }

  bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  String get configInjectionJavaScript {
    if (!hasSupabase) return '';
    return '''
(function(){
  window.ENV_SUPABASE_URL = ${jsonEncode(supabaseUrl)};
  window.ENV_SUPABASE_ANON_KEY = ${jsonEncode(supabaseAnonKey)};
  window.ENV_MEMBER_SYNC_KEY = ${jsonEncode(memberSyncKey)};
})();
''';
  }
}
