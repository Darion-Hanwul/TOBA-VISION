import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../widgets/app_header.dart';

class FinanceAllMusimScreen extends StatefulWidget {
  const FinanceAllMusimScreen({super.key});

  @override
  State<FinanceAllMusimScreen> createState() => _FinanceAllMusimScreenState();
}

class _FinanceAllMusimScreenState extends State<FinanceAllMusimScreen> {
  bool _isLoading = false;
  double _totalBiayaAllMusim = 0.0;

  // Data Riwayat Semua Musim Tanam yang telah ditutup (Dimulai kosong)
  List<Map<String, dynamic>> _seasonHistory = [];

  // Akumulasi per kategori dari seluruh musim
  Map<String, double> _categoryTotals = {
    'Buruh Tani / Upah': 0.0,
    'Pupuk & Nutrisi': 0.0,
    'Bibit & Olah Lahan': 0.0,
    'Lainnya / Tambahan': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadClosedSeasonsFromHive();
  }

  /// Memuat arsip musim yang telah ditutup dari Hive & menghitung ulang akumulasi
  Future<void> _loadClosedSeasonsFromHive() async {
    setState(() => _isLoading = true);
    try {
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');

      final rawArchive = box.get('closed_seasons_archive');
      if (rawArchive != null && rawArchive.toString().isNotEmpty) {
        final List decoded = jsonDecode(rawArchive.toString());
        _seasonHistory = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _seasonHistory = [];
      }

      _recalculateAccumulation();
    } catch (e) {
      debugPrint("Gagal memuat arsip musim dari Hive: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _recalculateAccumulation() {
    double grandTotal = 0.0;
    final Map<String, double> catSums = {
      'Buruh Tani / Upah': 0.0,
      'Pupuk & Nutrisi': 0.0,
      'Bibit & Olah Lahan': 0.0,
      'Lainnya / Tambahan': 0.0,
    };

    for (final season in _seasonHistory) {
      final double exp = (season['raw_expenses'] as num?)?.toDouble() ?? 0.0;
      grandTotal += exp;

      if (season['category_breakdown'] is Map) {
        final Map breakdown = season['category_breakdown'];
        breakdown.forEach((key, val) {
          final double v = (val as num?)?.toDouble() ?? 0.0;
          final kStr = key.toString();
          if (catSums.containsKey(kStr)) {
            catSums[kStr] = (catSums[kStr] ?? 0.0) + v;
          } else {
            catSums['Lainnya / Tambahan'] = (catSums['Lainnya / Tambahan'] ?? 0.0) + v;
          }
        });
      } else {
        // Fallback jika arsip lama tidak memiliki rincian per kategori
        catSums['Lainnya / Tambahan'] = (catSums['Lainnya / Tambahan'] ?? 0.0) + exp;
      }
    }

    _totalBiayaAllMusim = grandTotal;
    _categoryTotals = catSums;
  }

  Future<void> _saveArchiveToHive() async {
    try {
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');
      await box.put('closed_seasons_archive', jsonEncode(_seasonHistory));
    } catch (e) {
      debugPrint("Gagal menyimpan perubahan arsip musim: $e");
    }
  }

  String _formatRupiah(double val) {
    String numStr = val.toInt().toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

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

  int _calcPct(double part) {
    if (_totalBiayaAllMusim <= 0 || part <= 0) return 0;
    return ((part / _totalBiayaAllMusim) * 100).round();
  }

  double _calcRatio(double part) {
    if (_totalBiayaAllMusim <= 0 || part <= 0) return 0.0;
    return part / _totalBiayaAllMusim;
  }

  /// Membuka BottomSheet Edit Arsip Biaya Musim dengan 4 kategori biaya lama terisi otomatis
  void _openEditArchivedFinanceModal(int seasonIndex) {
    final season = _seasonHistory[seasonIndex];
    final Map<String, dynamic> breakdown =
        Map<String, dynamic>.from(season['category_breakdown'] as Map? ?? {});

    final double initialBuruh = (breakdown['Buruh Tani / Upah'] as num?)?.toDouble() ?? 0.0;
    final double initialPupuk = (breakdown['Pupuk & Nutrisi'] as num?)?.toDouble() ?? 0.0;
    final double initialBibit = (breakdown['Bibit & Olah Lahan'] as num?)?.toDouble() ?? 0.0;
    final double initialLainnya = (breakdown['Lainnya / Tambahan'] as num?)?.toDouble() ?? 0.0;

    // Fallback jika arsip lama hanya menyimpan raw_expenses tanpa rincian kategori
    final double totalBefore = (season['raw_expenses'] as num?)?.toDouble() ?? 0.0;
    final double sumBreakdown = initialBuruh + initialPupuk + initialBibit + initialLainnya;
    final double effectiveLainnya =
        (sumBreakdown == 0 && totalBefore > 0) ? totalBefore : initialLainnya;

    final TextEditingController buruhCtrl = TextEditingController(
      text: initialBuruh > 0 ? initialBuruh.toInt().toString() : '0',
    );
    final TextEditingController pupukCtrl = TextEditingController(
      text: initialPupuk > 0 ? initialPupuk.toInt().toString() : '0',
    );
    final TextEditingController bibitCtrl = TextEditingController(
      text: initialBibit > 0 ? initialBibit.toInt().toString() : '0',
    );
    final TextEditingController lainnyaCtrl = TextEditingController(
      text: effectiveLainnya > 0 ? effectiveLainnya.toInt().toString() : '0',
    );

    double parseAmount(String raw) {
      return double.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '').trim()) ?? 0.0;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final double currentTotal = parseAmount(buruhCtrl.text) +
                parseAmount(pupukCtrl.text) +
                parseAmount(bibitCtrl.text) +
                parseAmount(lainnyaCtrl.text);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Edit Biaya ${season['title']}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF022C22),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Biaya Baru:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          Text(
                            'Rp ${_formatRupiah(currentTotal)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF064E3B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildEditCategoryField(
                      label: 'Buruh Tani / Upah (Rp)',
                      icon: Icons.groups_rounded,
                      color: const Color(0xFF065F46),
                      controller: buruhCtrl,
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),

                    _buildEditCategoryField(
                      label: 'Pupuk & Nutrisi (Rp)',
                      icon: Icons.science_outlined,
                      color: const Color(0xFF4338CA),
                      controller: pupukCtrl,
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),

                    _buildEditCategoryField(
                      label: 'Bibit & Olah Lahan (Rp)',
                      icon: Icons.spa_outlined,
                      color: const Color(0xFF115E59),
                      controller: bibitCtrl,
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),

                    _buildEditCategoryField(
                      label: 'Lainnya / Tambahan (Rp)',
                      icon: Icons.category_outlined,
                      color: const Color(0xFF92400E),
                      controller: lainnyaCtrl,
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14532D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final double newBuruh = parseAmount(buruhCtrl.text);
                          final double newPupuk = parseAmount(pupukCtrl.text);
                          final double newBibit = parseAmount(bibitCtrl.text);
                          final double newLainnya = parseAmount(lainnyaCtrl.text);

                          final double newTotalExpenses =
                              newBuruh + newPupuk + newBibit + newLainnya;
                          final double existingRevenue =
                              (season['raw_revenue'] as num?)?.toDouble() ?? 0.0;
                          final double newProfit = existingRevenue - newTotalExpenses;

                          final Map<String, double> updatedBreakdown = {
                            'Buruh Tani / Upah': newBuruh,
                            'Pupuk & Nutrisi': newPupuk,
                            'Bibit & Olah Lahan': newBibit,
                            'Lainnya / Tambahan': newLainnya,
                          };

                          setState(() {
                            _seasonHistory[seasonIndex] = {
                              ...season,
                              'category_breakdown': updatedBreakdown,
                              'raw_expenses': newTotalExpenses,
                              'expenses': 'Rp ${_formatRupiah(newTotalExpenses)}',
                              'raw_profit': newProfit,
                              'profit':
                                  '${newProfit >= 0 ? "+" : "-"}Rp ${_formatRupiah(newProfit.abs())}',
                            };
                            _recalculateAccumulation();
                          });

                          await _saveArchiveToHive();
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Rincian biaya ${season['title']} berhasil diperbarui!',
                              ),
                              backgroundColor: const Color(0xFF065F46),
                            ),
                          );
                        },
                        child: const Text(
                          'Simpan Perubahan Biaya',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditCategoryField({
    required String label,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: '0',
            prefixText: 'Rp ',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppHeader(
        showBack: true,
        title: 'Rekap Semua Musim',
        backgroundColor: const Color(0xE6F4F7F5),
        showBottomBorder: true,
        trailing: AppHeaderActionButton(
          icon: _isLoading ? Icons.hourglass_top_rounded : Icons.sync_rounded,
          onTap: () async {
            await _loadClosedSeasonsFromHive();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Data akumulasi finansial diperbarui!'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF047857),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderTitleSection(),
              const SizedBox(height: 16),
              _buildAllSeasonsSummaryCard(),
              const SizedBox(height: 24),
              _buildAllSeasonsHistoryList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Biaya & Pengeluaran',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: Color(0xFF022C22),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Semua Musim',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Akumulasi menyeluruh pengeluaran operasional dari seluruh musim tanam.',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildAllSeasonsSummaryCard() {
    final bool hasData = _totalBiayaAllMusim > 0;
    final ratios = [
      _calcRatio(_categoryTotals['Buruh Tani / Upah'] ?? 0.0),
      _calcRatio(_categoryTotals['Pupuk & Nutrisi'] ?? 0.0),
      _calcRatio(_categoryTotals['Bibit & Olah Lahan'] ?? 0.0),
      _calcRatio(_categoryTotals['Lainnya / Tambahan'] ?? 0.0),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            width: 176,
            height: 176,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(176, 176),
                  painter: _AllSeasonsRingProgressPainter(
                    hasData: hasData,
                    ratios: ratios,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: hasData ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasData
                              ? const Color(0xFFD1FAE5).withValues(alpha: 0.6)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Icon(
                        Icons.spa_rounded,
                        color: hasData ? const Color(0xFF047857) : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'SEMUA MUSIM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'TOTAL BIAYA TERCATAT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatCompactRupiah(_totalBiayaAllMusim),
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.75,
              color: hasData ? const Color(0xFF14532D) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _seasonHistory.isNotEmpty
                ? 'Akumulasi seluruh pengeluaran dari ${_seasonHistory.length} musim tanam'
                : 'Belum ada musim tanam yang ditutup buku',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KATEGORI AKUMULASI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Color(0xFF334155),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '${_seasonHistory.length} Musim',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAccumulatedCategoryGrid(),
        ],
      ),
    );
  }

  Widget _buildAccumulatedCategoryGrid() {
    final valBuruh = _categoryTotals['Buruh Tani / Upah'] ?? 0.0;
    final valPupuk = _categoryTotals['Pupuk & Nutrisi'] ?? 0.0;
    final valBibit = _categoryTotals['Bibit & Olah Lahan'] ?? 0.0;
    final valLain = _categoryTotals['Lainnya / Tambahan'] ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAccumulatedCard(
                label: 'Buruh & Petik',
                amount: _formatCompactRupiah(valBuruh),
                percent: '${_calcPct(valBuruh)}%',
                isActive: valBuruh > 0,
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFF065F46),
                iconBg: const Color(0xFFD1FAE5),
                textColor: const Color(0xFF065F46),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAccumulatedCard(
                label: 'Pupuk & Nutrisi',
                amount: _formatCompactRupiah(valPupuk),
                percent: '${_calcPct(valPupuk)}%',
                isActive: valPupuk > 0,
                icon: Icons.science_outlined,
                iconColor: const Color(0xFF3730A3),
                iconBg: const Color(0xFFE0E7FF),
                textColor: const Color(0xFF312E81),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildAccumulatedCard(
                label: 'Bibit & Olah Lahan',
                amount: _formatCompactRupiah(valBibit),
                percent: '${_calcPct(valBibit)}%',
                isActive: valBibit > 0,
                icon: Icons.spa_outlined,
                iconColor: const Color(0xFF115E59),
                iconBg: const Color(0xFFCCFBF1),
                textColor: const Color(0xFF115E59),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAccumulatedCard(
                label: 'Logistik & Lain',
                amount: _formatCompactRupiah(valLain),
                percent: '${_calcPct(valLain)}%',
                isActive: valLain > 0,
                icon: Icons.local_shipping_outlined,
                iconColor: const Color(0xFF92400E),
                iconBg: const Color(0xFFFEF3C7),
                textColor: const Color(0xFF92400E),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccumulatedCard({
    required String label,
    required String amount,
    required String percent,
    required bool isActive,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? iconColor.withValues(alpha: 0.2) : const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? iconBg : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isActive ? iconColor : const Color(0xFF94A3B8), size: 16),
              ),
              Text(
                percent,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? textColor : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
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
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isActive ? textColor : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllSeasonsHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Musim Tanam',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                '${_seasonHistory.length} Musim Selesai',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_seasonHistory.isEmpty)
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
                Icon(Icons.inventory_2_outlined, size: 32, color: Color(0xFF94A3B8)),
                SizedBox(height: 8),
                Text(
                  'Belum ada arsip musim tanam',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Arsip akan otomatis muncul di sini setelah Anda menekan tombol "Tutup Buku & Simpan Rekap" pada halaman Panen.',
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
            itemCount: _seasonHistory.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final season = _seasonHistory[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
                  ],
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
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              season['title'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Text(
                            'Selesai',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      season['period'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Total: ${season['expenses']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${season['harvest']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF8FAFC)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildMiniButton(
                          label: 'Detail',
                          icon: Icons.visibility_outlined,
                          bg: const Color(0xFFF8FAFC),
                          fg: const Color(0xFF1E293B),
                          border: const Color(0xFFE2E8F0),
                          onTap: () => _showSeasonDetail(season),
                        ),
                        const SizedBox(width: 8),
                        _buildMiniButton(
                          label: 'Edit',
                          icon: Icons.edit_outlined,
                          bg: const Color(0xFFF0FDF4),
                          fg: const Color(0xFF166534),
                          border: const Color(0xFFBBF7D0),
                          onTap: () => _openEditArchivedFinanceModal(index),
                        ),
                        const SizedBox(width: 8),
                        _buildMiniButton(
                          label: 'Hapus',
                          icon: Icons.delete_outline_rounded,
                          bg: const Color(0xFFFEF2F2),
                          fg: const Color(0xFFDC2626),
                          border: const Color(0xFFFECACA),
                          onTap: () => _confirmDeleteSeason(index, season),
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

  void _confirmDeleteSeason(int index, Map<String, dynamic> season) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFBE123C)),
            SizedBox(width: 8),
            Text(
              'Hapus Arsip Musim',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data "${season['title']}"? Data riwayat dan rekapitulasi musim ini akan dihapus permanen.',
          style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBE123C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final deletedTitle = season['title'];
              setState(() {
                _seasonHistory.removeAt(index);
                _recalculateAccumulation();
              });
              await _saveArchiveToHive();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Arsip "$deletedTitle" berhasil dihapus!'),
                  backgroundColor: const Color(0xFFBE123C),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Ya, Hapus', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSeasonDetail(Map<String, dynamic> season) {
    final Map<String, dynamic> breakdown =
        Map<String, dynamic>.from(season['category_breakdown'] as Map? ?? {});

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  season['title'] as String,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF022C22)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Text(
                    'Arsip Selesai',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF047857)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(season['period'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const Divider(height: 28),
            _buildDetailRow(
              'Buruh Tani / Upah',
              'Rp ${_formatRupiah((breakdown['Buruh Tani / Upah'] as num?)?.toDouble() ?? 0.0)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Pupuk & Nutrisi',
              'Rp ${_formatRupiah((breakdown['Pupuk & Nutrisi'] as num?)?.toDouble() ?? 0.0)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Bibit & Olah Lahan',
              'Rp ${_formatRupiah((breakdown['Bibit & Olah Lahan'] as num?)?.toDouble() ?? 0.0)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Lainnya / Tambahan',
              'Rp ${_formatRupiah((breakdown['Lainnya / Tambahan'] as num?)?.toDouble() ?? 0.0)}',
            ),
            const Divider(height: 24),
            _buildDetailRow('Total Pengeluaran', season['expenses'] as String, isBold: true),
            const SizedBox(height: 10),
            _buildDetailRow('Total Hasil Timbangan', season['harvest'] as String),
            if (season['revenue'] != null) ...[
              const SizedBox(height: 10),
              _buildDetailRow('Total Pendapatan Panen', season['revenue'] as String),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF064E3B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? const Color(0xFF064E3B) : const Color(0xFF1E293B),
          ),
        ),
      ],
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
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllSeasonsRingProgressPainter extends CustomPainter {
  final bool hasData;
  final List<double> ratios;

  _AllSeasonsRingProgressPainter({
    required this.hasData,
    required this.ratios,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 12.0;

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

    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final colors = [
      const Color(0xFF166534),
      const Color(0xFF818CF8),
      const Color(0xFF115E59),
      const Color(0xFF92400E),
    ];

    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -math.pi / 2;
    for (int i = 0; i < ratios.length && i < colors.length; i++) {
      if (ratios[i] <= 0) continue;
      final sweep = 2 * math.pi * ratios[i];
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _AllSeasonsRingProgressPainter oldDelegate) => true;
}