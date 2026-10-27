import '../core/app_config.dart';
import 'api_repositories.dart';
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
    if (AppConfig.useMock) {
      user = MockUserRepository();
      weather = MockWeatherRepository();
      detection = MockDetectionRepository();
      finance = MockFinanceRepository();
      harvest = MockHarvestRepository();
    } else {
      user = ApiUserRepository();
      weather = ApiWeatherRepository();
      detection = ApiDetectionRepository();
      finance = ApiFinanceRepository();
      harvest = ApiHarvestRepository();
    }
  }
}
