import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'portal_config.dart';

class PortalApp extends StatelessWidget {
  const PortalApp({super.key, required this.config});

  final PortalConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(PortalConfig.brandPink),
          primary: const Color(PortalConfig.brandPink),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(PortalConfig.brandPink),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: PortalHomePage(config: config),
    );
  }
}

class PortalHomePage extends StatefulWidget {
  const PortalHomePage({super.key, required this.config});

  final PortalConfig config;

  @override
  State<PortalHomePage> createState() => _PortalHomePageState();
}

class _PortalHomePageState extends State<PortalHomePage> {
  InAppWebViewController? _webController;
  double _progress = 0;
  String? _lastError;
  bool _canGoBack = false;

  PortalConfig get config => widget.config;

  Future<void> _openExternal(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(config.appName),
        actions: [
          IconButton(
            tooltip: 'Accueil portail',
            onPressed: () => _webController?.loadUrl(
              urlRequest: URLRequest(url: WebUri(config.startUrl)),
            ),
            icon: const Icon(Icons.home_outlined),
          ),
          IconButton(
            tooltip: 'Retour',
            onPressed: _canGoBack ? () => _webController?.goBack() : null,
            icon: const Icon(Icons.arrow_back),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: () => _webController?.reload(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_progress > 0 && _progress < 1)
            LinearProgressIndicator(
              value: _progress,
              minHeight: 3,
              color: const Color(PortalConfig.brandPink),
            ),
          if (_lastError != null)
            Material(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lastError!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _lastError = null);
                        _webController?.reload();
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(config.startUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                useHybridComposition: true,
                allowsInlineMediaPlayback: true,
                mediaPlaybackRequiresUserGesture: false,
                transparentBackground: true,
                isInspectable: kDebugMode,
              ),
              onWebViewCreated: (controller) {
                _webController = controller;
              },
              onProgressChanged: (_, progress) {
                setState(() => _progress = progress / 100);
              },
              onReceivedError: (_, request, error) {
                if (request.isForMainFrame != true) return;
                setState(() {
                  _lastError =
                      'Chargement impossible (${error.type}). Vérifiez votre connexion.';
                });
                debugPrint('[JBF WebView] ${error.description}');
              },
              onUpdateVisitedHistory: (_, __, isReload) async {
                final back = await _webController?.canGoBack() ?? false;
                if (mounted) setState(() => _canGoBack = back);
              },
              shouldOverrideUrlLoading: (controller, action) async {
                final uri = action.request.url;
                if (uri == null) return NavigationActionPolicy.ALLOW;
                final scheme = uri.scheme.toLowerCase();
                if (scheme == 'http' || scheme == 'https') {
                  return NavigationActionPolicy.ALLOW;
                }
                if (scheme == 'mailto' || scheme == 'tel') {
                  await _openExternal(Uri.parse(uri.toString()));
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.CANCEL;
              },
            ),
          ),
        ],
      ),
    );
  }
}
