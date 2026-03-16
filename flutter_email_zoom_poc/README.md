# Flutter Email Zoom POC

Proof of concept implementing FairEmail-equivalent smart zoom and email security display in Flutter.

## Features

### Smart Zoom (mirrors FairEmail's WebViewEx.java + AdapterMessage.java)
- **3-level view zoom** (Petit/Normal/Grand) — cycles via toolbar button
- **Continuous message zoom** (50%-250%) — via slider in bottom sheet
- **Pinch-to-zoom** — native WebView gesture, scale persisted per message
- **Overview mode** — fit-to-width toggle
- Font size = `16px * viewZoomFactor * messageZoom%`

### HTML Sanitization (mirrors FairEmail's HtmlHelper.java)
- Removes `<script>`, `<iframe>`, `<form>`, `<input>`, event handlers
- Blocks `javascript:` URLs
- Removes tracking pixels (1x1 images)
- Blocks external images by default (toggle to show)
- Visual report of sanitized threats

### Email Security Display (mirrors FairEmail's AdapterMessage.java)
- **Authentication indicators**: DKIM/SPF/DMARC status with color-coded icons
- **Signature badge**: PGP or S/MIME, verified or not
- **Encryption lock**: visible for encrypted messages
- **TLS indicator**: connection security
- **Extended headers**: monospace auth results (DKIM=✓ SPF=✗ DMARC=✓)
- **Auth score** (0-4): same algorithm as FairEmail

## Sample Emails

| Email | Auth | Security | Purpose |
|-------|------|----------|---------|
| Simple welcome | DKIM+SPF+DMARC ✓ | S/MIME signed+verified | Clean email |
| Newsletter | DKIM+SPF+DMARC ✓ | None | Rich HTML tables |
| Phishing | DKIM+SPF+DMARC ✗ | None | Sanitizer demo |
| Encrypted | DKIM+SPF+DMARC ✓ | PGP encrypted | Encryption UI |
| Invoice | DKIM only | None | Partial auth |

## Running

```bash
cd flutter_email_zoom_poc
flutter pub get
flutter run
```

## Architecture

```
lib/
├── main.dart                       # App entry point
├── models/
│   └── email_message.dart          # Email model with security fields
├── utils/
│   ├── html_sanitizer.dart         # HTML cleaning (XSS, tracking, etc.)
│   └── zoom_controller.dart        # Multi-level zoom state management
├── widgets/
│   ├── email_webview.dart          # WebView with zoom + sanitization
│   ├── security_indicators.dart    # Auth/sign/encrypt icons
│   └── zoom_controls.dart          # Bottom sheet zoom UI
└── screens/
    ├── email_list_screen.dart      # Inbox with security indicators
    └── email_detail_screen.dart    # Full email view with zoom
```
