import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_email_zoom_poc/utils/html_sanitizer.dart';

void main() {
  test('sanitize returns renderable body markup instead of a nested document',
      () {
    const html = '''
<html>
  <head>
    <style>p { color: red; }</style>
  </head>
  <body>
    <p>Hello</p>
  </body>
</html>
''';

    final sanitized = HtmlSanitizer.sanitize(html);

    expect(sanitized, contains('<p>Hello</p>'));
    expect(sanitized, contains('<style>p { color: red; }</style>'));
    expect(sanitized, isNot(contains('<body><html')));
    expect(sanitized.trimLeft(), isNot(startsWith('<html')));
  });
}
