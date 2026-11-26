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
  final WeatherData? tomorrow;

  const WeatherData({
    required this.location,
    required this.temp,
    required this.condition,
    required this.subCondition,
    required this.safeToDry,
    required this.statusMessage,
    required this.slots,
    required this.tip,
    this.tomorrow,
  });
}

/// Mode deteksi AI yang dipilih petani pada layar pindai daun.
enum TobaccoDetectionMode {
  grade,
  maturity,
}

/// Skor probabilitas per kelas untuk model klasifikasi kematangan daun (YOLO11n-cls).
class TobaccoClassProbability {
  final String rawLabel;
  final String code;
  final String label;
  final double confidence; // 0.0 .. 1.0

  const TobaccoClassProbability({
    required this.rawLabel,
    required this.code,
    required this.label,
    required this.confidence,
  });
}

/// Satu kotak deteksi hasil model YOLO11s (koordinat ternormalisasi 0..1 pada foto asli).
class TobaccoDetectionBox {
  final String rawLabel;
  final String grade; // A / B / C
  final String gradeName; // BAGUS / SEDANG / JELEK
  final double confidence; // 0.0 .. 1.0
  final double left;
  final double top;
  final double right;
  final double bottom;

  const TobaccoDetectionBox({
    required this.rawLabel,
    required this.grade,
    required this.gradeName,
    required this.confidence,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get area =>
      (right - left).clamp(0.0, 1.0) * (bottom - top).clamp(0.0, 1.0);
}

class DetectionResult {
  final TobaccoDetectionMode mode;
  final String grade; // A / B / C / 1 / 2 / 3 / -
  final String gradeName; // SUPER / STANDAR / AFKIR / BELUM MATANG / MATANG / TERLALU MATANG
  final String badge;
  final String title;
  final String description;
  final String photoTip;
  final double? confidencePercent;
  final int? inferenceMs;
  final String? rawLabel;
  final String? imagePath;
  final int? imageWidth;
  final int? imageHeight;
  final List<TobaccoDetectionBox> detections;
  final List<TobaccoClassProbability> classProbabilities;

  const DetectionResult({
    this.mode = TobaccoDetectionMode.grade,
    required this.grade,
    required this.gradeName,
    required this.badge,
    required this.title,
    required this.description,
    required this.photoTip,
    this.confidencePercent,
    this.inferenceMs,
    this.rawLabel,
    this.imagePath,
    this.imageWidth,
    this.imageHeight,
    this.detections = const [],
    this.classProbabilities = const [],
  });

  bool get isMaturity => mode == TobaccoDetectionMode.maturity;
  bool get isGood => isMaturity ? rawLabel == 'Mature' || grade == '2' : grade == 'A';
  bool get hasDetections => detections.isNotEmpty;
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
