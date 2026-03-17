import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_email_zoom_poc/utils/zoom_controller.dart';

void main() {
  test('effectiveFontSizeForMessage applies the per-message pinch scale', () {
    final controller = ZoomController(messageZoom: 100, viewZoom: 1);

    controller.setMessageScale('message-1', 1.5);

    expect(controller.getMessageScale('message-1'), 1.5);
    expect(
      controller.effectiveFontSizeForMessage('message-1'),
      closeTo(24.0, 0.01),
    );
  });
}
