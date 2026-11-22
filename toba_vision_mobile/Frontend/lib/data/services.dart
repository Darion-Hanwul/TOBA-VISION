import '../core/app_config.dart';
import 'api_repositories.dart';
import 'bmkg_weather_service.dart';
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

    if (AppConfig.useMock) {
      user = MockUserRepository();
      detection = MockDetectionRepository();
      finance = MockFinanceRepository();
      harvest = MockHarvestRepository();
    } else {
      user = ApiUserRepository();
      detection = ApiDetectionRepository();
      finance = ApiFinanceRepository();
      harvest = ApiHarvestRepository();
    }
  }
}
