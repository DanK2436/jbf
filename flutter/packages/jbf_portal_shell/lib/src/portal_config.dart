/// Configuration d'une application portail JBF (WebView vers GitHub Pages ou URL custom).
class PortalConfig {
  const PortalConfig({
    required this.appName,
    required this.startUrl,
    this.githubPagesBase = 'https://dank2436.github.io/jbf',
  });

  final String appName;
  final String startUrl;
  final String githubPagesBase;

  static const brandPink = 0xFFE6007E;
  static const brandPinkDark = 0xFF9E1A59;

  /// Admin — connexion supervision
  factory PortalConfig.admin({String? baseUrl}) {
    final base = baseUrl ?? 'https://dank2436.github.io/jbf';
    return PortalConfig(
      appName: 'JBF Admin',
      githubPagesBase: base,
      startUrl: '$base/JBF%20Admin/auth/login.html',
    );
  }

  /// Membre — espace collaborateur
  factory PortalConfig.membre({String? baseUrl}) {
    final base = baseUrl ?? 'https://dank2436.github.io/jbf';
    return PortalConfig(
      appName: 'JBF Membre',
      githubPagesBase: base,
      startUrl: '$base/JBF%20Membre/auth/login.html',
    );
  }

  /// Client — espace partenaire / devis
  factory PortalConfig.client({String? baseUrl}) {
    final base = baseUrl ?? 'https://dank2436.github.io/jbf';
    return PortalConfig(
      appName: 'JBF Client',
      githubPagesBase: base,
      startUrl: '$base/JBF%20Client/auth/login.html',
    );
  }
}
