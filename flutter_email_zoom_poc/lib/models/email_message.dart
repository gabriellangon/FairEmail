/// Model representing an email message with security metadata.
/// Mirrors the key fields from FairEmail's EntityMessage.java.
class EmailMessage {
  final String id;
  final String from;
  final String subject;
  final String date;
  final String htmlBody;

  // Authentication results (like FairEmail's dkim/spf/dmarc/auth fields)
  final bool? dkim;
  final bool? spf;
  final bool? dmarc;
  final bool? tls;
  final String? signedBy;

  // Encryption status (mirrors EntityMessage encrypt constants)
  final EncryptionType? encryptionType;
  final bool verified;

  const EmailMessage({
    required this.id,
    required this.from,
    required this.subject,
    required this.date,
    required this.htmlBody,
    this.dkim,
    this.spf,
    this.dmarc,
    this.tls,
    this.signedBy,
    this.encryptionType,
    this.verified = false,
  });

  /// Whether the message is signed (PGP or S/MIME).
  bool get isSigned =>
      encryptionType == EncryptionType.pgpSignOnly ||
      encryptionType == EncryptionType.smimeSignOnly;

  /// Whether the message is encrypted.
  bool get isEncrypted =>
      encryptionType == EncryptionType.pgpSignEncrypt ||
      encryptionType == EncryptionType.smimeSignEncrypt;

  /// Authentication score (0-4), same logic as AdapterMessage.java lines 1440-1459.
  int get authScore {
    int auths = (dkim == true ? 1 : 0) +
        (spf == true ? 1 : 0) +
        (dmarc == true ? 1 : 0);

    // DMARC alignment bonus (like FairEmail)
    if (dmarc == true && (dkim == true || spf == true)) {
      auths = 4;
    }

    return auths;
  }

  /// Whether authentication has failed on any check.
  bool get hasAuthFailure =>
      dkim == false || spf == false || dmarc == false;
}

/// Mirrors FairEmail's EntityMessage encryption constants.
enum EncryptionType {
  pgpSignEncrypt,  // 1
  pgpSignOnly,     // 2
  smimeSignEncrypt, // 3
  smimeSignOnly,    // 4
}
