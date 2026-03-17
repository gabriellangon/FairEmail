import 'package:flutter/material.dart';
import 'screens/email_list_screen.dart';
import 'utils/zoom_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final zoomController = await ZoomController.load();
  runApp(EmailZoomPocApp(zoomController: zoomController));
}

class EmailZoomPocApp extends StatelessWidget {
  final ZoomController zoomController;

  const EmailZoomPocApp({super.key, required this.zoomController});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Email Zoom POC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: EmailListScreen(zoomController: zoomController),
    );
  }
}
