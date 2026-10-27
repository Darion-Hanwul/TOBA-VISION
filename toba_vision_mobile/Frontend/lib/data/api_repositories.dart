import 'models.dart';
import 'repositories.dart';

// ============================================================
// IMPLEMENTASI BACKEND ASLI (belum diisi).
// Saat API siap:
//  1. tambahkan `http` di pubspec.yaml
//  2. isi method di bawah (GET/POST ke AppConfig.apiBaseUrl)
//  3. jalankan: flutter run --dart-define=USE_MOCK=false
// Selama belum diisi, UI otomatis menampilkan pesan error + tombol "Coba Lagi".
// ============================================================

Never _todo(String endpoint) =>
    throw UnimplementedError('Backend belum tersedia: $endpoint');

class ApiUserRepository implements UserRepository {
  @override
  Future<UserProfile> getProfile() => _todo('GET /me');
}

class ApiWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherData> getWeather() => _todo('GET /weather');
}

class ApiDetectionRepository implements DetectionRepository {
  @override
  Future<DetectionResult> analyze({String? imagePath}) =>
      _todo('POST /detections (multipart image)');
}

class ApiFinanceRepository implements FinanceRepository {
  @override
  Future<List<FinanceEntry>> getEntries() => _todo('GET /finance');
}

class ApiHarvestRepository implements HarvestRepository {
  @override
  Future<List<HarvestItem>> getSchedule() => _todo('GET /harvest');
}
