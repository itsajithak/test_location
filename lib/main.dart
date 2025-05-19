import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:test_app/screens/services/flutter_background_service.dart';
import 'package:test_app/screens/test_app_screen/test_app_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await requestPermissions();
  await initializeService();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) {
        return const MyApp();
      }, // Wrap your app
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const TestAppScreen(),
    );
  }
}
