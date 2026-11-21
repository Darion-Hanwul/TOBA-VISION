import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/api_service.dart';
import '../../services/panen_service.dart';
import '../../widgets/app_header.dart';
import 'finance_all_musim_screen.dart';
import 'finance_screen_edit_upload.dart';

class FinanceScreen extends StatefulWidget {
  final bool showBack;
  final String idSiklus;
  const FinanceScreen({
    super.key,
    this.showBack = false,
    this.idSiklus = "siklus_2026_01",
  });

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int _selectedPeriod = 0; // 0: Musim Ini, 1: Semua
  bool _isLoading = false;
  double _totalBiayaNum = 0.0;

  final List<String> _periods = ['Musim Ini', 'Semua'];

  // Definisi Master 4 Kategori Pengeluaran (Warna, Ikon, & Nilai Awal 0)
  final List<Map<String, dynamic>> _categoryTemplates = [
    {
      'name': 'Buruh Tani / Upah',
      'icon': Icons.groups_rounded,
      'color': const Color(0xFF065F46),
      'bg': const Color(0xFFD1FAE5),
    },
    {
      'name': 'Pupuk & Nutrisi',
      'icon': Icons.science_outlined,
      'color': const Color(0xFF4338CA),
      'bg': const Color(0xFFE0E7FF),
    },
    {
      'name': 'Bibit & Olah Lahan',
      'icon': Icons.spa_outlined,
      'color': const Color(0xFF115E59),
      'bg': const Color(0xFFCCFBF1),
    },
    {
      'name': 'Lainnya / Tambahan',
      'icon': Icons.category_outlined,
      'color': const Color(0xFF92400E),
      'bg': const Color(0xFFFEF3C7),
    },
  ];

  // State Dinamis Kategori & Riwayat (Dimulai dari 0 / Kosong)
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _recalculateCategoriesFromHistory();
    _loadLocalAndSyncFinansial();
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

  /// Mencocokkan nama kategori inputan user ke salah satu dari 4 pos kategori utama
  Map<String, dynamic> _resolveCategoryStyle(String rawCategory) {
    final lower = rawCategory.toLowerCase();
    if (lower.contains('buruh') || lower.contains('upah') || lower.contains('petik')) {
      return _categoryTemplates[0];
    } else if (lower.contains('pupuk') || lower.contains('nutrisi') || lower.contains('obat')) {
      return _categoryTemplates[1];
    } else if (lower.contains('bibit') || lower.contains('olah') || lower.contains('lahan') || lower.contains('traktor')) {
      return _categoryTemplates[2];
    } else {
      return _categoryTemplates[3];
    }
  }

  /// Menghitung ulang Total Biaya, Nominal per Kategori, dan Persentase secara sinkron
  void _recalculateCategoriesFromHistory() {
    final Map<String, double> sumPerCategory = {
      'Buruh Tani / Upah': 0.0,
      'Pupuk & Nutrisi': 0.0,
      'Bibit & Olah Lahan': 0.0,
      'Lainnya / Tambahan': 0.0,
    };

    double grandTotal = 0.0;

    for (final item in _historyItems) {
      final double amt = (item['raw_amount'] as num?)?.toDouble() ?? 0.0;
      final style = _resolveCategoryStyle((item['category'] ?? '').toString());
      final catName = style['name'] as String;
      sumPerCategory[catName] = (sumPerCategory[catName] ?? 0.0) + amt;
      grandTotal += amt;
    }

    _totalBiayaNum = grandTotal;

    _categories = _categoryTemplates.map((tpl) {
      final name = tpl['name'] as String;
      final amountVal = sumPerCategory[name] ?? 0.0;
      final int pct = grandTotal > 0 ? ((amountVal / grandTotal) * 100).round() : 0;

      return {
        'name': name,
        'raw_amount': amountVal,
        'amount': _formatCompactRupiah(amountVal),
        'percentage': '$pct%',
        'ratio': grandTotal > 0 ? (amountVal / grandTotal) : 0.0,
        'icon': tpl['icon'],
        'color': tpl['color'],
        'bg': tpl['bg'],
      };
    }).toList();
  }

  /// Simpan state finansial aktif ke Hive agar terbaca otomatis oleh PanenScreen (Modal)
  Future<void> _saveActiveFinansialToHive() async {
    try {
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');

      final serializedHistory = _historyItems.map((e) {
        return {
          'title': e['title'],
          'date': e['date'],
          'category': e['category'],
          'raw_amount': e['raw_amount'],
        };
      }).toList();

      await box.put('active_finance_history_${widget.idSiklus}', jsonEncode(serializedHistory));
      await box.put('active_finance_total_${widget.idSiklus}', _totalBiayaNum);
      await box.put('finance_initialized_${widget.idSiklus}', true);
    } catch (e) {
      debugPrint('Gagal menyimpan cache finansial lokal: $e');
    }
  }

  // ==========================================
  // FETCH REKAP FINANSIAL & SYNC ANTREAN OFFLINE
  // ==========================================
  Future<void> _loadLocalAndSyncFinansial() async {
    setState(() => _isLoading = true);

    try {
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');

      final String historyKey = 'active_finance_history_${widget.idSiklus}';
      final String initFlagKey = 'finance_initialized_${widget.idSiklus}';

      // 1. Muat data lokal Hive terlebih dahulu
      final rawJson = box.get(historyKey);
      if (rawJson != null && rawJson.toString().isNotEmpty) {
        final List decoded = jsonDecode(rawJson.toString());
        _historyItems = decoded.map((e) {
          final double amt = (e['raw_amount'] as num?)?.toDouble() ?? 0.0;
          final cat = (e['category'] ?? 'Lainnya / Tambahan').toString();
          final style = _resolveCategoryStyle(cat);
          return {
            'title': (e['title'] ?? 'Pengeluaran').toString(),
            'date': (e['date'] ?? 'Hari ini').toString(),
            'category': style['name'],
            'amount': '-Rp ${_formatRupiah(amt)}',
            'raw_amount': amt,
            'icon': style['icon'],
            'color': style['color'],
            'bg': style['bg'],
          };
        }).toList();
      } else {
        _historyItems = [];
      }

      if (mounted) {
        setState(() {
          _recalculateCategoriesFromHistory();
        });
      }

      // 2. Sync antrean offline yang belum terkirim ke server
      await PanenService.syncPendingData(widget.idSiklus);

      // 3. Hanya tarik dari backend JIKA aplikasi belum pernah diinisialisasi & musim belum ditutup
      final bool isSeasonClosed = box.get('season_closed_${widget.idSiklus}', defaultValue: false);
      final bool hasInitializedLocal = box.get(initFlagKey, defaultValue: false);

      if (!isSeasonClosed && !hasInitializedLocal && rawJson == null) {
        final res = await ApiService.getRekapFinansial(widget.idSiklus);
        if (res != null && res['riwayat_pengeluaran'] != null) {
          final List remoteList = res['riwayat_pengeluaran'];
          if (remoteList.isNotEmpty) {
            _historyItems = remoteList.map((item) {
              final double amt = (item['jumlah_biaya'] as num?)?.toDouble() ?? 0.0;
              final cat = (item['kategori'] ?? 'Lainnya / Tambahan').toString();
              final style = _resolveCategoryStyle(cat);
              return {
                'title': (item['nama_pengeluaran'] ?? 'Pengeluaran').toString(),
                'date': '${item['keterangan']?.toString().isNotEmpty == true ? item['keterangan'] : 'Tercatat'} • ${style['name']}',
                'category': style['name'],
                'amount': '-Rp ${_formatRupiah(amt)}',
                'raw_amount': amt,
                'icon': style['icon'],
                'color': style['color'],
                'bg': style['bg'],
              };
            }).toList();

            if (mounted) {
              setState(() {
                _recalculateCategoriesFromHistory();
              });
              await _saveActiveFinansialToHive();
            }
          }
        }
        await box.put(initFlagKey, true);
      }
    } catch (e) {
      debugPrint("Mode Offline / Gagal sinkronisasi backend: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Formatter Rupiah Penuh (contoh: 1.250.000)
  String _formatRupiah(double val) {
    String numStr = val.toInt().toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  // Formatter Rupiah Ringkas untuk Kartu Grid (contoh: Rp 0, Rp 850 rb, Rp 2,4 jt)
  String _formatCompactRupiah(double val) {
    if (val <= 0) return 'Rp 0';
    if (val >= 1000000) {
      double jt = val / 1000000.0;
      String formatted = jt % 1 == 0
          ? jt.toInt().toString()
          : jt.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '').replaceAll('.', ',');
      return 'Rp $formatted jt';
    } else if (val >= 1000) {
      double rb = val / 1000.0;
      String formatted = rb % 1 == 0 ? rb.toInt().toString() : rb.toStringAsFixed(1).replaceAll('.', ',');
      return 'Rp $formatted rb';
    }
    return 'Rp ${_formatRupiah(val)}';
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan Hive box 'toba_offline_box' sudah terbuka sebelum mendengarkan perubahannya
    return FutureBuilder<Box>(
      future: Hive.isBoxOpen('toba_offline_box')
          ? Future.value(Hive.box('toba_offline_box'))
          : Hive.openBox('toba_offline_box'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F7F5),
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
            final double cachedTotal =
                (box.get('active_finance_total_${widget.idSiklus}', defaultValue: 0.0) as num).toDouble();
            if (cachedTotal == 0.0 &&
                _totalBiayaNum > 0.0 &&
                box.get('active_finance_history_${widget.idSiklus}') == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _historyItems.clear();
                    _recalculateCategoriesFromHistory();
                  });
                }
              });
            }

            final seasonMeta = _getSeasonArchiveMeta(box);
            final int activeSeasonNumber = seasonMeta['activeSeasonNumber'] as int;
            final Map<String, dynamic>? lastClosedSeason =
                seasonMeta['lastClosedSeason'] as Map<String, dynamic>?;

            return Scaffold(
              backgroundColor: const Color(0xFFF4F7F5),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppHeader(
                        showBack: widget.showBack,
                        backgroundColor: const Color(0xE6F4F7F5),
                        showBottomBorder: true,
                        trailing: AppHeaderActionButton(
                          icon: _isLoading ? Icons.hourglass_top_rounded : Icons.sync_rounded,
                          onTap: () async {
                            await _loadLocalAndSyncFinansial();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Data keuangan berhasil diperbarui!'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Color(0xFF047857),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPageTitleSection(activeSeasonNumber),
                            if (_totalBiayaNum == 0 && lastClosedSeason != null) ...[
                              const SizedBox(height: 14),
                              _buildLastClosedSeasonBanner(lastClosedSeason),
                            ],
                            const SizedBox(height: 16),
                            _buildCircularSummaryCard(activeSeasonNumber),
                            const SizedBox(height: 20),
                            _buildExpenseCategoryGrid(),
                            const SizedBox(height: 20),
                            _buildPrimaryActionButton(),
                            const SizedBox(height: 20),
                            _buildExpenseHistoryList(),
                            const SizedBox(height: 20),
                            _buildAllSeasonRecapCard(),
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

  /// Banner info ringkasan musim terakhir yang baru ditutup (tampil saat kondisi finansial aktif = 0)
  Widget _buildLastClosedSeasonBanner(Map<String, dynamic> lastSeason) {
    final String seasonTitle = (lastSeason['title'] ?? 'Musim Sebelumnya').toString();
    final String totalExpenses = (lastSeason['expenses'] ?? 'Rp 0').toString();
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
                  'Modal: $totalExpenses • Hasil: $profitText',
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
                MaterialPageRoute(builder: (context) => const FinanceAllMusimScreen()),
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

  Widget _buildPageTitleSection(int activeSeasonNumber) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(width: 5),
              Text(
                'Siklus Aktif: Musim Tanam #$activeSeasonNumber',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Biaya & Pengeluaran Kebun',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            color: Color(0xFF022C22),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Kelola catatan pengeluaran operasional perkebunan dengan jelas dan tenang.',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xFF64748B),
          ),
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
                        MaterialPageRoute(
                          builder: (context) => const FinanceAllMusimScreen(),
                        ),
                      ).then((_) {
                        if (mounted) {
                          setState(() => _selectedPeriod = 0);
                        }
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
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF064E3B).withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
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

  Widget _buildCircularSummaryCard(int activeSeasonNumber) {
    final bool hasData = _totalBiayaNum > 0;
    final int activeCategoriesCount =
        _categories.where((c) => ((c['raw_amount'] as num?)?.toDouble() ?? 0) > 0).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x0D022C22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(150, 150),
                  painter: _RingProgressPainter(
                    categories: _categories,
                    hasData: hasData,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: hasData ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: hasData ? null : Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: hasData ? const Color(0xFF065F46) : const Color(0xFF94A3B8),
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'TOTAL BIAYA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Estimasi Musim Tanam #$activeSeasonNumber',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Rp ${_formatRupiah(_totalBiayaNum)}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
              color: hasData ? const Color(0xFF022C22) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasData
                ? 'Tercatat dari $activeCategoriesCount kategori pengeluaran operasional'
                : 'Lembaran baru siap digunakan — belum ada pengeluaran tercatat',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCategoryGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rincian Biaya',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '4 Pos Biaya',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final double rawAmt = (cat['raw_amount'] as num?)?.toDouble() ?? 0.0;
            final bool isActive = rawAmt > 0;

            final Color activeColor = cat['color'] as Color;
            final Color activeBg = cat['bg'] as Color;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? activeColor.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isActive ? activeBg : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cat['icon'] as IconData,
                          color: isActive ? activeColor : const Color(0xFF94A3B8),
                          size: 16,
                        ),
                      ),
                      Text(
                        cat['percentage'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive ? activeColor : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat['name'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cat['amount'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isActive ? activeColor : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrimaryActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14532D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FinanceScreenEditUpload(),
            ),
          );

          if (result != null && mounted) {
            final double amountVal = double.tryParse(
                  result['amount'].toString().replaceAll(RegExp(r'[^0-9]'), ''),
                ) ??
                0.0;
            final String title = result['title'] ?? 'Pengeluaran Baru';
            final String rawCategory = result['category'] ?? 'Lainnya / Tambahan';
            final style = _resolveCategoryStyle(rawCategory);
            final String matchedCategoryName = style['name'] as String;

            // Simpan ke Backend FastAPI / Antrean Hive
            await PanenService.tambahBiaya(
              idSiklus: widget.idSiklus,
              namaPengeluaran: title,
              kategori: matchedCategoryName,
              jumlahBiaya: amountVal,
            );

            setState(() {
              _historyItems.insert(0, {
                'title': title,
                'date': '${result['date'] ?? "Hari ini"} • $matchedCategoryName',
                'category': matchedCategoryName,
                'amount': '-Rp ${_formatRupiah(amountVal)}',
                'raw_amount': amountVal,
                'icon': style['icon'],
                'color': style['color'],
                'bg': style['bg'],
              });
              _recalculateCategoriesFromHistory();
            });

            await _saveActiveFinansialToHive();
          }
        },
        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
        label: const Text(
          'Tambah Catatan Biaya',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildExpenseHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Pengeluaran',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _historyItems.isNotEmpty ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _historyItems.isNotEmpty ? '${_historyItems.length} Catatan' : 'Kosong',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _historyItems.isNotEmpty ? const Color(0xFF065F46) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_historyItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 32, color: Color(0xFF94A3B8)),
                SizedBox(height: 8),
                Text(
                  'Belum ada riwayat pengeluaran',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tekan tombol "Tambah Catatan Biaya" di atas untuk mulai mencatat pengeluaran musim ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _historyItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = _historyItems[index];
              final Color itemColor = item['color'] as Color;
              final Color itemBg = item['bg'] as Color;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x0D022C22)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: itemBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item['icon'] as IconData, color: itemColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['date'] as String,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          item['amount'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: itemColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF8FAFC)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildMiniButton(
                          label: 'Edit',
                          icon: Icons.edit_outlined,
                          bg: const Color(0xFFF8FAFC),
                          fg: const Color(0xFF334155),
                          border: const Color(0xFFE2E8F0),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FinanceScreenEditUpload(
                                  initialData: item,
                                ),
                              ),
                            );

                            if (result != null && mounted) {
                              final double updatedAmt = double.tryParse(
                                    result['amount'].toString().replaceAll(RegExp(r'[^0-9]'), ''),
                                  ) ??
                                  (item['raw_amount'] as num).toDouble();
                              final String updatedCat = result['category'] ?? item['category'];
                              final style = _resolveCategoryStyle(updatedCat);

                              setState(() {
                                item['title'] = result['title'] ?? item['title'];
                                item['category'] = style['name'];
                                item['date'] = '${result['date'] ?? "Diperbarui"} • ${style['name']}';
                                item['raw_amount'] = updatedAmt;
                                item['amount'] = '-Rp ${_formatRupiah(updatedAmt)}';
                                item['icon'] = style['icon'];
                                item['color'] = style['color'];
                                item['bg'] = style['bg'];
                                _recalculateCategoriesFromHistory();
                              });

                              await _saveActiveFinansialToHive();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildMiniButton(
                          label: 'Hapus',
                          icon: Icons.delete_outline_rounded,
                          bg: const Color(0xFFFFF1F2),
                          fg: const Color(0xFFBE123C),
                          border: const Color(0xFFFFE4E6),
                          onTap: () => _confirmDeleteItem(index, item),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _confirmDeleteItem(int index, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFBE123C)),
            SizedBox(width: 8),
            Text(
              'Hapus Pengeluaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus catatan "${item['title']}" sebesar ${item['amount']}?',
              style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFBE123C), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tindakan ini tidak dapat dibatalkan.',
                      style: TextStyle(fontSize: 11, color: Color(0xFFBE123C), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBE123C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final deletedTitle = item['title'];
              setState(() {
                _historyItems.removeAt(index);
                _recalculateCategoriesFromHistory();
              });
              await _saveActiveFinansialToHive();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Catatan "$deletedTitle" berhasil dihapus!'),
                  backgroundColor: const Color(0xFFBE123C),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Ya, Hapus', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniButton({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required Color border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu Bawah: Navigasi ke Rekap Semua Musim
  Widget _buildAllSeasonRecapCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1FAE5)),
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
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_edu_rounded, color: Color(0xFF065F46), size: 18),
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
                          'Arsip Laporan Musim',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Text(
                            'Semua Musim',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Lihat akumulasi total biaya dan riwayat pengeluaran dari seluruh musim tanam yang telah ditutup.',
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
            height: 40,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFECFDF5),
                foregroundColor: const Color(0xFF065F46),
                side: const BorderSide(color: Color(0xFFA7F3D0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FinanceAllMusimScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.bar_chart_rounded, size: 16),
              label: const Text(
                'Rekap Semua Musim',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingProgressPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;
  final bool hasData;

  _RingProgressPainter({
    required this.categories,
    required this.hasData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 11.0;

    // Default warna putih bersih + garis tepi halus saat Total Biaya = Rp 0
    if (!hasData) {
      final whiteFillPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      final subtleBorderPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius, whiteFillPaint);
      canvas.drawCircle(center, radius + (strokeWidth / 2), subtleBorderPaint);
      canvas.drawCircle(center, radius - (strokeWidth / 2), subtleBorderPaint);
      return;
    }

    // Latar track saat ada data
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Lukis segmen arc dinamis mengikuti proporsi & warna masing-masing kategori
    double startAngle = -math.pi / 2;
    for (final cat in categories) {
      final double ratio = (cat['ratio'] as num?)?.toDouble() ?? 0.0;
      if (ratio <= 0) continue;

      final double sweepAngle = 2 * math.pi * ratio;
      final paint = Paint()
        ..color = cat['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _RingProgressPainter oldDelegate) => true;
}