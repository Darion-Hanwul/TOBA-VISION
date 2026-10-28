import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'data/services.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Services.init();
  runApp(const TobaVisionApp());
}

class TobaVisionApp extends StatelessWidget {
  const TobaVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toba Vision',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const LoginScreen(),
    );
  }
}
