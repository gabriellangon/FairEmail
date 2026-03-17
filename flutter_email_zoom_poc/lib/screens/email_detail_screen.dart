import 'package:flutter/material.dart';
import '../models/email_message.dart';
import '../utils/zoom_controller.dart';
import '../widgets/email_webview.dart';
import '../widgets/security_indicators.dart';
import '../widgets/zoom_controls.dart';

/// Detail screen for viewing a single email with zoom and security info.
class EmailDetailScreen extends StatefulWidget {
  final EmailMessage email;
  final ZoomController zoomController;

  const EmailDetailScreen({
    super.key,
    required this.email,
    required this.zoomController,
  });

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen> {
  bool _showImages = false;
  bool _showHeaders = false;

  @override
  void initState() {
    super.initState();
    widget.zoomController.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.zoomController.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email;

    return Scaffold(
      appBar: AppBar(
        title: Text(email.subject, overflow: TextOverflow.ellipsis),
        actions: [
          // Zoom cycle button
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'Zoom: ${widget.zoomController.viewZoomLabel}',
            onPressed: widget.zoomController.cycleViewZoom,
          ),
          // Zoom settings
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Paramètres de zoom',
            onPressed: () => _showZoomControls(context),
          ),
          // Toggle images
          IconButton(
            icon: Icon(
              _showImages ? Icons.image : Icons.image_not_supported,
            ),
            tooltip: _showImages ? 'Masquer les images' : 'Afficher les images',
            onPressed: () => setState(() => _showImages = !_showImages),
          ),
        ],
      ),
      body: Column(
        children: [
          // Email header with security info
          _buildHeader(email),

          // Extended headers (DKIM/SPF/DMARC details)
          if (_showHeaders) _buildExtendedHeaders(email),

          const Divider(height: 1),

          // Email body WebView with zoom
          Expanded(
            child: EmailWebView(
              messageId: email.id,
              htmlContent: email.htmlBody,
              zoomController: widget.zoomController,
              showImages: _showImages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(EmailMessage email) {
    return InkWell(
      onTap: () => setState(() => _showHeaders = !_showHeaders),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    email.from,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                SecurityIndicators(message: email),
                Icon(
                  _showHeaders ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              email.subject,
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              email.date,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  /// Extended headers showing auth results.
  /// Mirrors AdapterMessage.java lines 2907-2909 text display.
  Widget _buildExtendedHeaders(EmailMessage email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auth results row (like FairEmail's DKIM=✓ SPF=✓ DMARC=✓)
          Text(
            'DKIM=${_authSymbol(email.dkim)} '
            'SPF=${_authSymbol(email.spf)} '
            'DMARC=${_authSymbol(email.dmarc)}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
          if (email.tls != null)
            Text(
              'TLS=${_authSymbol(email.tls)}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          if (email.signedBy != null)
            Text(
              'Signé par: ${email.signedBy}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          if (email.isSigned)
            Text(
              'Signature: ${email.encryptionType == EncryptionType.pgpSignOnly ? 'PGP' : 'S/MIME'}'
              ' ${email.verified ? '(vérifiée)' : '(non vérifiée)'}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          if (email.isEncrypted)
            Text(
              'Chiffrement: ${email.encryptionType == EncryptionType.pgpSignEncrypt ? 'PGP' : 'S/MIME'}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),

          // Zoom info
          const SizedBox(height: 4),
          Text(
            'Zoom: ${widget.zoomController.viewZoomLabel} '
            '| Texte: ${widget.zoomController.messageZoom}% '
            '| Pince: ${(widget.zoomController.getMessageScale(email.id) ?? 1.0).toStringAsFixed(2)}x '
            '| Taille effective: ${widget.zoomController.effectiveFontSizeForMessage(email.id).toStringAsFixed(1)}px',
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  String _authSymbol(bool? value) {
    if (value == null) return '-';
    return value ? '✓' : '✗';
  }

  void _showZoomControls(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ZoomControlsSheet(controller: widget.zoomController),
    );
  }
}
