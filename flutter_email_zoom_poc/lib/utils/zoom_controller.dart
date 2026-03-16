import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages zoom state, mirroring FairEmail's multi-level zoom system.
///
/// Three independent zoom axes (like FairEmail):
/// - [viewZoom]: 0=small, 1=normal, 2=large (discrete, cycles via button)
/// - [messageZoom]: 50-250% (continuous, via slider)
/// - pinch-to-zoom: handled natively by WebView, persisted per-message
class ZoomController extends ChangeNotifier {
  static const double fontSmall = 0.8;   // HtmlHelper.FONT_SMALL
  static const double fontNormal = 1.0;
  static const double fontLarge = 1.25;  // HtmlHelper.FONT_LARGE
  static const double baseFontSize = 16.0;

  int _viewZoom; // 0, 1, 2
  int _messageZoom; // 50..250 (percentage)
  bool _overviewMode;

  // Per-message pinch-zoom scale persistence
  final Map<String, double> _messageScales = {};

  ZoomController({
    int viewZoom = 1,
    int messageZoom = 100,
    bool overviewMode = false,
  })  : _viewZoom = viewZoom,
        _messageZoom = messageZoom,
        _overviewMode = overviewMode;

  int get viewZoom => _viewZoom;
  int get messageZoom => _messageZoom;
  bool get overviewMode => _overviewMode;

  String get viewZoomLabel => switch (_viewZoom) {
        0 => 'Petit',
        1 => 'Normal',
        2 => 'Grand',
        _ => 'Normal',
      };

  /// Calculated font size combining viewZoom and messageZoom.
  /// Same formula as WebViewEx.java lines 145-153.
  double get effectiveFontSize {
    final zoomFactor = switch (_viewZoom) {
      0 => fontSmall,
      2 => fontLarge,
      _ => fontNormal,
    };
    return baseFontSize * zoomFactor * (_messageZoom / 100.0);
  }

  /// WebView textZoom percentage (for InAppWebView settings).
  int get textZoomPercent => (effectiveFontSize / baseFontSize * 100).round();

  /// Cycle viewZoom: 0 → 1 → 2 → 0 (like FragmentMessages.onMenuZoom).
  void cycleViewZoom() {
    _viewZoom = (_viewZoom + 1) % 3;
    notifyListeners();
    _persist();
  }

  void setMessageZoom(int percent) {
    _messageZoom = percent.clamp(50, 250);
    notifyListeners();
    _persist();
  }

  void setOverviewMode(bool value) {
    _overviewMode = value;
    notifyListeners();
    _persist();
  }

  /// Store pinch-zoom scale for a specific message.
  void setMessageScale(String messageId, double scale) {
    _messageScales[messageId] = scale;
  }

  /// Get stored pinch-zoom scale for a message (null = use default).
  double? getMessageScale(String messageId) => _messageScales[messageId];

  /// Load persisted preferences.
  static Future<ZoomController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ZoomController(
      viewZoom: prefs.getInt('view_zoom') ?? 1,
      messageZoom: prefs.getInt('message_zoom') ?? 100,
      overviewMode: prefs.getBool('overview_mode') ?? false,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('view_zoom', _viewZoom);
    await prefs.setInt('message_zoom', _messageZoom);
    await prefs.setBool('overview_mode', _overviewMode);
  }
}
