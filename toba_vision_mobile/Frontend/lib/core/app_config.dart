/// Pengaturan global aplikasi.
///
/// Selama backend belum jadi, biarkan [useMock] = true.
/// Bisa juga diatur lewat command line tanpa ubah kode:
///   flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://api.contoh.com
class AppConfig {
  static const bool useMock =
      bool.fromEnvironment('USE_MOCK', defaultValue: true);

  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');

  /// Simulasi lama loading jaringan pada data mock.
  static const Duration mockDelay = Duration(milliseconds: 700);
}
