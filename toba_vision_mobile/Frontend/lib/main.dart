import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'data/firestore_service.dart';
import 'data/services.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase: Web memerlukan FirebaseOptions eksplisit
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIza' 'SyDzqzgWmkxE6qoHcq-4onsdooOVpomcJ6Q',
        appId: '1:376815342399:web:c466146f198498e016b98a',
        messagingSenderId: '376815342399',
        projectId: 'toba-vision-796bd',
        storageBucket: 'toba-vision-796bd.firebasestorage.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  // Inisialisasi struktur data awal ERD ke Cloud Firestore jika belum ada
  try {
    await FirestoreService.instance.inisialisasiDataAwalDemo();
  } catch (e) {
    debugPrint('Firestore init info: $e');
  }

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
      builder: (context, child) {
        if (kIsWeb) {
          // Frame mobile retro ketika dibuka di browser desktop (Chrome PC)
          return Container(
            color: const Color(0xFF141712),
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        }
        return child ?? const SizedBox.shrink();
      },
      home: const SplashScreen(),
    );
  }
}
