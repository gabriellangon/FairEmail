import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/email_message.dart';
import '../utils/zoom_controller.dart';
import '../widgets/security_indicators.dart';
import 'email_detail_screen.dart';

/// Main screen showing a list of sample emails.
class EmailListScreen extends StatefulWidget {
  final ZoomController zoomController;

  const EmailListScreen({super.key, required this.zoomController});

  @override
  State<EmailListScreen> createState() => _EmailListScreenState();
}

class _EmailListScreenState extends State<EmailListScreen> {
  late List<EmailMessage> _emails;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEmails();
  }

  Future<void> _loadEmails() async {
    final simpleHtml =
        await rootBundle.loadString('assets/emails/email_simple.html');
    final newsletterHtml =
        await rootBundle.loadString('assets/emails/email_newsletter.html');
    final maliciousHtml =
        await rootBundle.loadString('assets/emails/email_malicious.html');

    setState(() {
      _emails = [
        EmailMessage(
          id: '1',
          from: 'support@example.com',
          subject: 'Bienvenue sur notre plateforme !',
          date: '16 mars 2026, 10:30',
          htmlBody: simpleHtml,
          dkim: true,
          spf: true,
          dmarc: true,
          tls: true,
          signedBy: 'example.com',
          encryptionType: EncryptionType.smimeSignOnly,
          verified: true,
        ),
        EmailMessage(
          id: '2',
          from: 'newsletter@techweekly.io',
          subject: 'Newsletter Tech - Mars 2026',
          date: '15 mars 2026, 08:00',
          htmlBody: newsletterHtml,
          dkim: true,
          spf: true,
          dmarc: true,
          tls: true,
          signedBy: 'techweekly.io',
        ),
        EmailMessage(
          id: '3',
          from: 'security@my-bank-verify.xyz',
          subject: 'URGENT: Vérifiez votre compte !',
          date: '14 mars 2026, 23:45',
          htmlBody: maliciousHtml,
          dkim: false,
          spf: false,
          dmarc: false,
          tls: false,
        ),
        const EmailMessage(
          id: '4',
          from: 'alice@protonmail.com',
          subject: 'Document confidentiel (chiffré)',
          date: '13 mars 2026, 14:20',
          htmlBody: '<html><body><p>Ce message est chiffré avec PGP.</p>'
              '<p>Le contenu original nécessite votre clé privée pour être déchiffré.</p>'
              '<pre>-----BEGIN PGP MESSAGE-----\n'
              'hQEMA7K...\n'
              '-----END PGP MESSAGE-----</pre></body></html>',
          dkim: true,
          spf: true,
          dmarc: true,
          tls: true,
          signedBy: 'protonmail.com',
          encryptionType: EncryptionType.pgpSignEncrypt,
          verified: true,
        ),
        const EmailMessage(
          id: '5',
          from: 'noreply@updates.service.com',
          subject: 'Votre facture de février',
          date: '12 mars 2026, 09:00',
          htmlBody: '<html><body><h3>Facture #2026-0212</h3>'
              '<p>Montant: <b>42,50 EUR</b></p>'
              '<table border="1" cellpadding="8" cellspacing="0">'
              '<tr><td>Service Premium</td><td>29,99 EUR</td></tr>'
              '<tr><td>Support étendu</td><td>12,51 EUR</td></tr>'
              '<tr><td><b>Total</b></td><td><b>42,50 EUR</b></td></tr>'
              '</table>'
              '<p>Merci pour votre confiance.</p></body></html>',
          dkim: true,
          spf: null,
          dmarc: null,
          tls: true,
        ),
      ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boîte de réception'),
        actions: [
          // Zoom cycle button (like FairEmail's menu_zoom)
          IconButton(
            icon: _buildZoomIcon(),
            tooltip: 'Zoom: ${widget.zoomController.viewZoomLabel}',
            onPressed: () {
              widget.zoomController.cycleViewZoom();
              setState(() {});
            },
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _emails.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final email = _emails[index];
          return _EmailListTile(
            email: email,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EmailDetailScreen(
                  email: email,
                  zoomController: widget.zoomController,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildZoomIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.format_size),
        Positioned(
          right: 0,
          bottom: 0,
          child: Text(
            '+' * widget.zoomController.viewZoom,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _EmailListTile extends StatelessWidget {
  final EmailMessage email;
  final VoidCallback onTap;

  const _EmailListTile({required this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnauthenticated = email.hasAuthFailure;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isUnauthenticated ? Colors.red.shade100 : Colors.blue.shade100,
        child: Icon(
          email.isEncrypted
              ? Icons.lock
              : isUnauthenticated
                  ? Icons.warning
                  : Icons.mail,
          color: isUnauthenticated ? Colors.red : Colors.blue,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              email.from,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isUnauthenticated ? Colors.red.shade700 : null,
              ),
            ),
          ),
          SecurityIndicators(message: email),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(email.subject, overflow: TextOverflow.ellipsis),
          Text(email.date,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
      isThreeLine: true,
      onTap: onTap,
    );
  }
}
