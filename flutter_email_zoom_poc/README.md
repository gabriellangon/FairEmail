# Flutter Email Zoom POC

## Contexte et objectif

**FairEmail** est un client email Android open-source reconnu pour sa sécurité et son ergonomie. Ce POC (proof of concept) reproduit en **Flutter** trois fonctionnalités clés de FairEmail, afin de valider qu'on peut les porter dans une app Flutter cross-platform (Android + iOS + macOS) avec un comportement équivalent.

L'objectif est de permettre à un développeur Flutter de construire un client email qui offre le même niveau de contrôle du zoom, de sécurité HTML et d'indicateurs d'authentification que FairEmail, **sans avoir besoin de lire le code source Java de FairEmail**.

### Ce que ce POC valide

1. **Le système de zoom multi-niveaux** fonctionne en Flutter via WebView
2. **La sanitisation HTML** protège contre XSS, tracking et contenu malveillant
3. **Les indicateurs de sécurité email** (DKIM/SPF/DMARC, signature, chiffrement) sont affichables dans une UI Flutter
4. **Le cross-platform** : le même code tourne sur Android (Chromium WebView) et iOS/macOS (WKWebView) avec des adaptations conditionnelles

## Fonctionnalités détaillées

### 1. Smart Zoom (3 axes indépendants)

FairEmail propose un système de zoom inhabituel à 3 axes. Ce POC le reproduit fidèlement :

| Axe | Contrôle | Valeurs | Persistance |
|-----|----------|---------|-------------|
| **View Zoom** | Bouton toolbar (cycle) | Petit (×0.8) / Normal (×1.0) / Grand (×1.25) | SharedPreferences |
| **Message Zoom** | Slider dans bottom sheet | 50% – 250% (continu) | SharedPreferences |
| **Pinch-to-zoom** | Geste natif WebView | Libre | En mémoire, par message |

**Formule finale** : `font-size = 16px × viewZoomFactor × (messageZoom / 100)`

Le View Zoom et Message Zoom sont **globaux** (s'appliquent à tous les messages). Le pinch-to-zoom est **par message** (chaque email garde son échelle).

Il y a aussi un **mode Overview** (fit-to-width) qui redimensionne le contenu pour tenir dans la largeur de l'écran.

**Fichiers sources FairEmail de référence** :
- `WebViewEx.java` lignes 87-88 (zoom WebView), 145-153 (calcul font size)
- `AdapterMessage.java` (onScaleChanged, persistance)
- `FragmentMessages.java` (onMenuZoom, cycle 0→1→2→0)

### 2. Sanitisation HTML (sécurité email)

Les emails HTML sont un vecteur d'attaque courant (XSS, tracking, phishing). Ce POC implémente un sanitiseur qui :

- **Supprime** les balises dangereuses : `<script>`, `<iframe>`, `<object>`, `<embed>`, `<form>`, `<input>`
- **Supprime** les attributs event handlers : `onclick`, `onload`, `onerror`, etc.
- **Bloque** les URLs `javascript:`
- **Détecte et supprime** les pixels de tracking (images 1×1)
- **Bloque les images externes** par défaut (l'utilisateur peut choisir de les afficher)
- **Affiche un rapport visuel** : bandeau orange avec le nombre de menaces supprimées, et un dialog de détail

**Important** : le JavaScript est **désactivé** dans le WebView (`javaScriptEnabled: false`). C'est un choix de sécurité volontaire — on n'exécute jamais de JS provenant des emails.

**Fichier source FairEmail de référence** : `HtmlHelper.java`

### 3. Indicateurs de sécurité email

Chaque email affiche ses indicateurs d'authentification et de chiffrement :

| Indicateur | Ce qu'il montre | Affichage |
|-----------|----------------|-----------|
| **DKIM** | Signature du domaine expéditeur | Icône verte (✓) ou rouge (✗) |
| **SPF** | Autorisation du serveur d'envoi | Icône verte (✓) ou rouge (✗) |
| **DMARC** | Politique d'alignement DKIM+SPF | Icône verte (✓) ou rouge (✗) |
| **TLS** | Connexion chiffrée lors du transport | Icône cadenas |
| **Signature** | PGP ou S/MIME, vérifiée ou non | Badge avec statut |
| **Chiffrement** | PGP ou S/MIME | Icône cadenas fermé |

**Score d'authentification** (0-4) : même algorithme que FairEmail :
- +1 pour chaque check passé (DKIM, SPF, DMARC)
- Score = 4 si DMARC ✓ ET (DKIM ✓ OU SPF ✓) — bonus d'alignement

**Fichier source FairEmail de référence** : `AdapterMessage.java` lignes 1440-1459

## Emails de démonstration

Le POC inclut 5 emails fictifs qui couvrent les cas d'usage principaux :

| Email | Auth | Sécurité | Sert à tester |
|-------|------|----------|---------------|
| Simple welcome | DKIM+SPF+DMARC ✓ | S/MIME signé+vérifié | Email propre, tous les indicateurs verts |
| Newsletter | DKIM+SPF+DMARC ✓ | Aucune | HTML riche avec tableaux, test du zoom |
| Phishing | DKIM+SPF+DMARC ✗ | Aucune | Sanitiseur en action (scripts, tracking) |
| Encrypted | DKIM+SPF+DMARC ✓ | PGP chiffré | UI de chiffrement |
| Invoice | DKIM seul | Aucune | Auth partielle (1/3) |

## Platforms

| Plateforme | Moteur WebView | Zoom | Notes |
|-----------|---------------|------|-------|
| Android | Chromium WebView | `builtInZoomControls` + `textZoom` + pinch | Parité complète avec FairEmail |
| iOS | WKWebView | CSS `font-size` + pinch natif | Blocage images via sanitiseur |
| macOS | WKWebView | CSS `font-size` + pinch natif | Nécessite entitlements sandbox |

### Différences Android vs iOS/macOS

Certaines propriétés de `InAppWebViewSettings` sont Android-only (`builtInZoomControls`, `blockNetworkLoads`, `textZoom`, `overScrollMode`). Sur iOS/macOS :
- Le **zoom** est géré par CSS `font-size` (déjà calculé dans `_buildHtml()`) + pinch natif WKWebView
- Le **blocage d'images** est géré par le sanitiseur HTML (suppression des `src`) plutôt que par `blockNetworkLoads`
- Le **mode overview** est géré par la balise `<meta viewport>` plutôt que par `loadWithOverviewMode`

Le code conditionne ces settings via `Platform.isAndroid` dans `_buildSettings()`.

## Running

```bash
cd flutter_email_zoom_poc
flutter pub get

# Android
flutter run

# iOS
flutter run -d ios

# macOS
flutter run -d macos
```

### Setup macOS
Les fichiers `macos/Runner/*.entitlements` doivent inclure `com.apple.security.network.client = true` pour que le WebView puisse charger du contenu.

## Architecture

```
lib/
├── main.dart                       # Point d'entrée, chargement du ZoomController
├── models/
│   └── email_message.dart          # Modèle email avec champs sécurité (DKIM, SPF, etc.)
├── utils/
│   ├── html_sanitizer.dart         # Nettoyage HTML (XSS, tracking, URLs dangereuses)
│   └── zoom_controller.dart        # Gestion d'état zoom 3 axes + persistance
├── widgets/
│   ├── email_webview.dart          # WebView avec zoom + sanitisation + settings conditionnels
│   ├── security_indicators.dart    # Icônes auth/signature/chiffrement
│   └── zoom_controls.dart          # Bottom sheet avec slider zoom + toggles
└── screens/
    ├── email_list_screen.dart      # Liste inbox avec indicateurs sécurité
    └── email_detail_screen.dart    # Vue email complète avec zoom
```

## Décisions de design

| Décision | Raison |
|----------|--------|
| `javaScriptEnabled: false` | Sécurité — ne jamais exécuter de JS provenant d'emails |
| Zoom via CSS `font-size` plutôt que `textZoom` seul | Cross-platform (iOS/macOS n'ont pas `textZoom`) |
| Sanitisation côté Dart (pas côté WebView) | Contrôle total avant injection dans le WebView |
| `SharedPreferences` pour la persistance zoom | Simple, suffisant pour un POC |
| Images externes bloquées par défaut | Vie privée — empêche le tracking par pixel |
| `shouldOverrideUrlLoading` → CANCEL | Les liens email s'ouvrent dans le navigateur externe, pas dans le WebView |
