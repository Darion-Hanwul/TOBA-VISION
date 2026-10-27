class UserProfile {
  final String name;
  final String group;
  final String region;
  const UserProfile({required this.name, required this.group, required this.region});
}

enum WeatherKind { sunny, cloudy, overcast, rain }

class WeatherSlot {
  final String time;
  final WeatherKind kind;
  final String title;
  final String note;
  final int temp;
  final bool highlight;
  const WeatherSlot({
    required this.time,
    required this.kind,
    required this.title,
    required this.note,
    required this.temp,
    this.highlight = false,
  });
}

class WeatherData {
  final String location;
  final int temp;
  final String condition;
  final String subCondition;
  final bool safeToDry;
  final String statusMessage;
  final List<WeatherSlot> slots;
  final String tip;
  const WeatherData({
    required this.location,
    required this.temp,
    required this.condition,
    required this.subCondition,
    required this.safeToDry,
    required this.statusMessage,
    required this.slots,
    required this.tip,
  });
}

class DetectionResult {
  final String grade; // A / B / C
  final String gradeName; // SUPER / AFKIR
  final String badge;
  final String title;
  final String description;
  final String photoTip;
  const DetectionResult({
    required this.grade,
    required this.gradeName,
    required this.badge,
    required this.title,
    required this.description,
    required this.photoTip,
  });
  bool get isGood => grade == 'A';
}

class FinanceEntry {
  final String title;
  final String category;
  final String date;
  final int amount; // positif = pemasukan, negatif = pengeluaran
  const FinanceEntry({
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
  });
}

class HarvestItem {
  final String plot;
  final String date;
  final int estimateKg;
  final String status;
  const HarvestItem({
    required this.plot,
    required this.date,
    required this.estimateKg,
    required this.status,
  });
}
