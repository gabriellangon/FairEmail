import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// HTML sanitizer for email content.
///
/// Inspired by FairEmail's HtmlHelper.java — removes dangerous elements
/// while preserving email layout (tables, inline styles, images).
class HtmlSanitizer {
  // Elements to remove entirely (tag + content)
  static const _removeElements = {
    'script',
    'noscript',
    'iframe',
    'frame',
    'frameset',
    'object',
    'embed',
    'applet',
    'form',
    'input',
    'button',
    'select',
    'textarea',
    'link',
    'meta',
    'base',
  };

  // Allowed elements (everything else gets unwrapped — content kept, tag removed)
  static const _allowedElements = {
    'html', 'head', 'body',
    'div', 'span', 'p', 'br', 'hr',
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    'b', 'i', 'u', 'em', 'strong', 'small', 'sub', 'sup',
    'a', 'img',
    'ul', 'ol', 'li',
    'table', 'thead', 'tbody', 'tfoot', 'tr', 'td', 'th', 'caption',
    'blockquote', 'pre', 'code',
    'center', 'font',
    'style', // kept but content is sanitized separately
  };

  // Dangerous attribute prefixes
  static const _dangerousAttrPrefixes = ['on', 'formaction'];

  /// Sanitize HTML email content. Returns safe renderable markup.
  ///
  /// [html] - Raw HTML content
  /// [allowImages] - Whether to keep <img> tags with external sources
  static String sanitize(String html, {bool allowImages = false}) {
    final document = html_parser.parse(html);

    for (final tag in _removeElements) {
      for (final element in document.querySelectorAll(tag)) {
        element.remove();
      }
    }

    _sanitizeNode(document.documentElement!, allowImages);
    _removeTrackingPixels(document);
    _sanitizeStyles(document);

    final headStyles = document.head
            ?.querySelectorAll('style')
            .map((style) => style.outerHtml)
            .join('\n') ??
        '';
    final bodyHtml =
        document.body?.innerHtml ?? document.documentElement?.innerHtml ?? '';

    if (headStyles.isEmpty) {
      return bodyHtml;
    }

    return '$headStyles\n$bodyHtml';
  }

  /// Returns a report of what was sanitized, for UI display.
  static SanitizeReport analyze(String html) {
    final document = html_parser.parse(html);
    final report = SanitizeReport();

    for (final tag in _removeElements) {
      final elements = document.querySelectorAll(tag);
      if (elements.isNotEmpty) {
        report.removedElements[tag] = elements.length;
      }
    }

    // Check for dangerous attributes
    for (final el in document.querySelectorAll('*')) {
      for (final attr in el.attributes.keys.toList()) {
        final attrStr = attr.toString().toLowerCase();
        if (_isDangerousAttribute(attrStr)) {
          report.removedAttributes.add('$attrStr on <${el.localName}>');
        }
        if (attrStr == 'href' || attrStr == 'src') {
          final val = el.attributes[attr] ?? '';
          if (val.toLowerCase().trimLeft().startsWith('javascript:')) {
            report.blockedUrls.add(val);
          }
        }
      }
    }

    // Check for tracking pixels
    for (final img in document.querySelectorAll('img')) {
      final width = img.attributes['width'];
      final height = img.attributes['height'];
      if (_isTrackingPixel(width, height)) {
        report.trackingPixels++;
      }
    }

    return report;
  }

  static void _sanitizeNode(Element element, bool allowImages) {
    // Process children first (iterate on copy to allow removal)
    for (final child in element.children.toList()) {
      final tag = child.localName?.toLowerCase() ?? '';

      if (_removeElements.contains(tag)) {
        child.remove();
        continue;
      }

      if (!_allowedElements.contains(tag)) {
        // Unwrap: keep content, remove tag
        child.replaceWith(Text(child.text));
        continue;
      }

      // Sanitize attributes
      _sanitizeAttributes(child, allowImages);

      // Recurse
      _sanitizeNode(child, allowImages);
    }
  }

  static void _sanitizeAttributes(Element element, bool allowImages) {
    final tag = element.localName?.toLowerCase() ?? '';

    for (final attr in element.attributes.keys.toList()) {
      final attrStr = attr.toString().toLowerCase();

      // Remove event handlers (onclick, onload, onerror, etc.)
      if (_isDangerousAttribute(attrStr)) {
        element.attributes.remove(attr);
        continue;
      }

      // Sanitize href/src — block javascript: URLs
      if (attrStr == 'href' || attrStr == 'src') {
        final val = element.attributes[attr] ?? '';
        if (val.toLowerCase().trimLeft().startsWith('javascript:')) {
          element.attributes[attr] = '#blocked';
        }
      }
    }

    // Block external images if not allowed
    if (tag == 'img' && !allowImages) {
      final src = element.attributes['src'] ?? '';
      if (src.startsWith('http://') || src.startsWith('https://')) {
        element.attributes['src'] = '';
        element.attributes['data-original-src'] = src;
        element.attributes['alt'] =
            '[Image bloquée: ${element.attributes['alt'] ?? 'externe'}]';
      }
    }
  }

  static bool _isDangerousAttribute(String attr) {
    for (final prefix in _dangerousAttrPrefixes) {
      if (attr.startsWith(prefix)) return true;
    }
    return false;
  }

  static void _removeTrackingPixels(Document document) {
    for (final img in document.querySelectorAll('img')) {
      final width = img.attributes['width'];
      final height = img.attributes['height'];
      if (_isTrackingPixel(width, height)) {
        img.remove();
      }
    }
  }

  static bool _isTrackingPixel(String? width, String? height) {
    if (width == null || height == null) return false;
    final w = int.tryParse(width);
    final h = int.tryParse(height);
    return w != null && h != null && w <= 1 && h <= 1;
  }

  static void _sanitizeStyles(Document document) {
    // Remove style blocks that contain dangerous content
    for (final style in document.querySelectorAll('style')) {
      final content = style.text.toLowerCase();
      if (content.contains('expression(') ||
          content.contains('javascript:') ||
          content.contains('url(') ||
          content.contains('@import')) {
        style.remove();
      }
    }
  }
}

/// Report of what was found/sanitized in an email.
class SanitizeReport {
  final Map<String, int> removedElements = {};
  final List<String> removedAttributes = [];
  final List<String> blockedUrls = [];
  int trackingPixels = 0;

  bool get isClean =>
      removedElements.isEmpty &&
      removedAttributes.isEmpty &&
      blockedUrls.isEmpty &&
      trackingPixels == 0;

  int get totalThreats =>
      removedElements.values.fold(0, (a, b) => a + b) +
      removedAttributes.length +
      blockedUrls.length +
      trackingPixels;
}
