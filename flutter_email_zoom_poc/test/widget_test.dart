import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_email_zoom_poc/main.dart';
import 'package:flutter_email_zoom_poc/utils/zoom_controller.dart';

void main() {
  testWidgets('renders inbox screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      EmailZoomPocApp(zoomController: ZoomController()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Boîte de réception'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(5));
  });
}
