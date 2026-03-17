import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/html_sanitizer.dart';
import '../utils/zoom_controller.dart';

/// WebView-based email content viewer with smart zoom.
///
/// Mirrors FairEmail's WebViewEx.java behavior:
/// - Pinch-to-zoom (built-in, no visible controls)
/// - Font size based on viewZoom + messageZoom
/// - Overview mode for fit-to-width
/// - Scale persistence per message
class EmailWebView extends StatefulWidget {
  final String messageId;
  final String htmlContent;
  final ZoomController zoomController;
  final bool showImages;

  const EmailWebView({
    super.key,
    required this.messageId,
    required this.htmlContent,
    required this.zoomController,
    this.showImages = false,
  });

  @override
  State<EmailWebView> createState() => _EmailWebViewState();
}

class _EmailWebViewState extends State<EmailWebView> {
  InAppWebViewController? _controller;
  double _contentHeight = 300;
  bool _loading = true;
  SanitizeReport? _report;

  @override
  void initState() {
    super.initState();
    widget.zoomController.addListener(_onZoomChanged);
    _report = HtmlSanitizer.analyze(widget.htmlContent);
  }

  @override
  void dispose() {
    widget.zoomController.removeListener(_onZoomChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(EmailWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlContent != widget.htmlContent) {
      _report = HtmlSanitizer.analyze(widget.htmlContent);
      _loadContent();
    }
    if (oldWidget.showImages != widget.showImages) {
      _loadContent();
    }
  }

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  void _onZoomChanged() {
    _loadContent();
  }

  /// Build platform-aware WebView settings.
  /// Some properties (builtInZoomControls, blockNetworkLoads, etc.)
  /// are Android-only. On macOS/iOS, WKWebView handles zoom natively
  /// and images are controlled via CSS/sanitization instead.
  InAppWebViewSettings _buildSettings() {
    final settings = InAppWebViewSettings(
      // Cross-platform settings
      supportZoom: true,
      javaScriptEnabled: false,
      transparentBackground: true,
      verticalScrollBarEnabled: false,
      horizontalScrollBarEnabled: false,
    );

    if (_isAndroid) {
      // Android-only (WebView/Chromium)
      settings.builtInZoomControls = true;
      settings.displayZoomControls = false;
      settings.useWideViewPort = true;
      settings.loadWithOverviewMode = widget.zoomController.overviewMode;
      settings.textZoom = widget.zoomController.textZoomPercent;
      settings.allowFileAccess = false;
      settings.blockNetworkLoads = !widget.showImages;
      settings.blockNetworkImage = !widget.showImages;
      settings.mixedContentMode =
          MixedContentMode.MIXED_CONTENT_NEVER_ALLOW;
      settings.overScrollMode = OverScrollMode.OVER_SCROLL_NEVER;
    }
    // macOS/iOS: WKWebView handles pinch-to-zoom natively.
    // Font size is controlled via CSS (already in _buildHtml).
    // Image blocking is handled by the sanitizer.

    return settings;
  }

  String _buildHtml() {
    final sanitized = HtmlSanitizer.sanitize(
      widget.htmlContent,
      allowImages: widget.showImages,
    );

    final fontSize = widget.zoomController.effectiveFontSize.round();
    final overviewMeta = widget.zoomController.overviewMode
        ? '<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">'
        : '<meta name="viewport" content="width=device-width, user-scalable=yes">';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  $overviewMeta
  <style>
    body {
      font-size: ${fontSize}px;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      padding: 8px;
      margin: 0;
      word-wrap: break-word;
      overflow-wrap: break-word;
      color: #1a1a1a;
      line-height: 1.5;
    }
    img {
      max-width: 100%;
      height: auto;
    }
    pre, code {
      white-space: pre-wrap;
      font-size: 0.9em;
    }
    table {
      max-width: 100%;
      border-collapse: collapse;
    }
    blockquote {
      border-left: 3px solid #ccc;
      margin: 8px 0;
      padding: 4px 12px;
      color: #555;
    }
    a {
      color: #1a73e8;
    }
  </style>
</head>
<body>
$sanitized
</body>
</html>
''';
  }

  void _loadContent() {
    final html = _buildHtml();
    _controller?.loadData(
      data: html,
      mimeType: 'text/html',
      encoding: 'utf-8',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sanitization warning banner
        if (_report != null && !_report!.isClean) _buildSanitizeBanner(),

        // WebView
        SizedBox(
          height: _contentHeight.clamp(100, 2000),
          child: Stack(
            children: [
              InAppWebView(
                initialData: InAppWebViewInitialData(
                  data: _buildHtml(),
                  mimeType: 'text/html',
                  encoding: 'utf-8',
                ),
                initialSettings: _buildSettings(),
                onWebViewCreated: (controller) {
                  _controller = controller;
                },
                onLoadStop: (controller, url) async {
                  // Auto-size height to content
                  final height = await controller.evaluateJavascript(
                    source: 'document.body.scrollHeight',
                  );
                  if (height != null && mounted) {
                    setState(() {
                      _contentHeight = (height as num).toDouble() + 16;
                      _loading = false;
                    });
                  }
                },
                onScaleChanged: (controller, oldScale, newScale) {
                  // Persist scale per message (like AdapterMessage onScaleChanged)
                  widget.zoomController.setMessageScale(
                    widget.messageId,
                    newScale,
                  );
                },
                shouldOverrideUrlLoading: (controller, action) async {
                  // Block all navigation — email links should open externally
                  return NavigationActionPolicy.CANCEL;
                },
              ),
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSanitizeBanner() {
    final report = _report!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(
          left: BorderSide(color: Colors.orange.shade400, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.security, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${report.totalThreats} élément(s) dangereux supprimé(s)',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
            ),
          ),
          InkWell(
            onTap: () => _showSanitizeDetails(report),
            child: Icon(Icons.info_outline,
                size: 16, color: Colors.orange.shade700),
          ),
        ],
      ),
    );
  }

  void _showSanitizeDetails(SanitizeReport report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rapport de sécurité'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report.removedElements.isNotEmpty) ...[
              const Text('Éléments supprimés:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...report.removedElements.entries.map((e) => Text(
                  '  <${e.key}> x${e.value}',
                  style: const TextStyle(fontFamily: 'monospace'))),
              const SizedBox(height: 8),
            ],
            if (report.removedAttributes.isNotEmpty) ...[
              const Text('Attributs dangereux:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...report.removedAttributes.map((a) => Text('  $a',
                  style: const TextStyle(fontFamily: 'monospace'))),
              const SizedBox(height: 8),
            ],
            if (report.blockedUrls.isNotEmpty) ...[
              const Text('URLs bloquées:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...report.blockedUrls.map((u) => Text('  $u',
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 11))),
              const SizedBox(height: 8),
            ],
            if (report.trackingPixels > 0)
              Text('Pixels de tracking: ${report.trackingPixels}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
