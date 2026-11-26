import '../core/app_config.dart';
import 'api_repositories.dart';
import 'bmkg_weather_service.dart';
import 'local_tobacco_detector.dart';
import 'mock_repositories.dart';
import 'repositories.dart';

/// Service locator sederhana: memilih Mock atau API sesuai AppConfig.useMock.
class Services {
  static late UserRepository user;
  static late WeatherRepository weather;
  static late DetectionRepository detection;
  static late FinanceRepository finance;
  static late HarvestRepository harvest;

  static void init() {
    // Cuaca selalu terhubung live ke BMKG Resmi (dengan fallback offline otomatis)
    weather = BmkgWeatherRepository();
    // Deteksi mutu daun berjalan 100% lokal (on-device offline TFLite)
    detection = LocalDetectionRepository();

    if (AppConfig.useMock) {
      user = MockUserRepository();
      finance = MockFinanceRepository();
      harvest = MockHarvestRepository();
    } else {
      user = ApiUserRepository();
      finance = ApiFinanceRepository();
      harvest = ApiHarvestRepository();
    }
  }
}
