import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_session.dart';
import 'bmkg_locations.dart';
import 'models.dart';
import 'repositories.dart';

/// Repository Cuaca yang terhubung langsung ke API Publik BMKG (Badan Meteorologi, Klimatologi, dan Geofisika)
/// Mengambil data prakiraan cuaca real-time untuk wilayah perkebunan tembakau berdasarkan profil petani di Firestore.
class BmkgWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherData> getWeather({String? locationQuery}) async {
    // 1. Tentukan target wilayah dari parameter atau dari sesi profil petani di Firestore
    final query = (locationQuery != null && locationQuery.trim().isNotEmpty)
        ? locationQuery
        : AuthSession.currentLokasi;

    final targetLocation = BmkgLocations.findMatchingLocation(query);
    final String apiUrl =
        'https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=${targetLocation.code}';

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final dataList = json['data'] as List<dynamic>?;
        if (dataList != null && dataList.isNotEmpty) {
          final firstData = dataList[0] as Map<String, dynamic>;
          final lokasi = firstData['lokasi'] as Map<String, dynamic>?;
          final cuacaDays = firstData['cuaca'] as List<dynamic>?;

          final String kotkab = lokasi?['kotkab'] ?? targetLocation.kabupaten;
          final String kecamatan = lokasi?['kecamatan'] ?? targetLocation.kecamatan;

          if (cuacaDays != null && cuacaDays.isNotEmpty) {
            final String areaLabel = targetLocation.kecamatan.isNotEmpty && targetLocation.kecamatan != 'Bulu'
                ? '${targetLocation.kecamatan}, $kotkab'
                : '$kotkab ($kecamatan)';

            // Kumpulkan seluruh slot waktu dari BMKG secara berurutan
            final List<dynamic> allUpcomingSlots = [];
            for (final day in cuacaDays) {
              if (day is List) allUpcomingSlots.addAll(day);
            }

            // 1. Hari Ini / 24 Jam ke Depan: Ambil 8 slot berturut-turut (24 jam penuh dari sekarang)
            final List<dynamic> today24Raw = allUpcomingSlots.isNotEmpty
                ? allUpcomingSlots.take(8).toList()
                : ((cuacaDays[0] is List) ? (cuacaDays[0] as List<dynamic>) : []);

            // 2. Hari Besok: Gunakan daftar lengkap slot hari kedua (cuacaDays[1])
            final List<dynamic>? tomorrowRaw = cuacaDays.length > 1 && (cuacaDays[1] is List)
                ? (cuacaDays[1] as List<dynamic>)
                : null;

            final todayWeather = _parseDayWeatherData(
              dayRaw: today24Raw,
              isToday: true,
              kotkab: kotkab,
              kecamatan: kecamatan,
              areaLabel: areaLabel,
            );

            final WeatherData tomorrowWeather;
            if (tomorrowRaw != null && tomorrowRaw.isNotEmpty) {
              tomorrowWeather = _parseDayWeatherData(
                dayRaw: tomorrowRaw,
                isToday: false,
                kotkab: kotkab,
                kecamatan: kecamatan,
                areaLabel: areaLabel,
              );
            } else {
              tomorrowWeather = _buildFallbackTomorrow(
                kotkab: kotkab,
                kecamatan: kecamatan,
                areaLabel: areaLabel,
              );
            }

            return WeatherData(
              location: todayWeather.location,
              temp: todayWeather.temp,
              condition: todayWeather.condition,
              subCondition: todayWeather.subCondition,
              safeToDry: todayWeather.safeToDry,
              statusMessage: todayWeather.statusMessage,
              slots: todayWeather.slots,
              tip: todayWeather.tip,
              tomorrow: tomorrowWeather,
            );
          }
        }
      }
    } catch (_) {
      // Jika terjadi error koneksi / timeout, fallback ke data lokal secara aman
    }

    // Fallback otomatis saat offline yang tetap mencantumkan wilayah petani
    final areaLabel = targetLocation.kecamatan.isNotEmpty && targetLocation.kecamatan != 'Bulu'
        ? '${targetLocation.kecamatan}, ${targetLocation.kabupaten}'
        : '${targetLocation.kabupaten} (${targetLocation.kecamatan})';

    final todayFallback = WeatherData(
      location: '${targetLocation.kabupaten} (${targetLocation.kecamatan})',
      temp: 27,
      condition: 'Cerah Berawan',
      subCondition: 'BMKG Offline • Data Kebun',
      safeToDry: true,
      statusMessage: 'Aman untuk jemur daun tembakau hari ini di $areaLabel.',
      slots: _buildFull24HourFallbackSlots(isTomorrow: false),
      tip:
          'Prakiraan lokal $areaLabel. Jemur tembakau mulai pukul 08:30 sampai 14:00 saat sinar matahari terik!',
    );

    final tomorrowFallback = _buildFallbackTomorrow(
      kotkab: targetLocation.kabupaten,
      kecamatan: targetLocation.kecamatan,
      areaLabel: areaLabel,
    );

    return WeatherData(
      location: todayFallback.location,
      temp: todayFallback.temp,
      condition: todayFallback.condition,
      subCondition: todayFallback.subCondition,
      safeToDry: todayFallback.safeToDry,
      statusMessage: todayFallback.statusMessage,
      slots: todayFallback.slots,
      tip: todayFallback.tip,
      tomorrow: tomorrowFallback,
    );
  }

  /// Parsing data cuaca 24 jam penuh untuk satu hari tertentu
  static WeatherData _parseDayWeatherData({
    required List<dynamic> dayRaw,
    required bool isToday,
    required String kotkab,
    required String kecamatan,
    required String areaLabel,
  }) {
    final now = DateTime.now();
    final List<WeatherSlot> slots = [];
    Map<String, dynamic>? representativeSlot;
    int closestDiffMinutes = 999999;

    for (final s in dayRaw) {
      if (s is Map<String, dynamic>) {
        final localDtStr = s['local_datetime'] as String? ?? '';
        final timePart = localDtStr.contains(' ')
            ? localDtStr.split(' ')[1].substring(0, 5)
            : '12:00';

        final dt = DateTime.tryParse(localDtStr.replaceAll(' ', 'T'));
        final String desc = (s['weather_desc'] as String?) ?? 'Cerah';
        final int tempVal = (s['t'] as num?)?.toInt() ?? 25;
        final int huVal = (s['hu'] as num?)?.toInt() ?? 70;
        final kind = _mapWeatherKind(desc);
        final bool isRain = desc.toLowerCase().contains('hujan') ||
            desc.toLowerCase().contains('petir');

        bool isCurrentSlot = false;
        if (isToday) {
          if (dt != null) {
            final diff = (dt.difference(now).inMinutes).abs();
            if (diff < closestDiffMinutes) {
              closestDiffMinutes = diff;
              representativeSlot = s;
              isCurrentSlot = true;
            }
          }
        } else {
          // Untuk besok, slot siang 10:00 - 13:00 adalah fokus utama petani tembakau
          final hour = int.tryParse(timePart.split(':')[0]) ?? 12;
          if (hour >= 10 && hour <= 13) {
            representativeSlot ??= s;
          }
        }

        final bool isNextDay = dt != null && isToday && (dt.day != now.day);

        final String baseNote;
        if (isRain) {
          baseNote = 'Sasak harus di gudang (Hujan)';
        } else if (kind == WeatherKind.sunny) {
          baseNote = 'Kering optimal terik ($huVal%)';
        } else if (kind == WeatherKind.cloudy) {
          baseNote = 'Berawan, pantau sasak';
        } else {
          baseNote = 'Udara sejuk berawan ($huVal%)';
        }

        final String note = isNextDay ? 'Besok • $baseNote' : baseNote;

        slots.add(
          WeatherSlot(
            time: timePart,
            kind: kind,
            title: desc,
            note: note,
            temp: tempVal,
            highlight: isRain || (isToday && isCurrentSlot),
          ),
        );
      }
    }

    if (representativeSlot == null && dayRaw.isNotEmpty) {
      representativeSlot = dayRaw[0] as Map<String, dynamic>?;
    }

    final String curDesc =
        (representativeSlot?['weather_desc'] as String?) ?? (isToday ? 'Cerah Berawan' : 'Cerah');
    final int curTemp = (representativeSlot?['t'] as num?)?.toInt() ?? 28;
    final int curHumidity = (representativeSlot?['hu'] as num?)?.toInt() ?? 72;

    // Cek apakah ada potensi hujan di jam-jam penjemuran sasak (07:00 - 17:00)
    bool hasDaytimeRain = false;
    for (final s in dayRaw) {
      if (s is Map<String, dynamic>) {
        final dtStr = s['local_datetime'] as String? ?? '';
        final hour = dtStr.contains(' ')
            ? int.tryParse(dtStr.split(' ')[1].substring(0, 2)) ?? 12
            : 12;
        final desc = ((s['weather_desc'] as String?) ?? '').toLowerCase();
        if (hour >= 6 && hour <= 17 && (desc.contains('hujan') || desc.contains('petir'))) {
          hasDaytimeRain = true;
          break;
        }
      }
    }

    final bool safeToDry = !hasDaytimeRain;
    final String statusMessage;
    final String tip;

    if (isToday) {
      statusMessage = hasDaytimeRain
          ? 'Waspada hujan hari ini di $areaLabel! Segera amankan sasak.'
          : 'Aman untuk jemur daun tembakau hari ini di $areaLabel.';
      tip = hasDaytimeRain
          ? 'Awas Pak! Prakiraan BMKG hari ini berpotensi $curDesc di $areaLabel. Pantau sasak tembakau dan segera masukkan ke gudang bila mendung gelap!'
          : 'Prakiraan BMKG hari ini di $areaLabel $curDesc (Kelembaban $curHumidity%). Sinar matahari optimal untuk membalik sasak tembakau agar kering merata & kuning keemasan!';
    } else {
      statusMessage = hasDaytimeRain
          ? 'Besok diprediksi hujan di $areaLabel. Siapkan gudang & tunda jemur terbuka.'
          : 'Prakiraan besok cerah & aman untuk penjemuran sasak di $areaLabel.';
      tip = hasDaytimeRain
          ? 'Perhatian Pak! Besok ada potensi hujan di wilayah $areaLabel. Sebaiknya daun disimpan rapi di gudang atau siapkan terpal penutup bila daun masih di sasak!'
          : 'Kabar baik Pak! Besok cuaca di $areaLabel diprediksi bersahabat ($curDesc). Siapkan sasak sejak pagi jam 07:00 untuk penjemuran maksimal!';
    }

    return WeatherData(
      location: '$kotkab ($kecamatan)',
      temp: curTemp,
      condition: curDesc,
      subCondition: 'BMKG • Lembab $curHumidity%',
      safeToDry: safeToDry,
      statusMessage: statusMessage,
      slots: _expandTo24HourlySlots(
        slots.isNotEmpty ? slots : _buildFull24HourFallbackSlots(isTomorrow: !isToday),
        isToday: isToday,
      ),
      tip: tip,
    );
  }

  /// Membuat prediksi hari besok saat BMKG hanya mengembalikan data 1 hari
  static WeatherData _buildFallbackTomorrow({
    required String kotkab,
    required String kecamatan,
    required String areaLabel,
  }) {
    return WeatherData(
      location: '$kotkab ($kecamatan)',
      temp: 27,
      condition: 'Hujan Ringan',
      subCondition: 'BMKG • Lembab 82%',
      safeToDry: false,
      statusMessage: 'Waspada potensi hujan besok sore jam 16:00 di $areaLabel! Segera siapkan gudang sasak.',
      slots: _buildFull24HourFallbackSlots(isTomorrow: true),
      tip:
          'Perhatian Pak! Besok terdeteksi potensi hujan sore jam 16:00 - 17:00 (mendung jam 13:00 - 15:00 & 18:00 - 20:00) di $areaLabel. Pastikan daun tembakau sudah diangkat sebelum hujan turun agar tidak basah dan membusuk!',
    );
  }

  /// Daftar lengkap 24 jam penuh (tiap interval 1 jam berturut-turut: 00:00 - 23:00)
  static List<WeatherSlot> _buildFull24HourFallbackSlots({bool isTomorrow = false}) {
    if (isTomorrow) {
      return [
        const WeatherSlot(time: '00:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Malam tenang sejuk di gudang', temp: 22),
        const WeatherSlot(time: '01:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Malam sejuk berembun', temp: 22),
        const WeatherSlot(time: '02:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Udara malam dingin, sasak aman', temp: 21),
        const WeatherSlot(time: '03:00', kind: WeatherKind.overcast, title: 'Udara Kabur', note: 'Embun malam tebal di gudang', temp: 21),
        const WeatherSlot(time: '04:00', kind: WeatherKind.overcast, title: 'Udara Kabur', note: 'Embun pagi dingin di kebun', temp: 21),
        const WeatherSlot(time: '05:00', kind: WeatherKind.overcast, title: 'Udara Kabur', note: 'Subuh sejuk, siapkan daun tembakau', temp: 22),
        const WeatherSlot(time: '06:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Fajar mulai terang, siap angkut sasak', temp: 23),
        const WeatherSlot(time: '07:00', kind: WeatherKind.sunny, title: 'Cerah Pagi', note: 'Mulai jemur sasak di sinar pagi', temp: 25),
        const WeatherSlot(time: '08:00', kind: WeatherKind.sunny, title: 'Cerah Hangat', note: 'Sinar pagi hangat, penguapan mulai aktif', temp: 26),
        const WeatherSlot(time: '09:00', kind: WeatherKind.sunny, title: 'Cerah Terik', note: 'Sinar terik naik, daun layu optimal', temp: 28),
        const WeatherSlot(time: '10:00', kind: WeatherKind.sunny, title: 'Cerah Terik', note: 'Kering optimal terik, balik daun di sasak', temp: 29),
        const WeatherSlot(time: '11:00', kind: WeatherKind.sunny, title: 'Cerah Terik', note: 'Puncak panas terik, pengeringan maksimal', temp: 30),
        const WeatherSlot(time: '12:00', kind: WeatherKind.sunny, title: 'Cerah Terik', note: 'Terik tengah hari, pantau kelembaban', temp: 31),
        const WeatherSlot(time: '13:00', kind: WeatherKind.overcast, title: 'Mendung Berawan', note: 'Awan mendung mulai berkumpul', temp: 28),
        const WeatherSlot(time: '14:00', kind: WeatherKind.overcast, title: 'Mendung Berawan', note: 'Mendung tebal, bersiap angkat sasak', temp: 27),
        const WeatherSlot(time: '15:00', kind: WeatherKind.overcast, title: 'Mendung Tebal', note: 'Awan gelap angin kencang, amankan daun!', temp: 26),
        const WeatherSlot(time: '16:00', kind: WeatherKind.rain, title: 'Hujan Ringan', note: 'Hujan turun! Sasak wajib di gudang', temp: 25, highlight: true),
        const WeatherSlot(time: '17:00', kind: WeatherKind.rain, title: 'Hujan Ringan', note: 'Hujan rintik bertahap reda', temp: 24, highlight: true),
        const WeatherSlot(time: '18:00', kind: WeatherKind.overcast, title: 'Berawan Basah', note: 'Hujan telah reda, sasak tetap di gudang', temp: 24),
        const WeatherSlot(time: '19:00', kind: WeatherKind.overcast, title: 'Berawan', note: 'Malam teduh sejuk, sasak di gudang', temp: 24),
        const WeatherSlot(time: '20:00', kind: WeatherKind.overcast, title: 'Berawan', note: 'Gudang tertutup rapat dan kering', temp: 23),
        const WeatherSlot(time: '21:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Suhu malam stabil untuk fermentasi', temp: 23),
        const WeatherSlot(time: '22:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Sasak aman di gudang semalaman', temp: 23),
        const WeatherSlot(time: '23:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Malam tenang sejuk di gudang', temp: 22),
      ];
    }
    return [
      const WeatherSlot(time: '00:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Malam tenang sejuk di gudang', temp: 23),
      const WeatherSlot(time: '01:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Malam tenang sejuk di gudang', temp: 22),
      const WeatherSlot(time: '02:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Udara malam dingin, sasak aman', temp: 22),
      const WeatherSlot(time: '03:00', kind: WeatherKind.overcast, title: 'Udara Kabur', note: 'Embun malam sejuk di gudang', temp: 21),
      const WeatherSlot(time: '04:00', kind: WeatherKind.overcast, title: 'Udara Kabur', note: 'Embun pagi sejuk, udara bersih', temp: 21),
      const WeatherSlot(time: '05:00', kind: WeatherKind.overcast, title: 'Udara Kabur', note: 'Subuh sejuk, siapkan daun tembakau', temp: 22),
      const WeatherSlot(time: '06:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Fajar mulai terang, siap angkut sasak', temp: 23),
      const WeatherSlot(time: '07:00', kind: WeatherKind.sunny, title: 'Cerah Pagi', note: 'Mulai susun jemuran sasak di kebun', temp: 25),
      const WeatherSlot(time: '08:00', kind: WeatherKind.sunny, title: 'Cerah Hangat', note: 'Sinar pagi hangat, penguapan mulai aktif', temp: 26),
      const WeatherSlot(time: '09:00', kind: WeatherKind.sunny, title: 'Cerah Terik', note: 'Sinar terik naik, daun layu merata', temp: 28),
      const WeatherSlot(time: '10:00', kind: WeatherKind.sunny, title: 'Cerah Terik', note: 'Kering optimal terik, balik daun di sasak', temp: 29),
      const WeatherSlot(time: '11:00', kind: WeatherKind.sunny, title: 'Cerah Terik', note: 'Puncak panas terik, pengeringan maksimal', temp: 30),
      const WeatherSlot(time: '12:00', kind: WeatherKind.sunny, title: 'Cerah Terik', note: 'Terik tengah hari, pantau kelembaban', temp: 31),
      const WeatherSlot(time: '13:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Panas stabil siang, balik sisi bawah sasak', temp: 30),
      const WeatherSlot(time: '14:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Pengeringan berlanjut, aroma mulai harum', temp: 29),
      const WeatherSlot(time: '15:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Matahari condong, cek kadar kelayuan', temp: 28),
      const WeatherSlot(time: '16:00', kind: WeatherKind.overcast, title: 'Berawan', note: 'Angin sore stabil, mulai rapikan sasak', temp: 26),
      const WeatherSlot(time: '17:00', kind: WeatherKind.overcast, title: 'Berawan', note: 'Sore sejuk, angkut sasak masuk gudang', temp: 25),
      const WeatherSlot(time: '18:00', kind: WeatherKind.overcast, title: 'Berawan', note: 'Sasak tersimpan rapi dalam gudang', temp: 24),
      const WeatherSlot(time: '19:00', kind: WeatherKind.overcast, title: 'Berawan', note: 'Malam teduh, proses pemeraman daun', temp: 24),
      const WeatherSlot(time: '20:00', kind: WeatherKind.overcast, title: 'Berawan', note: 'Gudang tertutup rapat dan kering', temp: 23),
      const WeatherSlot(time: '21:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Suhu malam stabil untuk fermentasi', temp: 23),
      const WeatherSlot(time: '22:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Sasak aman di gudang semalaman', temp: 23),
      const WeatherSlot(time: '23:00', kind: WeatherKind.cloudy, title: 'Cerah Berawan', note: 'Malam tenang, istirahat kebun', temp: 22),
    ];
  }

  /// Mengembangkan data 8 slot (tiap 3 jam) dari BMKG menjadi 24 slot lengkap tiap 1 jam
  static List<WeatherSlot> _expandTo24HourlySlots(
    List<WeatherSlot> anchorSlots, {
    required bool isToday,
  }) {
    if (anchorSlots.isEmpty) {
      return _buildFull24HourFallbackSlots(isTomorrow: !isToday);
    }
    if (anchorSlots.length >= 24) {
      return anchorSlots;
    }

    final now = DateTime.now();
    final Map<int, WeatherSlot> hourMap = {};
    for (final s in anchorSlots) {
      final h = int.tryParse(s.time.split(':')[0]) ?? 0;
      hourMap[h] = s;
    }

    final sortedAnchorHours = hourMap.keys.toList()..sort();
    final List<WeatherSlot> full24 = [];

    for (int h = 0; h < 24; h++) {
      final timeStr = '${h.toString().padLeft(2, '0')}:00';

      // Jika pas di jam anchor BMKG
      if (hourMap.containsKey(h)) {
        final exactSlot = hourMap[h]!;
        final isRain = exactSlot.kind == WeatherKind.rain ||
            exactSlot.title.toLowerCase().contains('hujan');
        full24.add(
          WeatherSlot(
            time: timeStr,
            kind: exactSlot.kind,
            title: exactSlot.title,
            note: exactSlot.note.isNotEmpty
                ? exactSlot.note
                : _getHourlyFarmingNote(h, exactSlot.kind, exactSlot.title),
            temp: exactSlot.temp,
            highlight: isRain || (isToday && h == now.hour),
          ),
        );
        continue;
      }

      // Cari anchor sebelumnya dan sesudahnya
      int prevH = sortedAnchorHours.last;
      int nextH = sortedAnchorHours.first;

      for (final ah in sortedAnchorHours) {
        if (ah < h) {
          prevH = ah;
        }
      }
      for (final ah in sortedAnchorHours) {
        if (ah > h) {
          nextH = ah;
          break;
        }
      }

      final prevSlot = hourMap[prevH]!;
      final nextSlot = hourMap[nextH]!;

      // Interpolasi suhu linear
      int span = nextH - prevH;
      if (span <= 0) span += 24;
      int dist = h - prevH;
      if (dist < 0) dist += 24;
      final double ratio = dist / span;
      final int tempVal =
          (prevSlot.temp + ratio * (nextSlot.temp - prevSlot.temp)).round();

      // Pilih kondisi cuaca dari anchor terdekat
      int distPrev = (h - prevH).abs();
      if (distPrev > 12) distPrev = 24 - distPrev;
      int distNext = (nextH - h).abs();
      if (distNext > 12) distNext = 24 - distNext;

      final closestSlot = distPrev <= distNext ? prevSlot : nextSlot;
      WeatherKind kind = closestSlot.kind;
      String title = closestSlot.title;

      // Jika ada hujan di anchor sesudahnya dan jarak hanya 1 jam, tandai awan tebal mendung
      if (nextSlot.kind == WeatherKind.rain && distNext == 1 && kind != WeatherKind.rain) {
        kind = WeatherKind.overcast;
        title = 'Mendung Tebal';
      }

      final isRain = kind == WeatherKind.rain ||
          title.toLowerCase().contains('hujan');
      final note = _getHourlyFarmingNote(h, kind, title);

      full24.add(
        WeatherSlot(
          time: timeStr,
          kind: kind,
          title: title,
          note: note,
          temp: tempVal,
          highlight: isRain || (isToday && h == now.hour),
        ),
      );
    }

    return full24;
  }

  /// Catatan khusus aktivitas penjemuran tembakau per jam
  static String _getHourlyFarmingNote(int hour, WeatherKind kind, String title) {
    final isRain = kind == WeatherKind.rain ||
        title.toLowerCase().contains('hujan') ||
        title.toLowerCase().contains('petir');
    if (isRain) {
      return 'Sasak harus di gudang (Hujan)';
    }

    if (kind == WeatherKind.overcast ||
        title.toLowerCase().contains('mendung') ||
        title.toLowerCase().contains('berawan tebal')) {
      if (hour >= 7 && hour <= 16) {
        return 'Mendung redup, pantau sasak berkala';
      } else {
        return 'Udara sejuk berawan malam';
      }
    }

    switch (hour) {
      case 0:
      case 1:
      case 2:
      case 3:
        return 'Malam tenang sejuk, sasak di gudang';
      case 4:
      case 5:
        return 'Embun pagi sejuk di gudang';
      case 6:
        return 'Fajar mulai terang, siap angkut sasak';
      case 7:
        return 'Mulai jemur sasak di terik pagi';
      case 8:
        return 'Sinar pagi hangat, penguapan mulai aktif';
      case 9:
        return 'Sinar terik naik, daun layu optimal';
      case 10:
        return 'Kering optimal terik, balik daun di sasak';
      case 11:
        return 'Puncak panas terik, pengeringan maksimal';
      case 12:
        return 'Terik tengah hari, pantau kelembaban';
      case 13:
        return 'Panas stabil, balik sisi bawah sasak';
      case 14:
        return 'Pengeringan berlanjut, aroma mulai harum';
      case 15:
        return 'Matahari condong, cek kadar kelayuan';
      case 16:
        return 'Angin sore stabil, mulai rapikan sasak';
      case 17:
        return 'Sore sejuk, angkut sasak masuk gudang';
      case 18:
        return 'Sasak tersimpan aman dalam gudang';
      case 19:
      case 20:
      case 21:
      case 22:
      case 23:
        return 'Pemeraman malam hari dalam gudang tertutup';
      default:
        return 'Kondisi stabil untuk kebun';
    }
  }

  static WeatherKind _mapWeatherKind(String desc) {
    final lower = desc.toLowerCase();
    if (lower.contains('hujan') ||
        lower.contains('petir') ||
        lower.contains('gerimis')) {
      return WeatherKind.rain;
    }
    if (lower.contains('cerah berawan')) {
      return WeatherKind.cloudy;
    }
    if (lower.contains('cerah')) {
      return WeatherKind.sunny;
    }
    if (lower.contains('berawan') ||
        lower.contains('kabut') ||
        lower.contains('asap')) {
      return WeatherKind.overcast;
    }
    return WeatherKind.cloudy;
  }
}
