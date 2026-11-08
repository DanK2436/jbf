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

  static const brandPink = 0xFFE6007E; // 20% Rose logo officiel JBF Service
  static const grayDominant = 0xFFAAAAAA; // 60% Gris de structure
  static const grayFooter = 0xFF404048; // Gris corporatif unifié pour pied de page
  static const whiteSurface = 0xFFFFFFFF; // 15% Blanc de contraste
  static const blackTypography = 0xFF0C0C0E; // 5% Noir de lisibilité
  static const brandPinkDark = 0xFFC4006B;

  /// Admin — connexion supervision
  factory PortalConfig.admin({String? baseUrl}) {
    final base = baseUrl ?? 'https://dank2436.github.io/jbf';
    return PortalConfig(
      appName: 'JBF Service Admin',
      githubPagesBase: base,
      startUrl: '$base/JBF%20Admin/auth/login.html',
    );
  }

  /// Membre — espace collaborateur
  factory PortalConfig.membre({String? baseUrl}) {
    final base = baseUrl ?? 'https://dank2436.github.io/jbf';
    return PortalConfig(
      appName: 'JBF Service Membre',
      githubPagesBase: base,
      startUrl: '$base/JBF%20Membre/auth/login.html',
    );
  }

  /// Client — espace partenaire / devis
  factory PortalConfig.client({String? baseUrl}) {
    final base = baseUrl ?? 'https://dank2436.github.io/jbf';
    return PortalConfig(
      appName: 'JBF Service Client',
      githubPagesBase: base,
      startUrl: '$base/JBF%20Client/auth/login.html',
    );
  }
}
