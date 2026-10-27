import '../core/app_config.dart';
import 'models.dart';
import 'repositories.dart';

Future<T> _fake<T>(T value) async {
  await Future.delayed(AppConfig.mockDelay);
  return value;
}

class MockUserRepository implements UserRepository {
  @override
  Future<UserProfile> getProfile() => _fake(const UserProfile(
        name: 'Pak Slamet',
        group: 'Mitra Poktan Sindoro Makmur',
        region: 'Lereng Sumbing',
      ));
}

/// Cuaca bergantian: panggilan ganjil = aman, genap = peringatan hujan.
/// (Tarik layar ke bawah untuk refresh & lihat dua kondisi.)
class MockWeatherRepository implements WeatherRepository {
  int _n = 0;

  @override
  Future<WeatherData> getWeather() {
    final alert = _n.isOdd;
    _n++;
    if (!alert) {
      return _fake(const WeatherData(
        location: 'Temanggung',
        temp: 29,
        condition: 'Cerah',
        subCondition: 'Berawan',
        safeToDry: true,
        statusMessage: 'Aman untuk jemur\ndaun tembakau hari ini.',
        slots: [
          WeatherSlot(time: '11:00', kind: WeatherKind.sunny, title: 'Cerah', note: 'Kering optimal', temp: 30),
          WeatherSlot(time: '13:00', kind: WeatherKind.rain, title: 'Hujan Lebat', note: 'Sasak harus di gudang', temp: 23, highlight: true),
          WeatherSlot(time: '16:00', kind: WeatherKind.cloudy, title: 'Gerimis Reda', note: 'Udara lembab dingin', temp: 21),
        ],
        tip: 'Matahari lagi terik nih, Pak! Waktu terbaik buat balik sasak tembakau biar kering merata & aroma mantap!',
      ));
    }
    return _fake(const WeatherData(
      location: 'Temanggung',
      temp: 21,
      condition: 'Hujan',
      subCondition: 'Mendung',
      safeToDry: false,
      statusMessage: 'Jangan jemur! Hujan lebat\nsebentar lagi.',
      slots: [
        WeatherSlot(time: '11:00', kind: WeatherKind.overcast, title: 'Mendung', note: 'Awan menebal', temp: 24, highlight: true),
        WeatherSlot(time: '13:00', kind: WeatherKind.rain, title: 'Hujan Lebat', note: 'Sasak harus di gudang', temp: 22),
        WeatherSlot(time: '16:00', kind: WeatherKind.rain, title: 'Hujan Sedang', note: 'Udara lembab dingin', temp: 21),
      ],
      tip: 'Awas Pak! Hujan mau turun. Segera angkat sasak ke gudang biar daun tembakau tidak rusak!',
    ));
  }
}

/// Hasil deteksi bergantian: pertama Grade C, lalu Grade A.
class MockDetectionRepository implements DetectionRepository {
  int _n = 0;

  @override
  Future<DetectionResult> analyze({String? imagePath}) {
    final good = _n.isOdd;
    _n++;
    const tip = 'Posisikan helai daun di atas latar belakang netral dengan pencahayaan alami tanpa bayangan jatuh untuk menjaga akurasi 98%.';
    if (good) {
      return _fake(const DetectionResult(
        grade: 'A',
        gradeName: 'SUPER',
        badge: 'GRADE A • KUALITAS PREMIUM',
        title: 'Kualitas Terbaik, Siap Jual',
        description: 'Daun matang sempurna, warna merata, serat seragam, dan kadar air ideal. Tidak ditemukan bercak maupun jamur.',
        photoTip: tip,
      ));
    }
    return _fake(const DetectionResult(
      grade: 'C',
      gradeName: 'AFKIR',
      badge: 'GRADE C • KUALITAS RENDAH / CACAT',
      title: 'Perlu Sortir & Penanganan Khusus',
      description: 'Daun kusam kecokelatan gelap, bercak daun jamur/embun tepung terdeteksi >25%, serat agak rapuh atau terlalu basah (kadar air >22%). Tidak lolos standar super.',
      photoTip: tip,
    ));
  }
}

class MockFinanceRepository implements FinanceRepository {
  @override
  Future<List<FinanceEntry>> getEntries() => _fake(const [
        FinanceEntry(title: 'Jual tembakau Grade A', category: 'Penjualan', date: '06 Okt 2026', amount: 4500000),
        FinanceEntry(title: 'Pupuk NPK 50 kg', category: 'Sarana tani', date: '04 Okt 2026', amount: -850000),
        FinanceEntry(title: 'Upah petik 5 orang', category: 'Tenaga kerja', date: '03 Okt 2026', amount: -750000),
        FinanceEntry(title: 'Jual tembakau Grade B', category: 'Penjualan', date: '01 Okt 2026', amount: 2800000),
      ]);
}

class MockHarvestRepository implements HarvestRepository {
  @override
  Future<List<HarvestItem>> getSchedule() => _fake(const [
        HarvestItem(plot: 'Petak Atas (Lereng)', date: '10 Okt 2026', estimateKg: 320, status: 'Siap petik'),
        HarvestItem(plot: 'Petak Tengah', date: '15 Okt 2026', estimateKg: 410, status: 'Menunggu'),
        HarvestItem(plot: 'Petak Bawah', date: '22 Okt 2026', estimateKg: 280, status: 'Menunggu'),
      ]);
}
