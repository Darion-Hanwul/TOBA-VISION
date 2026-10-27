import 'models.dart';

/// Kontrak data. UI hanya bergantung pada interface ini,
/// jadi saat backend jadi cukup ganti implementasinya.
abstract class UserRepository {
  Future<UserProfile> getProfile();
}

abstract class WeatherRepository {
  Future<WeatherData> getWeather();
}

abstract class DetectionRepository {
  /// [imagePath] = path foto dari kamera (null saat mode demo).
  Future<DetectionResult> analyze({String? imagePath});
}

abstract class FinanceRepository {
  Future<List<FinanceEntry>> getEntries();
}

abstract class HarvestRepository {
  Future<List<HarvestItem>> getSchedule();
}
