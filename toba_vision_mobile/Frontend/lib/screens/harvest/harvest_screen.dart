import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../services/offline_service.dart';
import '../../services/panen_service.dart';
import '../../widgets/app_header.dart';
import 'harvest_all_musim_screen.dart';
import 'harvest_edit_screen.dart';

class HarvestScreen extends StatefulWidget {
  final bool showBack;
  final String idSiklus;

  const HarvestScreen({
    super.key,
    this.showBack = false,
    this.idSiklus = "siklus_2026_01",
  });

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  int _selectedPeriod = 0; // 0: Musim Ini, 1: Semua
  final List<String> _periods = ['Musim Ini', 'Semua'];

  int _activeStep = 1; // Mulai dari P1
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isClosingSeason = false;

  // State Lokasi Dinamis (Otomatis dari GPS / Cache Hive)
  String _currentLocationLabel = 'Mendeteksi lokasi...';
  bool _isFetchingLocation = false;

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _revenueController = TextEditingController();

  // Stats Dynamic (Dimulai dari 0, Modal otomatis ditarik dari Fitur Finansial)
  double _totalModal = 0.0;
  double _totalPendapatan = 0.0;
  double _estimasiLaba = 0.0;

  final List<String> _stages = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7'];

  // State Data P1-P7 (Dimulai dari 0)
  List<Map<String, dynamic>> _stagesData = List.generate(7, (i) {
    return {
      'step': i + 1,
      'stage': 'P${i + 1}',
      'weight': 0.0,
      'revenue': 0.0,
    };
  });

  @override
  void initState() {
    super.initState();
    _loadLocalAndSyncHarvest();
    _detectCurrentLocation();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _revenueController.dispose();
    super.dispose();
  }

  String _resolveActiveUid() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid.isNotEmpty) {
      return currentUser.uid;
    }
    final localUser = OfflineService.getUserData();
    final localUid = localUser['uid']?.toString().trim() ?? '';
    return localUid.isNotEmpty ? localUid : 'guest_petani';
  }

  // ==========================================
  // DETEKSI LOKASI REAL-TIME (GPS + REVERSE GEOCODING + HIVE CACHE)
  // ==========================================
  Future<void> _detectCurrentLocation({bool forceRefresh = false}) async {
    if (_isFetchingLocation) return;

    try {
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');

      final String? cachedLoc = box.get('current_user_location')?.toString();
      if (cachedLoc != null && cachedLoc.isNotEmpty && mounted) {
        setState(() => _currentLocationLabel = cachedLoc);
      }

      if (mounted) setState(() => _isFetchingLocation = true);

      double? lat;
      double? lon;

      try {
        if (!kIsWeb) {
          final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            throw Exception('Location service disabled');
          }
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception('Location permission denied');
        }

        final Position pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        lat = pos.latitude;
        lon = pos.longitude;
      } catch (gpsError) {
        debugPrint('GPS fallback ke lokasi jaringan: $gpsError');
        final ipRes = await http
            .get(Uri.parse('https://ipapi.co/json/'))
            .timeout(const Duration(seconds: 5));
        if (ipRes.statusCode == 200) {
          final ipData = jsonDecode(ipRes.body);
          final String city = (ipData['city'] ?? '').toString();
          final String region = (ipData['region'] ?? '').toString();
          if (city.isNotEmpty) {
            final fallbackPlace = region.isNotEmpty ? '$city • $region' : city;
            await box.put('current_user_location', fallbackPlace);
            if (mounted) setState(() => _currentLocationLabel = fallbackPlace);
            return;
          }
        }
      }

      if (lat != null && lon != null) {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&accept-language=id',
        );
        final response = await http.get(
          uri,
          headers: {'User-Agent': 'TobaVisionApp/1.0'},
        ).timeout(const Duration(seconds: 6));

        String resolvedPlace = '${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)}';

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final Map<String, dynamic> address =
              Map<String, dynamic>.from(data['address'] ?? {});

          final String? subDistrict = address['suburb'] ??
              address['village'] ??
              address['town'] ??
              address['municipality'];
          final String? city = address['city'] ??
              address['county'] ??
              address['regency'] ??
              address['state_district'];

          if (subDistrict != null && city != null) {
            resolvedPlace = '$subDistrict • $city';
          } else if (city != null) {
            resolvedPlace = city;
          } else if (subDistrict != null) {
            resolvedPlace = subDistrict;
          }
        }

        await box.put('current_user_location', resolvedPlace);
        if (mounted) setState(() => _currentLocationLabel = resolvedPlace);
      }
    } catch (e) {
      debugPrint('Gagal mendeteksi lokasi: $e');
      if (mounted && _currentLocationLabel == 'Mendeteksi lokasi...') {
        setState(() => _currentLocationLabel = 'Lokasi Saat Ini');
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  /// Dialog opsi perbarui GPS atau ubah nama lokasi/blok lahan secara manual
  Future<void> _showLocationOptionsDialog() async {
    final TextEditingController manualLocCtrl = TextEditingController(
      text: _currentLocationLabel.startsWith('Mendeteksi') ? '' : _currentLocationLabel,
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: Color(0xFF064E3B), size: 20),
            SizedBox(width: 8),
            Text(
              'Lokasi Lahan Saat Ini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lokasi terdeteksi otomatis dari GPS perangkat, atau sesuaikan nama blok lahan Anda:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: manualLocCtrl,
              decoration: InputDecoration(
                hintText: 'Contoh: Lahan Blok A • Jember',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _detectCurrentLocation(forceRefresh: true);
            },
            icon: const Icon(Icons.my_location_rounded, size: 15, color: Color(0xFF065F46)),
            label: const Text('Deteksi GPS', style: TextStyle(color: Color(0xFF065F46))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF064E3B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final text = manualLocCtrl.text.trim();
              if (text.isNotEmpty) {
                final box = Hive.isBoxOpen('toba_offline_box')
                    ? Hive.box('toba_offline_box')
                    : await Hive.openBox('toba_offline_box');
                await box.put('current_user_location', text);
                if (mounted) setState(() => _currentLocationLabel = text);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  /// Membaca arsip musim tertutup dari Hive untuk menentukan nomor siklus aktif & info musim terakhir
  Map<String, dynamic> _getSeasonArchiveMeta(Box box) {
    final rawArchive = box.get('closed_seasons_archive');
    if (rawArchive != null && rawArchive.toString().isNotEmpty) {
      try {
        final List decoded = jsonDecode(rawArchive.toString());
        if (decoded.isNotEmpty) {
          final latestClosed = Map<String, dynamic>.from(decoded.first as Map);
          return {
            'activeSeasonNumber': decoded.length + 1,
            'lastClosedSeason': latestClosed,
          };
        }
      } catch (e) {
        debugPrint('Gagal membaca arsip musim: $e');
      }
    }
    return {
      'activeSeasonNumber': 1,
      'lastClosedSeason': null,
    };
  }

  /// Mengisi controller input sesuai tahapan yang sedang dipilih user
  void _syncControllersForActiveStep() {
    final current = _stagesData[_activeStep - 1];
    final double w = (current['weight'] as num?)?.toDouble() ?? 0.0;
    final double r = (current['revenue'] as num?)?.toDouble() ?? 0.0;

    _weightController.text = w > 0 ? (w % 1 == 0 ? w.toInt().toString() : w.toString()) : '';
    _revenueController.text = r > 0 ? _formatRupiah(r) : '';
  }

  /// Menghitung ulang Total Pendapatan & Estimasi Laba/Rugi Bersih
  void _recalculateTotals() {
    double sumRev = 0.0;
    for (final s in _stagesData) {
      sumRev += (s['revenue'] as num?)?.toDouble() ?? 0.0;
    }
    _totalPendapatan = sumRev;
    _estimasiLaba = _totalPendapatan - _totalModal;
  }

  Future<void> _saveStagesToHive() async {
    try {
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');
      await box.put('active_harvest_stages_${widget.idSiklus}', jsonEncode(_stagesData));
    } catch (e) {
      debugPrint("Gagal menyimpan state panen ke Hive: $e");
    }
  }

  // ==========================================
  // FETCH DATA PANEN, ARSIP CLOUD, & MODAL FINANSIAL DARI HIVE / API
  // ==========================================
  Future<void> _loadLocalAndSyncHarvest() async {
    setState(() => _isLoading = true);
    try {
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');

      // 1. Ambil Modal otomatis dari Total Biaya aktif di Fitur Finansial
      _totalModal =
          (box.get('active_finance_total_${widget.idSiklus}', defaultValue: 0.0) as num).toDouble();

      // 2. Muat data tahapan P1-P7 aktif dari Hive
      final rawStages = box.get('active_harvest_stages_${widget.idSiklus}');
      if (rawStages != null && rawStages.toString().isNotEmpty) {
        final List decoded = jsonDecode(rawStages.toString());
        _stagesData = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _stagesData = List.generate(7, (i) {
          return {
            'step': i + 1,
            'stage': 'P${i + 1}',
            'weight': 0.0,
            'revenue': 0.0,
          };
        });
      }

      if (mounted) {
        setState(() {
          _recalculateTotals();
          _syncControllersForActiveStep();
        });
      }

      // 3. Tarik arsip musim dari Cloud Firestore agar persistensi lintas port/device terjaga
      final String uidPetani = _resolveActiveUid();
      final cloudArchives = await ApiService.getArsipMusimPetani(uidPetani);
      if (cloudArchives.isNotEmpty) {
        await box.put('closed_seasons_archive', jsonEncode(cloudArchives));
      }

      // 4. Sync antrean offline
      await PanenService.syncPendingData(widget.idSiklus);

      // 5. Sinkronisasi data aktif dari Backend FastAPI/Firestore
      final finRes = await ApiService.getRekapFinansial(widget.idSiklus);
      if (finRes != null) {
        final double remoteModal =
            ((finRes['total_biaya'] ?? finRes['total_pengeluaran']) as num?)?.toDouble() ?? 0.0;
        if (remoteModal != _totalModal) {
          _totalModal = remoteModal;
          await box.put('active_finance_total_${widget.idSiklus}', _totalModal);
        }
      }

      final panenRes = await ApiService.getRekapPanen(widget.idSiklus);
      if (panenRes != null && panenRes['riwayat_petikan'] is List) {
        final List remotePetikan = panenRes['riwayat_petikan'] as List;
        final double localWeightSum = _stagesData.fold(
          0.0,
          (sum, item) => sum + ((item['weight'] as num?)?.toDouble() ?? 0.0),
        );

        // Jika lokal kosong (misal port web baru) sementara server punya data aktif, pulihkan dari server
        if (localWeightSum == 0 && remotePetikan.isNotEmpty) {
          for (final item in remotePetikan) {
            final int step = (item['petikan_ke'] as num?)?.toInt() ?? 0;
            if (step >= 1 && step <= 7) {
              _stagesData[step - 1]['weight'] =
                  (item['berat_kg'] as num?)?.toDouble() ?? 0.0;
              _stagesData[step - 1]['revenue'] =
                  (item['total_pendapatan'] as num?)?.toDouble() ?? 0.0;
            }
          }
          await _saveStagesToHive();
        }
      }

      if (mounted) {
        setState(() {
          _recalculateTotals();
          _syncControllersForActiveStep();
        });
      }
    } catch (e) {
      debugPrint("Offline / Error fetching harvest data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // SIMPAN PETIKAN KE PANEN SERVICE & HIVE
  // ==========================================
  Future<void> _handleSavePetikan() async {
    final double weight =
        double.tryParse(_weightController.text.replaceAll(',', '.').trim()) ?? 0.0;
    final double revenue =
        double.tryParse(_revenueController.text.replaceAll(RegExp(r'[^0-9]'), '').trim()) ?? 0.0;

    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan berat tembakau (kg) lebih dari 0!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await PanenService.tambahPanen(
        idSiklus: widget.idSiklus,
        petikanKe: _activeStep,
        beratKg: weight,
        totalPendapatan: revenue,
        isOnline: true,
        keterangan: 'Petikan P$_activeStep',
      );

      setState(() {
        _stagesData[_activeStep - 1]['weight'] = weight;
        _stagesData[_activeStep - 1]['revenue'] = revenue;
        _recalculateTotals();
      });

      await _saveStagesToHive();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Timbangan P$_activeStep (${weight.toStringAsFixed(0)} kg) berhasil dicatat!'),
          backgroundColor: const Color(0xFF064E3B),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan panen: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ==========================================
  // TUTUP BUKU & SIMPAN REKAP (ARSIPKAN KE FIRESTORE + HIVE & RESET KE 0)
  // ==========================================
  Future<void> _confirmAndCloseSeason() async {
    final double totalWeightKg =
        _stagesData.fold(0.0, (sum, item) => sum + ((item['weight'] as num?)?.toDouble() ?? 0.0));

    if (totalWeightKg <= 0 && _totalModal <= 0 && _totalPendapatan <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada data panen atau biaya pengeluaran untuk ditutup buku.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Color(0xFFBE123C)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tutup Buku & Simpan Rekap',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Menutup buku akan mengarsipkan seluruh catatan Panen & Biaya Finansial musim ini ke Cloud Firestore & menu "Rekap Semua Musim", lalu mereset kedua halaman kembali ke 0 untuk musim tanam berikutnya.',
              style: TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildSummaryDialogRow('Total Hasil Panen', '${totalWeightKg.toStringAsFixed(0)} kg'),
                  const SizedBox(height: 6),
                  _buildSummaryDialogRow('Total Modal (Finansial)', 'Rp ${_formatRupiah(_totalModal)}'),
                  const SizedBox(height: 6),
                  _buildSummaryDialogRow('Total Pendapatan', 'Rp ${_formatRupiah(_totalPendapatan)}'),
                  const Divider(height: 16),
                  _buildSummaryDialogRow(
                    'Laba / Rugi Bersih',
                    '${_estimasiLaba >= 0 ? "+" : "-"}Rp ${_formatRupiah(_estimasiLaba.abs())}',
                    isHighlight: true,
                    isProfit: _estimasiLaba >= 0,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBE123C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Tutup Buku', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isClosingSeason = true);

    try {
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');

      final String uidPetani = _resolveActiveUid();

      // 1. Hitung breakdown kategori dari riwayat finansial aktif
      final Map<String, double> categoryBreakdown = {
        'Buruh Tani / Upah': 0.0,
        'Pupuk & Nutrisi': 0.0,
        'Bibit & Olah Lahan': 0.0,
        'Lainnya / Tambahan': 0.0,
      };

      final rawFinHistory = box.get('active_finance_history_${widget.idSiklus}');
      if (rawFinHistory != null && rawFinHistory.toString().isNotEmpty) {
        final List finItems = jsonDecode(rawFinHistory.toString());
        for (final item in finItems) {
          final String cat = (item['category'] ?? 'Lainnya / Tambahan').toString();
          final double amt = (item['raw_amount'] as num?)?.toDouble() ?? 0.0;
          if (categoryBreakdown.containsKey(cat)) {
            categoryBreakdown[cat] = (categoryBreakdown[cat] ?? 0.0) + amt;
          } else {
            categoryBreakdown['Lainnya / Tambahan'] = (categoryBreakdown['Lainnya / Tambahan'] ?? 0.0) + amt;
          }
        }
      }

      // 2. Muat daftar arsip musim sebelumnya
      List<Map<String, dynamic>> existingArchive = [];
      final rawArchive = box.get('closed_seasons_archive');
      if (rawArchive != null && rawArchive.toString().isNotEmpty) {
        final List decoded = jsonDecode(rawArchive.toString());
        existingArchive = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      final int nextSeasonNumber = existingArchive.length + 1;
      final now = DateTime.now();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final String formattedDate = '${now.day} ${months[now.month - 1]} ${now.year}';

      final Map<String, dynamic> newArchiveEntry = {
        'uid_petani': uidPetani,
        'title': 'Musim Tanam #$nextSeasonNumber (${now.year})',
        'period': 'Ditutup $formattedDate • $_currentLocationLabel',
        'expenses': 'Rp ${_formatRupiah(_totalModal)}',
        'raw_expenses': _totalModal,
        'revenue': 'Rp ${_formatRupiah(_totalPendapatan)}',
        'raw_revenue': _totalPendapatan,
        'profit': '${_estimasiLaba >= 0 ? "+" : "-"}Rp ${_formatRupiah(_estimasiLaba.abs())}',
        'raw_profit': _estimasiLaba,
        'harvest': '${totalWeightKg.toStringAsFixed(0)} kg tembakau',
        'raw_weight': totalWeightKg,
        'category_breakdown': categoryBreakdown,
        'stages': _stagesData,
        'status': 'Selesai',
      };

      // 3. Simpan arsip ke Cloud Firestore & bersihkan data aktif siklus di server
      await ApiService.tutupSiklusPanen(
        widget.idSiklus,
        archivePayload: newArchiveEntry,
      );

      // 4. Perbarui arsip lokal Hive
      existingArchive.insert(0, newArchiveEntry);
      await box.put('closed_seasons_archive', jsonEncode(existingArchive));

      // 5. Reset total state Finansial & Panen aktif kembali ke 0 (Lembaran Baru)
      await box.delete('active_finance_history_${widget.idSiklus}');
      await box.put('active_finance_total_${widget.idSiklus}', 0.0);
      await box.delete('active_harvest_stages_${widget.idSiklus}');
      await box.put('season_closed_${widget.idSiklus}', true);

      if (mounted) {
        setState(() {
          _activeStep = 1;
          _totalModal = 0.0;
          _totalPendapatan = 0.0;
          _estimasiLaba = 0.0;
          _stagesData = List.generate(7, (i) {
            return {
              'step': i + 1,
              'stage': 'P${i + 1}',
              'weight': 0.0,
              'revenue': 0.0,
            };
          });
          _weightController.clear();
          _revenueController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Musim Tanam #$nextSeasonNumber tersimpan di Cloud Firestore! Siap mencatat Musim Tanam #${nextSeasonNumber + 1}.',
            ),
            backgroundColor: const Color(0xFF064E3B),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menutup buku musim: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isClosingSeason = false);
    }
  }

  Widget _buildSummaryDialogRow(String label, String value, {bool isHighlight = false, bool isProfit = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 13 : 12,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
            color: isHighlight
                ? (isProfit ? const Color(0xFF065F46) : const Color(0xFFBE123C))
                : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  String _formatRupiah(double val) {
    String numStr = val.toInt().toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Box>(
      future: Hive.isBoxOpen('toba_offline_box')
          ? Future.value(Hive.box('toba_offline_box'))
          : Hive.openBox('toba_offline_box'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F9FB),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF064E3B)),
            ),
          );
        }

        final openedBox = snapshot.data!;

        return ValueListenableBuilder(
          valueListenable: openedBox.listenable(
            keys: [
              'active_finance_total_${widget.idSiklus}',
              'closed_seasons_archive',
            ],
          ),
          builder: (context, Box box, _) {
            final double latestFinanceTotal =
                (box.get('active_finance_total_${widget.idSiklus}', defaultValue: 0.0) as num).toDouble();

            if (latestFinanceTotal != _totalModal) {
              _totalModal = latestFinanceTotal;
              _estimasiLaba = _totalPendapatan - _totalModal;
            }

            final seasonMeta = _getSeasonArchiveMeta(box);
            final int activeSeasonNumber = seasonMeta['activeSeasonNumber'] as int;
            final Map<String, dynamic>? lastClosedSeason =
                seasonMeta['lastClosedSeason'] as Map<String, dynamic>?;

            final double totalWeightKg = _stagesData.fold(
              0.0,
              (sum, item) => sum + ((item['weight'] as num?)?.toDouble() ?? 0.0),
            );
            final bool isCurrentSeasonEmpty =
                totalWeightKg == 0 && _totalPendapatan == 0 && _totalModal == 0;

            return Scaffold(
              backgroundColor: const Color(0xFFF7F9FB),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppHeader(
                        showBack: widget.showBack,
                        backgroundColor: const Color(0xFFF7F9FB),
                        logoIcon: Icons.agriculture_rounded,
                        logoBg: const Color(0xFFA7F3D0),
                        trailing: AppHeaderActionButton(
                          icon: _isLoading ? Icons.hourglass_top_rounded : Icons.sync_rounded,
                          onTap: () async {
                            await _loadLocalAndSyncHarvest();
                            await _detectCurrentLocation(forceRefresh: true);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sinkronisasi data panen & lokasi berhasil diperbarui!'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Color(0xFF064E3B),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            _buildTitleSection(activeSeasonNumber),
                            if (isCurrentSeasonEmpty && lastClosedSeason != null) ...[
                              const SizedBox(height: 14),
                              _buildLastClosedSeasonBanner(lastClosedSeason),
                            ],
                            const SizedBox(height: 12),
                            _buildPeriodSelector(),
                            const SizedBox(height: 16),
                            _buildStepTrackerCard(),
                            const SizedBox(height: 16),
                            _buildMilestoneProfitCard(),
                            const SizedBox(height: 16),
                            _buildWeighingInputCard(),
                            const SizedBox(height: 20),
                            _buildCtaButtonSection(),
                            const SizedBox(height: 20),
                            _buildCloseSeasonCard(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Banner info ringkasan musim terakhir yang baru ditutup (tampil saat kondisi panen aktif = 0)
  Widget _buildLastClosedSeasonBanner(Map<String, dynamic> lastSeason) {
    final String seasonTitle = (lastSeason['title'] ?? 'Musim Sebelumnya').toString();
    final String harvestWeight = (lastSeason['harvest'] ?? '0 kg').toString();
    final String profitText = (lastSeason['profit'] ?? 'Rp 0').toString();
    final double rawProfit = (lastSeason['raw_profit'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF065F46).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF065F46), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$seasonTitle telah diarsipkan',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF064E3B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Panen: $harvestWeight • Laba: $profitText',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: rawProfit >= 0 ? const Color(0xFF047857) : const Color(0xFFBE123C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF065F46),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFA7F3D0)),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HarvestAllMusimScreen()),
              );
            },
            child: const Text(
              'Lihat Arsip',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(int activeSeasonNumber) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.spa_rounded, size: 13, color: Color(0xFF065F46)),
                  const SizedBox(width: 4),
                  Text(
                    'Siklus Aktif: Musim Tanam #$activeSeasonNumber',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: _showLocationOptionsDialog,
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F0F8),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: const Color(0xFFCBD5E1).withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _isFetchingLocation
                        ? const SizedBox(
                            width: 11,
                            height: 11,
                            child: CircularProgressIndicator(strokeWidth: 1.8, color: Color(0xFF064E3B)),
                          )
                        : const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF064E3B)),
                    const SizedBox(width: 4),
                    Text(
                      _currentLocationLabel,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF064E3B)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Monitoring Siklus Panen',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Color(0xFF064E3B),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pantau dan catat bobot pemetikan daun tembakau secara berkala.',
          style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PILIH PERIODE',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_periods.length, (index) {
              final isSelected = _selectedPeriod == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    if (index == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HarvestAllMusimScreen()),
                      ).then((_) {
                        if (mounted) setState(() => _selectedPeriod = 0);
                      });
                    } else {
                      setState(() => _selectedPeriod = index);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF064E3B) : Colors.white,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF064E3B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          _periods[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTrackerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Siklus Petikan Daun',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.eco_rounded, size: 12, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Text(
                      'P$_activeStep Aktif',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 67,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 17,
                  left: 18,
                  right: 18,
                  child: Row(
                    children: List.generate(6, (segIdx) {
                      final leftStepWeight = (_stagesData[segIdx]['weight'] as num?)?.toDouble() ?? 0.0;
                      final rightStepNum = segIdx + 2;
                      Color lineColor = const Color(0xFFE2E8F0);
                      if (rightStepNum == _activeStep) {
                        lineColor = const Color(0xFFF59E0B);
                      } else if (leftStepWeight > 0) {
                        lineColor = const Color(0xFF166534);
                      }
                      return Expanded(child: Container(height: 2.5, color: lineColor));
                    }),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_stages.length, (index) {
                    final stepNum = index + 1;
                    final double stepWeight = (_stagesData[index]['weight'] as num?)?.toDouble() ?? 0.0;
                    final bool isActive = stepNum == _activeStep;
                    final bool isDone = !isActive && stepWeight > 0;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeStep = stepNum;
                          _syncControllersForActiveStep();
                        });
                      },
                      onLongPress: () async {
                        setState(() => _activeStep = stepNum);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HarvestEditScreen(
                              initialStep: stepNum,
                              stageName: _stages[index],
                            ),
                          ),
                        );
                        if (result != null && mounted) {
                          setState(() {
                            _weightController.text = result['weight'] ?? _weightController.text;
                            _revenueController.text = result['revenue'] ?? _revenueController.text;
                          });
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFF59E0B)
                                  : isDone
                                      ? const Color(0xFF166534)
                                      : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFFFDE68A)
                                    : isDone
                                        ? const Color(0xFF166534)
                                        : const Color(0xFFE2E8F0),
                                width: isActive ? 3 : 1,
                              ),
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                  : Text(
                                      '$stepNum',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isActive ? Colors.white : const Color(0xFF94A3B8),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _stages[index],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
                              color: isActive
                                  ? const Color(0xFFD97706)
                                  : isDone
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneProfitCard() {
    final double bepPercent = _totalModal > 0
        ? ((_totalPendapatan / _totalModal) * 100).clamp(0.0, 100.0)
        : (_totalPendapatan > 0 ? 100.0 : 0.0);
    final bool isBepReached = _totalPendapatan > 0 && _totalPendapatan >= _totalModal;

    int modalFlex = 1;
    int profitFlex = 0;
    if (_totalModal <= 0 && _totalPendapatan <= 0) {
      modalFlex = 1;
      profitFlex = 0;
    } else if (_totalPendapatan <= _totalModal) {
      modalFlex = (_totalPendapatan * 100).round();
      profitFlex = 0;
    } else {
      final double totalBar = _totalPendapatan;
      modalFlex = ((_totalModal / totalBar) * 100).round().clamp(1, 99);
      profitFlex = 100 - modalFlex;
    }

    double maxWeight = 0.0;
    for (final s in _stagesData) {
      final w = (s['weight'] as num?)?.toDouble() ?? 0.0;
      if (w > maxWeight) maxWeight = w;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target Keuntungan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 2),
                  Text('Pencapaian Modal & Profit Bersih', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _totalPendapatan > 0
                      ? const Color(0xFFDCFCE7).withValues(alpha: 0.6)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp ${_formatRupiah(_totalPendapatan)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _totalPendapatan > 0 ? const Color(0xFF064E3B) : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${bepPercent.toStringAsFixed(1)}% BEP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _totalPendapatan > 0 ? const Color(0xFF166534) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isBepReached ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isBepReached ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flag_rounded,
                          size: 14,
                          color: _totalModal > 0 ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Modal (Finansial): Rp ${_formatRupiah(_totalModal)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _totalModal > 0 ? const Color(0xFF064E3B) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      isBepReached
                          ? 'BEP TERCAPAI'
                          : (_totalModal > 0 ? 'PROSES BEP' : 'BELUM ADA MODAL'),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isBepReached ? const Color(0xFF166534) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9999),
                  child: Container(
                    height: 14,
                    color: const Color(0xFFE2E8F0),
                    child: (_totalModal <= 0 && _totalPendapatan <= 0)
                        ? const Center(
                            child: Text(
                              '0%',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                            ),
                          )
                        : Row(
                            children: [
                              if (modalFlex > 0)
                                Expanded(
                                  flex: modalFlex,
                                  child: Container(
                                    color: const Color(0xFF94A3B8),
                                    alignment: Alignment.center,
                                    child: const Text('MODAL', style: TextStyle(fontSize: 8, color: Colors.white)),
                                  ),
                                ),
                              if (profitFlex > 0)
                                Expanded(
                                  flex: profitFlex,
                                  child: Container(
                                    color: const Color(0xFF166534),
                                    alignment: Alignment.center,
                                    child: const Text('UNTUNG', style: TextStyle(fontSize: 8, color: Colors.white)),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bar Chart Distribusi Hasil Petikan (P1-P7)
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distribusi Hasil Petikan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              Text(
                'Per Tahapan (kg)',
                style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_stagesData.length, (idx) {
                final data = _stagesData[idx];
                final int stepNum = idx + 1;
                final double weightVal = (data['weight'] as num?)?.toDouble() ?? 0.0;
                final bool isActive = stepNum == _activeStep;
                final bool isDone = !isActive && weightVal > 0;

                final double barHeight = weightVal > 0 && maxWeight > 0
                    ? (22.0 + ((weightVal / maxWeight) * 54.0)).clamp(22.0, 76.0)
                    : (isActive ? 22.0 : 14.0);

                final Color barColor = isActive
                    ? const Color(0xFFF59E0B)
                    : isDone
                        ? const Color(0xFF166534)
                        : const Color(0xFFE2E8F0);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeStep = stepNum;
                      _syncControllersForActiveStep();
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        weightVal > 0 ? '${weightVal.toInt()} kg' : '-',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFFD97706)
                              : isDone
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 26,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['stage'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? const Color(0xFFD97706)
                              : isDone
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 14),

          // Kotak Laba/Rugi Bersih (Kiri) + Tombol Prev & Next Panen (Kanan)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _estimasiLaba > 0
                  ? const Color(0xFFDCFCE7).withValues(alpha: 0.6)
                  : _estimasiLaba < 0
                      ? const Color(0xFFFFF1F2)
                      : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _estimasiLaba > 0
                    ? const Color(0xFFA7F3D0)
                    : _estimasiLaba < 0
                        ? const Color(0xFFFFE4E6)
                        : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.savings_outlined,
                  color: _estimasiLaba > 0
                      ? const Color(0xFF064E3B)
                      : _estimasiLaba < 0
                          ? const Color(0xFFBE123C)
                          : const Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _estimasiLaba == 0
                            ? 'Rp 0'
                            : '${_estimasiLaba > 0 ? "+" : "-"}Rp ${_formatRupiah(_estimasiLaba.abs())}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _estimasiLaba > 0
                              ? const Color(0xFF064E3B)
                              : _estimasiLaba < 0
                                  ? const Color(0xFFBE123C)
                                  : const Color(0xFF475569),
                        ),
                      ),
                      const Text(
                        'Estimasi Laba/Rugi Bersih saat ini',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    if (_activeStep > 1)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF064E3B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _activeStep--;
                            _syncControllersForActiveStep();
                          });
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 14),
                        label: Text(
                          'Prev (P${_activeStep - 1})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    if (_activeStep < 7)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF064E3B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _activeStep++;
                            _syncControllersForActiveStep();
                          });
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: Text(
                          'Next Panen (P${_activeStep + 1})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeighingInputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Timbangan Petikan P$_activeStep',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const Text('Hari Ini', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Berat Tembakau (kg)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF064E3B)),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
                const Text('kg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Total Pendapatan (Rp)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _revenueController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButtonSection() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF064E3B),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isSaving ? null : _handleSavePetikan,
        icon: _isSaving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.check_circle_outline_rounded, size: 20),
        label: Text(
          _isSaving ? 'Menyimpan...' : 'Simpan Catatan Petikan P$_activeStep',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// Kartu Tutup Buku Musim
  Widget _buildCloseSeasonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE4E6)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.archive_outlined, color: Color(0xFFBE123C), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tutup Buku Musim',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: const Color(0xFFFFE4E6)),
                          ),
                          child: const Text(
                            'Akhir Musim',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFBE123C),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Simpan rekap hasil panen & biaya pengeluaran ke arsip semua musim, lalu mulai lembaran musim baru dari 0.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF1F2),
                foregroundColor: const Color(0xFFBE123C),
                side: const BorderSide(color: Color(0xFFFFE4E6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isClosingSeason ? null : _confirmAndCloseSeason,
              icon: _isClosingSeason
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Color(0xFFBE123C), strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline_rounded, size: 16),
              label: Text(
                _isClosingSeason ? 'Menutup Buku...' : 'Tutup Buku & Simpan Rekap',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}