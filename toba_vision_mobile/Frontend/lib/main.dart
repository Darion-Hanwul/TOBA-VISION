import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:toba_vision_mobile/firebase_options.dart';
import 'package:toba_vision_mobile/services/api_service.dart';
import 'package:toba_vision_mobile/services/offline_service.dart';
import 'core/theme.dart';
import 'data/services.dart';
import 'screens/splash_screen.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Handler wajib berada di top-level (di luar class) untuk notifikasi saat aplikasi di background/tertutup
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('--> [FCM Background] Pesan darurat diterima: ${message.notification?.title}');
}

Future<void> _registerTokenToBackend(String? token) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (token == null || token.isEmpty || uid == null || uid.isEmpty) return;

  try {
    await http
        .post(
          Uri.parse('${ApiService.baseUrl}/api/cuaca/register-token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'uid_petani': uid,
            'fcm_token': token,
            'platform': kIsWeb ? 'web' : 'android',
          }),
        )
        .timeout(const Duration(seconds: 6));
  } catch (e) {
    debugPrint('--> [FCM] Gagal mendaftarkan token ke server: $e');
  }
}

Future<void> initWeatherPushNotification() async {
  try {
    final messaging = FirebaseMessaging.instance;

    // 1. Minta izin notifikasi ke pengguna (HP & Web)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );

    // 2. Pastikan notifikasi tetap muncul dengan suara saat aplikasi terbuka di iOS/Android
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Subscribe topik umum untuk Android/iOS
    if (!kIsWeb) {
      await messaging.subscribeToTopic('toba_weather_alerts');
    }

    // 4. Ambil token perangkat (ganti VAPID_KEY jika dijalankan di Web)
    const String webVapidKey = 'BJxPsdnjS468XWr2nagmzaRy9Pt62I9_nBsNFEB1bw9Q-E52WM1wPQwubWMFRxXn6PcR2L-lh-FssXoyMP40ypc';
    final String? token = await messaging.getToken(
      vapidKey: kIsWeb ? webVapidKey : null,
    );

    await _registerTokenToBackend(token);

    // Perbarui token otomatis jika di-refresh oleh Firebase atau saat user baru login
    messaging.onTokenRefresh.listen((newToken) {
      _registerTokenToBackend(newToken);
    });
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && token != null) {
        _registerTokenToBackend(token);
      }
    });

    // 5. Listener saat aplikasi sedang dibuka (Foreground) -> bunyikan alarm & tampilkan banner merah
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();

      final title = message.notification?.title ?? '🚨 ALARM HUJAN DERAS!';
      final body = message.notification?.body ??
          'Hujan deras terdeteksi! Segera amankan sasak daun tembakau ke gudang.';

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(
                      body,
                      style: const TextStyle(fontSize: 12.5, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  } catch (e) {
    debugPrint('--> [FCM Init Warning] $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await OfflineService.initHive();
  Services.init();

  // Jalankan inisialisasi push notification cuaca tanpa menghambat tampilan awal
  initWeatherPushNotification();

  runApp(const TobaVisionApp());
}

class TobaVisionApp extends StatelessWidget {
  const TobaVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toba Vision',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashScreen(),
    );
  }
}