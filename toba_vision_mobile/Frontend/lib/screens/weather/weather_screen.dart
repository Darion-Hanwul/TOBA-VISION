import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../services/offline_service.dart';
import '../../widgets/app_header.dart';

enum _AlertTier { safeGreen, cautionYellow, dangerRed }

class _HourlyForecastItem {
  final DateTime time;
  final double tempC;
  final int rainProb;
  final double rainMm;
  final int weatherCode;
  final String conditionText;
  final String tierString;

  const _HourlyForecastItem({
    required this.time,
    required this.tempC,
    required this.rainProb,
    required this.rainMm,
    required this.weatherCode,
    required this.conditionText,
    required this.tierString,
  });

  bool get isHeavyRain =>
      tierString == 'red' || weatherCode >= 63 || rainMm >= 2.0;

  bool get isCaution =>
      !isHeavyRain &&
      (tierString == 'yellow' ||
          (weatherCode >= 45 && weatherCode <= 61) ||
          weatherCode == 80 ||
          rainMm > 0.0 ||
          rainProb >= 55 ||
          tempC < 26.5);

  bool get isHotSunny =>
      !isHeavyRain &&
      !isCaution &&
      tempC >= 27.0 &&
      time.hour >= 7 &&
      time.hour <= 16;

  String get label =>
      conditionText.isNotEmpty ? conditionText : 'Cerah Berawan';

  String get advice {
    if (isHeavyRain) return 'Sasak wajib masuk gudang!';
    if (isCaution) return 'Siapkan terpal penutup';
    if (time.hour >= 18 || time.hour < 6) return 'Simpan sasak di rak dalam';
    return 'Optimal penjemuran daun';
  }
}

class _DailyForecastItem {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int maxRainProb;
  final double totalRainMm;
  final String condition;
  final String hotWindow;
  final String rainWindow;
  final String summaryVerdict;
  final List<_HourlyForecastItem> hours;

  const _DailyForecastItem({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.maxRainProb,
    required this.totalRainMm,
    required this.condition,
    required this.hotWindow,
    required this.rainWindow,
    required this.summaryVerdict,
    required this.hours,
  });
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  String _namaPetani = 'Petani Mitra';
  String _locationName = 'Mendeteksi lokasi...';
  double _lat = -8.1724;
  double _lon = 113.7007;

  double _currentTemp = 29.0;
  int _currentHumidity = 65;
  int _currentRainProb = 15;
  double _currentRainMm = 0.0;
  String _currentCondition = 'Cerah Berawan';
  String _currentTierStr = 'green';
  String _backendWarningMsg = 'AMAN JEMUR • Panas terik optimal untuk penjemuran daun.';

  List<_DailyForecastItem> _dailyList = [];
  int _selectedDayIndex = 0;

  bool _alarmAlreadyTriggered = false;
  Timer? _alarmBeepTimer;

  @override
  void initState() {
    super.initState();
    _loadAllWeatherData();
  }

  @override
  void dispose() {
    _alarmBeepTimer?.cancel();
    super.dispose();
  }

  String _dynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  // ==========================================
  // 1. MUAT PROFIL, GPS REAL-TIME & DATA DINAMIS DARI BACKEND (/api/weather)
  // ==========================================
  Future<void> _loadAllWeatherData({bool showToast = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // A. Nama Petani Aktif
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final userData = OfflineService.getUserData();
      if ((userData['nama']?.toString().trim().isNotEmpty ?? false) &&
          userData['nama'] != 'Petani Toba') {
        _namaPetani = userData['nama'].toString().trim();
      } else if (firebaseUser?.displayName?.trim().isNotEmpty ?? false) {
        _namaPetani = firebaseUser!.displayName!.trim();
      }

      // B. Deteksi Koordinat GPS & Nama Kecamatan/Kota Saat Ini
      await _resolveCurrentGpsAndPlace();

      // C. Ambil Prakiraan Cuaca Presisi (Real-Time + 14 Hari) dari Backend FastAPI (/api/weather)
      final queryParams = <String, String>{
        'location': _locationName,
        'lat': _lat.toString(),
        'lon': _lon.toString(),
        'days': '14',
      };

      final backendUri = Uri.parse('${ApiService.baseUrl}/api/weather')
          .replace(queryParameters: queryParams);

      final res = await http.get(backendUri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        throw Exception('Server cuaca mengembalikan status ${res.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(res.body);

      // Parse Current Weather dari Backend
      final current = Map<String, dynamic>.from(data['current'] ?? {});
      _currentTemp = (current['numeric_temp_c'] as num?)?.toDouble() ?? 28.0;
      _currentHumidity = (current['humidity'] as num?)?.toInt() ?? 65;
      _currentRainProb = (current['chance_of_rain'] as num?)?.toInt() ?? 0;
      _currentRainMm = (current['precip_mm'] as num?)?.toDouble() ?? 0.0;
      _currentCondition = (current['condition'] ?? 'Cerah Berawan').toString();
      _currentTierStr = (current['tier'] ?? 'green').toString();

      final rec = Map<String, dynamic>.from(data['recommendation'] ?? {});
      if ((rec['warning_message'] ?? '').toString().isNotEmpty) {
        _backendWarningMsg = rec['warning_message'].toString();
      }

      // Parse Daily Forecast (14 Hari Akurat dari Backend)
      final List<dynamic> dListRaw = data['daily_forecast'] ?? [];
      final parsedDays = dListRaw
          .map((item) => _parseDailyItemFromBackend(Map<String, dynamic>.from(item)))
          .toList();

      // Simpan cache lokasi offline di Hive
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');
      await box.put('cached_weather_location', _locationName);

      // Trigger FCM push ke server jika hujan deras aktual terdeteksi
      _notifyBackendIfSevereWeather();

      if (!mounted) return;
      setState(() {
        if (parsedDays.isNotEmpty) {
          _dailyList = parsedDays;
        }
        if (_selectedDayIndex >= _dailyList.length) _selectedDayIndex = 0;
        _isLoading = false;
      });

      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cuaca $_locationName berhasil diperbarui!'),
            backgroundColor: AppColors.forest,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Bunyikan alarm otomatis HANYA jika status cuaca aktual dari backend = RED (Hujan Deras)
      if (_evaluateCurrentTier() == _AlertTier.dangerRed && !_alarmAlreadyTriggered) {
        _alarmAlreadyTriggered = true;
        _triggerHeavyRainAlarm(isManualTest: false);
      }
    } catch (e) {
      debugPrint('Error memuat cuaca dari backend: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Gagal terhubung ke Backend Cuaca (${ApiService.baseUrl}). Pastikan server FastAPI berjalan.';
        });
      }
    }
  }

  _DailyForecastItem _parseDailyItemFromBackend(Map<String, dynamic> raw) {
    final dateStr = (raw['date'] ?? DateTime.now().toIso8601String().split('T').first).toString();
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();

    final List<dynamic> rawHours = raw['hours'] ?? [];
    final hours = <_HourlyForecastItem>[];
    for (final hItem in rawHours) {
      final hMap = Map<String, dynamic>.from(hItem);
      final tStr = (hMap['time'] ?? '12:00').toString();
      final parts = tStr.split(':');
      final hourInt = int.tryParse(parts.first) ?? 12;
      final minuteInt = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      hours.add(
        _HourlyForecastItem(
          time: DateTime(date.year, date.month, date.day, hourInt, minuteInt),
          tempC: (hMap['temp_c'] as num?)?.toDouble() ?? 27.0,
          rainProb: (hMap['chance_of_rain'] as num?)?.toInt() ?? 0,
          rainMm: (hMap['precip_mm'] as num?)?.toDouble() ?? 0.0,
          weatherCode: (hMap['weather_code'] as num?)?.toInt() ?? 1,
          conditionText: (hMap['condition'] ?? '').toString(),
          tierString: (hMap['tier'] ?? 'green').toString(),
        ),
      );
    }

    return _DailyForecastItem(
      date: date,
      maxTemp: (raw['max_temp_c'] as num?)?.toDouble() ?? 30.0,
      minTemp: (raw['min_temp_c'] as num?)?.toDouble() ?? 22.0,
      maxRainProb: (raw['max_chance_of_rain'] as num?)?.toInt() ?? 0,
      totalRainMm: (raw['total_precip_mm'] as num?)?.toDouble() ?? 0.0,
      condition: (raw['condition'] ?? 'Cerah Berawan').toString(),
      hotWindow: (raw['hot_window'] ?? 'Tidak ada panas terik optimal').toString(),
      rainWindow: (raw['rain_window'] ?? 'Aman, tidak ada potensi hujan').toString(),
      summaryVerdict: (raw['summary_verdict'] ?? 'Pantau cuaca secara berkala.').toString(),
      hours: hours,
    );
  }

  Future<void> _openAccurateCalendarPicker() async {
    if (_dailyList.isEmpty) return;
    final firstAvailable = _dailyList.first.date;
    final lastAvailable = _dailyList.last.date;
    final currentSelected = _dailyList[_selectedDayIndex].date;

    final picked = await showDatePicker(
      context: context,
      initialDate: currentSelected,
      firstDate: DateTime(firstAvailable.year, firstAvailable.month, firstAvailable.day),
      lastDate: DateTime(lastAvailable.year, lastAvailable.month, lastAvailable.day),
      helpText: 'Pilih Tanggal Prakiraan (${_dailyList.length} Hari Ke Depan)',
      confirmText: 'Lihat Cuaca',
      cancelText: 'Batal',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF004C22),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    final matchIdx = _dailyList.indexWhere(
      (d) => d.date.year == picked.year && d.date.month == picked.month && d.date.day == picked.day,
    );
    if (matchIdx != -1) {
      setState(() => _selectedDayIndex = matchIdx);
    }
  }

  Future<void> _resolveCurrentGpsAndPlace() async {
    final box = Hive.isBoxOpen('toba_offline_box')
        ? Hive.box('toba_offline_box')
        : await Hive.openBox('toba_offline_box');

    final cachedLoc = box.get('current_user_location')?.toString();
    if (cachedLoc != null && cachedLoc.isNotEmpty) {
      _locationName = cachedLoc;
    }

    try {
      if (!kIsWeb) {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) throw Exception('GPS nonaktif');
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _lat = pos.latitude;
      _lon = pos.longitude;

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$_lat&lon=$_lon&accept-language=id',
      );
      final geoRes = await http
          .get(uri, headers: {'User-Agent': 'TobaVisionApp/1.0'})
          .timeout(const Duration(seconds: 6));

      if (geoRes.statusCode == 200) {
        final Map<String, dynamic> geo = jsonDecode(geoRes.body);
        final Map<String, dynamic> addr = Map<String, dynamic>.from(geo['address'] ?? {});
        final String? sub = addr['suburb'] ?? addr['village'] ?? addr['town'] ?? addr['municipality'];
        final String? city = addr['city'] ?? addr['county'] ?? addr['regency'] ?? addr['state_district'];
        if (sub != null && city != null) {
          _locationName = '$sub, $city';
        } else if (city != null) {
          _locationName = city;
        }
        await box.put('current_user_location', _locationName);
      }
    } catch (_) {
      try {
        final ipRes = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 5));
        if (ipRes.statusCode == 200) {
          final ip = jsonDecode(ipRes.body);
          if (ip['latitude'] != null && ip['longitude'] != null) {
            _lat = (ip['latitude'] as num).toDouble();
            _lon = (ip['longitude'] as num).toDouble();
          }
          final city = (ip['city'] ?? '').toString();
          final region = (ip['region'] ?? '').toString();
          if (city.isNotEmpty) {
            _locationName = region.isNotEmpty ? '$city, $region' : city;
            await box.put('current_user_location', _locationName);
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _notifyBackendIfSevereWeather() async {
    if (_evaluateCurrentTier() != _AlertTier.dangerRed) return;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await http
          .post(
            Uri.parse('${ApiService.baseUrl}/api/cuaca/alert-push'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'uid_petani': uid,
              'lokasi': _locationName,
              'suhu_c': _currentTemp,
              'peluang_hujan': _currentRainProb,
              'curah_hujan_mm': _currentRainMm,
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  // ==========================================
  // 2. LOGIKA WARNA DINAMIS DARI BACKEND (HIJAU / KUNING / MERAH)
  // ==========================================
  _AlertTier _evaluateCurrentTier() {
    if (_currentTierStr == 'red' || _currentRainMm >= 2.0) {
      return _AlertTier.dangerRed;
    }
    if (_currentTierStr == 'yellow' ||
        _currentRainMm > 0.0 ||
        _currentRainProb >= 55 ||
        _currentTemp < 26.5) {
      return _AlertTier.cautionYellow;
    }
    return _AlertTier.safeGreen;
  }

  // ==========================================
  // 3. ALARM BUNYI + GETARAN + DIALOG DARURAT HUJAN DERAS
  // ==========================================
  void _triggerHeavyRainAlarm({bool isManualTest = false}) {
    _alarmBeepTimer?.cancel();
    int beepCount = 0;

    void playBeep() {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    }

    playBeep();
    _alarmBeepTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      beepCount++;
      if (beepCount >= 6 || !mounted) {
        timer.cancel();
        return;
      }
      playBeep();
    });

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFEF2F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: Color(0xFFDC2626), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'ALARM HUJAN DERAS!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF991B1B),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isManualTest
                  ? 'Simulasi Alarm Darurat Cuaca untuk $_locationName aktif!'
                  : 'Terdeteksi hujan deras (${_currentRainMm.toStringAsFixed(1)} mm) dengan suhu ${_currentTemp.toStringAsFixed(1)}°C di $_locationName!',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7F1D1D),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Segera angkat seluruh sasak jemuran daun tembakau ke dalam gudang dan tutup terpal pelindung agar kualitas daun tidak rusak.',
              style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF450A0A)),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _alarmBeepTimer?.cancel();
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.volume_off_rounded, size: 18),
              label: const Text(
                'Matikan Alarm & Amankan Sasak',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatIndoDate(DateTime dt, {int? quickIndex}) {
    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final shortDateStr = '${dt.day} ${months[dt.month - 1]}';
    if (quickIndex == 0) return 'Hari Ini • $shortDateStr';
    if (quickIndex == 1) return 'Besok • $shortDateStr';
    return '${days[dt.weekday % 7]}, $shortDateStr';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.forest),
              SizedBox(height: 14),
              Text(
                'Mengambil prakiraan cuaca dinamis dari server...',
                style: TextStyle(fontSize: 13.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.red),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.forest, foregroundColor: Colors.white),
                onPressed: () => _loadAllWeatherData(showToast: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Muat Ulang'),
              ),
            ],
          ),
        ),
      );
    }

    final tier = _evaluateCurrentTier();

    final Color primaryColor;
    final Color softBgColor;
    final Color borderColor;
    final IconData statusIcon;

    switch (tier) {
      case _AlertTier.safeGreen:
        primaryColor = const Color(0xFF004C22);
        softBgColor = const Color(0xFFDCFCE7);
        borderColor = const Color(0xFF86EFAC);
        statusIcon = Icons.wb_sunny_rounded;
        break;
      case _AlertTier.cautionYellow:
        primaryColor = const Color(0xFFB45309);
        softBgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFFCD34D);
        statusIcon = Icons.cloud_queue_rounded;
        break;
      case _AlertTier.dangerRed:
        primaryColor = const Color(0xFFDC2626);
        softBgColor = const Color(0xFFFEE2E2);
        borderColor = const Color(0xFFFCA5A5);
        statusIcon = Icons.thunderstorm_rounded;
        break;
    }

    final activeDay = _dailyList.isNotEmpty ? _dailyList[_selectedDayIndex] : null;

    final displaySlots = activeDay == null
        ? <_HourlyForecastItem>[]
        : activeDay.hours
            .where((h) => h.time.hour >= 7 && h.time.hour <= 19 && h.time.hour % 2 == 1)
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Lokasi GPS Real-Time + Tombol Tes Alarm & Refresh
          AppHeader(
            subtitle: _locationName.toUpperCase(),
            padding: EdgeInsets.zero,
            height: null,
            logoSize: 42,
            logoIcon: statusIcon,
            logoBg: softBgColor,
            logoColor: primaryColor,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Tes Bunyi Alarm Hujan',
                  child: AppHeaderActionButton(
                    icon: Icons.notifications_active_outlined,
                    onTap: () => _triggerHeavyRainAlarm(isManualTest: true),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Perbarui GPS & Cuaca',
                  child: AppHeaderActionButton(
                    icon: Icons.sync_rounded,
                    onTap: () => _loadAllWeatherData(showToast: true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            '${_dynamicGreeting()}, $_namaPetani',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Kartu Utama Suhu Presisi Dinamis + Indikator Hijau / Kuning / Merah
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kondisi Kebun $_locationName',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '${_currentTemp.toStringAsFixed(1)}°C',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentCondition,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w800,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Curah ${_currentRainMm.toStringAsFixed(1)} mm • Peluang $_currentRainProb% • Lembap $_currentHumidity%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: softBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, size: 28, color: primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Banner Status Warna Hijau / Kuning / Merah
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: softBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tier == _AlertTier.safeGreen
                              ? Icons.check_rounded
                              : Icons.warning_amber_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _backendWarningMsg,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 3. Pemilih Tanggal Prakiraan Akurat (14 Hari Ke Depan) + Kalender Terbatas Akurat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prakiraan ${_dailyList.length} Hari Ke Depan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              TextButton.icon(
                onPressed: _openAccurateCalendarPicker,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF004C22),
                  backgroundColor: const Color(0xFFDCFCE7),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.calendar_month_rounded, size: 17),
                label: const Text(
                  'Pilih Tanggal',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dailyList.length,
              // ignore: unnecessary_underscores
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final day = _dailyList[idx];
                final isSelected = idx == _selectedDayIndex;
                final isDayRainy = day.totalRainMm >= 4.0;
                final isDayCaution = !isDayRainy && (day.maxRainProb >= 55 || day.totalRainMm > 0);

                final Color dotColor = isDayRainy
                    ? const Color(0xFFDC2626)
                    : (isDayCaution ? const Color(0xFFD97706) : const Color(0xFF16A34A));

                return GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF004C22) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF004C22) : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatIndoDate(day.date, quickIndex: idx),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${day.maxTemp.toStringAsFixed(0)}° / ${day.minTemp.toStringAsFixed(0)}°C  •  Hujan ${day.maxRainProb}%',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? const Color(0xFFBBF7D0) : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // 4. KARTU PINTAR: KAPAN PANAS TERIK vs KAPAN HUJAN + GARIS WAKTU VISUAL
          if (activeDay != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: cardDeco(radius: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Jadwal Jemur & Deteksi Hujan',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatIndoDate(activeDay.date, quickIndex: _selectedDayIndex),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Baris 1: Jendela Panas Terik (Hijau)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wb_sunny_rounded, color: Color(0xFF15803D), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jendela Panas Terik (Aman Jemur)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF166534),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeDay.hotWindow,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF14532D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Baris 2: Perkiraan Waktu Hujan (Merah/Kuning)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.water_drop_rounded, color: Color(0xFFDC2626), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Perkiraan Waktu Hujan',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeDay.rainWindow,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF7F1D1D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Garis Waktu Visual 06:00 - 20:00 (Hijau = Panas, Kuning = Mendung, Merah = Hujan)
                  const Text(
                    'Peta Warna Cuaca (06:00 – 20:00)',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 16,
                      child: Row(
                        children: activeDay.hours
                            .where((h) => h.time.hour >= 6 && h.time.hour <= 20)
                            .map((h) {
                          final Color barColor = h.isHeavyRain
                              ? const Color(0xFFDC2626)
                              : (h.isCaution ? const Color(0xFFF59E0B) : const Color(0xFF16A34A));
                          return Expanded(
                            child: Tooltip(
                              message:
                                  '${h.time.hour.toString().padLeft(2, '0')}:00 • ${h.tempC.toStringAsFixed(1)}°C (${h.label})',
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                                color: barColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('06:00', style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                      Text('10:00', style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                      Text('14:00', style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                      Text('18:00', style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                      Text('20:00', style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    activeDay.summaryVerdict,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 18),

          // 5. Rincian Prakiraan Per Jam pada Tanggal Terpilih
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: cardDeco(radius: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Prakiraan Per Jam',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (activeDay != null)
                      Text(
                        _formatIndoDate(activeDay.date, quickIndex: _selectedDayIndex),
                        style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final slot in displaySlots) _buildHourlySlotTile(slot),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlySlotTile(_HourlyForecastItem s) {
    final Color tileBg;
    final Color tileBorder;
    final Color accent;
    final IconData icon;

    if (s.isHeavyRain) {
      tileBg = const Color(0xFFFEF2F2);
      tileBorder = const Color(0xFFFECACA);
      accent = const Color(0xFFDC2626);
      icon = Icons.thunderstorm_rounded;
    } else if (s.isCaution) {
      tileBg = const Color(0xFFFFFBEB);
      tileBorder = const Color(0xFFFDE68A);
      accent = const Color(0xFFD97706);
      icon = Icons.cloud_queue_rounded;
    } else {
      tileBg = const Color(0xFFF0FDF4);
      tileBorder = const Color(0xFFBBF7D0);
      accent = const Color(0xFF15803D);
      icon = Icons.wb_sunny_rounded;
    }

    final timeLabel = '${s.time.hour.toString().padLeft(2, '0')}:00';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tileBorder),
      ),
      child: Row(
        children: [
          Text(
            timeLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.label} (${s.rainProb}%)',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.advice,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${s.tempC.toStringAsFixed(1)}°C',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}