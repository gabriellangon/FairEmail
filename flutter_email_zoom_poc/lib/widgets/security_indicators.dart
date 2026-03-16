import 'package:flutter/material.dart';
import '../models/email_message.dart';

/// Displays email security indicators in a row.
///
/// Mirrors FairEmail's AdapterMessage.java security icons:
/// ibAuth, ibVerified, ibSigned, ibEncrypted.
class SecurityIndicators extends StatelessWidget {
  final EmailMessage message;
  final VoidCallback? onAuthTap;

  const SecurityIndicators({
    super.key,
    required this.message,
    this.onAuthTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Authentication indicator (DKIM/SPF/DMARC)
        _AuthIcon(message: message, onTap: onAuthTap),
        // Signature indicator
        if (message.isSigned) _SignedIcon(verified: message.verified),
        // Encryption indicator
        if (message.isEncrypted) _EncryptedIcon(),
        // TLS indicator
        if (message.tls != null) _TlsIcon(secure: message.tls!),
      ],
    );
  }
}

/// Authentication icon with 7 levels (mirrors drawable/authenticated.xml).
class _AuthIcon extends StatelessWidget {
  final EmailMessage message;
  final VoidCallback? onTap;

  const _AuthIcon({required this.message, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (message.dkim == null &&
        message.spf == null &&
        message.dmarc == null) {
      return const SizedBox.shrink();
    }

    final hasFailure = message.hasAuthFailure;
    final score = message.authScore;

    // Icon and color logic matching AdapterMessage.java lines 1434-1464
    IconData icon;
    Color color;

    if (hasFailure) {
      icon = Icons.flag_rounded;
      color = Colors.red;
    } else if (score >= 4) {
      icon = Icons.verified_user;
      color = Colors.green;
    } else if (score >= 2) {
      icon = Icons.gpp_maybe;
      color = Colors.orange;
    } else if (score >= 1) {
      icon = Icons.gpp_bad;
      color = Colors.deepOrange;
    } else {
      icon = Icons.help_outline;
      color = Colors.grey;
    }

    return Tooltip(
      message: _buildTooltip(),
      child: InkWell(
        onTap: onTap ?? () => _showAuthDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  String _buildTooltip() {
    final parts = <String>[];
    if (message.dkim != null) {
      parts.add('DKIM: ${message.dkim! ? '✓' : '✗'}');
    }
    if (message.spf != null) {
      parts.add('SPF: ${message.spf! ? '✓' : '✗'}');
    }
    if (message.dmarc != null) {
      parts.add('DMARC: ${message.dmarc! ? '✓' : '✗'}');
    }
    return parts.join(' | ');
  }

  void _showAuthDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Authentification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _authRow('DKIM', message.dkim),
            _authRow('SPF', message.spf),
            _authRow('DMARC', message.dmarc),
            _authRow('TLS', message.tls),
            if (message.signedBy != null) ...[
              const SizedBox(height: 8),
              Text('Signé par: ${message.signedBy}',
                  style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Widget _authRow(String label, bool? value) {
    final icon = value == null
        ? const Icon(Icons.remove, size: 16, color: Colors.grey)
        : value
            ? const Icon(Icons.check_circle, size: 16, color: Colors.green)
            : const Icon(Icons.cancel, size: 16, color: Colors.red);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            value == null ? '-' : (value ? 'Pass' : 'Fail'),
            style: TextStyle(
              color: value == null
                  ? Colors.grey
                  : (value ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedIcon extends StatelessWidget {
  final bool verified;
  const _SignedIcon({required this.verified});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: verified ? 'Signature vérifiée' : 'Signé (non vérifié)',
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          Icons.gesture,
          size: 20,
          color: verified ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}

class _EncryptedIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Tooltip(
      message: 'Message chiffré',
      child: Padding(
        padding: EdgeInsets.all(2),
        child: Icon(Icons.lock, size: 20, color: Colors.green),
      ),
    );
  }
}

class _TlsIcon extends StatelessWidget {
  final bool secure;
  const _TlsIcon({required this.secure});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: secure ? 'Connexion TLS' : 'Pas de TLS',
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          secure ? Icons.shield : Icons.shield_outlined,
          size: 18,
          color: secure ? Colors.blue : Colors.orange,
        ),
      ),
    );
  }
}
