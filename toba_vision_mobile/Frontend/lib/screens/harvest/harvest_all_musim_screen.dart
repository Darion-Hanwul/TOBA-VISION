import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/api_service.dart';
import '../../services/offline_service.dart';
import '../../widgets/app_header.dart';

class HarvestAllMusimScreen extends StatefulWidget {
  const HarvestAllMusimScreen({super.key});

  @override
  State<HarvestAllMusimScreen> createState() => _HarvestAllMusimScreenState();
}

class _HarvestAllMusimScreenState extends State<HarvestAllMusimScreen> {
  bool _isLoading = false;

  // Header Akumulasi Dynamic State (Dimulai dari 0)
  double _totalBobotKg = 0.0;
  double _totalRevenueRp = 0.0;

  // Data Riwayat Semua Musim Panen Tembakau yang telah ditutup
  List<Map<String, dynamic>> _seasonHistory = [];

  static const List<String> _stageLabels = [
    'Daun Pasir (Bawah 1)',
    'Daun Bawah 2',
    'Daun Tengah Utama (Prima)',
    'Daun Tengah 2',
    'Daun Atas',
    'Pucuk Daun',
    'Pemetikan Akhir',
  ];

  @override
  void initState() {
    super.initState();
    _loadClosedSeasons();
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

  /// Membangun list stageDetails (P1-P7) dari raw stages untuk tampilan Detail
  List<Map<String, dynamic>> _buildStageDetailsList(List<dynamic> rawStages) {
    return List.generate(7, (idx) {
      double w = 0.0;
      double r = 0.0;
      if (idx < rawStages.length && rawStages[idx] is Map) {
        w = ((rawStages[idx]['weight'] as num?)?.toDouble()) ?? 0.0;
        r = ((rawStages[idx]['revenue'] as num?)?.toDouble()) ?? 0.0;
      }

      return {
        'stage': 'P${idx + 1}',
        'label': _stageLabels[idx],
        'weight': w > 0 ? '${_formatNumber(w)} kg' : '0 kg',
        'revenue': 'Rp ${_formatRupiah(r)}',
      };
    });
  }

  List<Map<String, dynamic>> _mapRawArchives(List<dynamic> rawList) {
    return rawList.map((e) {
      final map = Map<String, dynamic>.from(e);
      final double rawWeight = (map['raw_weight'] as num?)?.toDouble() ?? 0.0;
      final double rawRev = (map['raw_revenue'] as num?)?.toDouble() ?? 0.0;

      final List rawStages = (map['stages'] as List<dynamic>?) ?? [];
      int completedCycles = 0;
      for (int idx = 0; idx < 7; idx++) {
        if (idx < rawStages.length && rawStages[idx] is Map) {
          final double w = ((rawStages[idx]['weight'] as num?)?.toDouble()) ?? 0.0;
          if (w > 0) completedCycles++;
        }
      }

      return {
        ...map,
        'weight': map['harvest'] ?? '${_formatNumber(rawWeight)} kg tembakau',
        'raw_weight': rawWeight,
        'revenue': map['revenue'] ?? 'Rp ${_formatRupiah(rawRev)}',
        'raw_revenue': rawRev,
        'cycles': '$completedCycles/7 Petikan Terisi',
        'status': map['status'] ?? 'Selesai',
        'stageDetails': _buildStageDetailsList(rawStages),
      };
    }).toList();
  }

  /// Memuat arsip musim panen dari Hive lokal lalu menyinkronkan dengan Cloud Firestore
  Future<void> _loadClosedSeasons() async {
    setState(() => _isLoading = true);
    try {
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');

      // 1. Tampilkan cache lokal terlebih dahulu agar cepat
      final rawArchive = box.get('closed_seasons_archive');
      if (rawArchive != null && rawArchive.toString().isNotEmpty) {
        final List decoded = jsonDecode(rawArchive.toString());
        _seasonHistory = _mapRawArchives(decoded);
        _recalculateTotals();
        if (mounted) setState(() {});
      }

      // 2. Tarik data terbaru dari Cloud Firestore agar tetap tersimpan lintas sesi/port
      final String uidPetani = _resolveActiveUid();
      final cloudArchives = await ApiService.getArsipMusimPetani(uidPetani);
      if (cloudArchives.isNotEmpty) {
        await box.put('closed_seasons_archive', jsonEncode(cloudArchives));
        _seasonHistory = _mapRawArchives(cloudArchives);
        _recalculateTotals();
      } else if (rawArchive == null || rawArchive.toString().isEmpty) {
        _seasonHistory = [];
        _recalculateTotals();
      }
    } catch (e) {
      debugPrint("Gagal memuat arsip panen: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _recalculateTotals() {
    double sumWeight = 0.0;
    double sumRevenue = 0.0;
    for (final season in _seasonHistory) {
      sumWeight += (season['raw_weight'] as num?)?.toDouble() ?? 0.0;
      sumRevenue += (season['raw_revenue'] as num?)?.toDouble() ?? 0.0;
    }
    _totalBobotKg = sumWeight;
    _totalRevenueRp = sumRevenue;
  }

  Future<void> _saveArchiveToHive() async {
    try {
      final box = Hive.isBoxOpen('toba_offline_box')
          ? Hive.box('toba_offline_box')
          : await Hive.openBox('toba_offline_box');
      await box.put('closed_seasons_archive', jsonEncode(_seasonHistory));
    } catch (e) {
      debugPrint("Gagal menyimpan arsip panen ke Hive: $e");
    }
  }

  String _formatRupiah(double val) {
    String numStr = val.toInt().toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  String _formatNumber(double val) {
    String numStr = val.toInt().toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return numStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  /// Membuka BottomSheet Edit Arsip Panen dengan data P1-P7 & Modal lama terisi otomatis
  void _openEditArchivedHarvestModal(int seasonIndex) {
    final season = _seasonHistory[seasonIndex];
    final List<dynamic> rawStages = (season['stages'] as List<dynamic>?) ?? [];

    final List<Map<String, dynamic>> editableStages = List.generate(7, (i) {
      double w = 0.0;
      double r = 0.0;
      if (i < rawStages.length && rawStages[i] is Map) {
        w = ((rawStages[i]['weight'] as num?)?.toDouble()) ?? 0.0;
        r = ((rawStages[i]['revenue'] as num?)?.toDouble()) ?? 0.0;
      }
      return {
        'step': i + 1,
        'stage': 'P${i + 1}',
        'weight': w,
        'revenue': r,
      };
    });

    int selectedStep = 1;
    final double initialModal = (season['raw_expenses'] as num?)?.toDouble() ?? 0.0;

    final TextEditingController modalCtrl = TextEditingController(
      text: initialModal > 0 ? initialModal.toInt().toString() : '0',
    );
    final TextEditingController weightCtrl = TextEditingController(
      text: ((editableStages[0]['weight'] as num).toDouble() > 0)
          ? (editableStages[0]['weight'] as num).toInt().toString()
          : '',
    );
    final TextEditingController revenueCtrl = TextEditingController(
      text: ((editableStages[0]['revenue'] as num).toDouble() > 0)
          ? (editableStages[0]['revenue'] as num).toInt().toString()
          : '',
    );

    void syncInputsForStep(int step) {
      final double w = (editableStages[step - 1]['weight'] as num?)?.toDouble() ?? 0.0;
      final double r = (editableStages[step - 1]['revenue'] as num?)?.toDouble() ?? 0.0;
      weightCtrl.text = w > 0 ? (w % 1 == 0 ? w.toInt().toString() : w.toString()) : '';
      revenueCtrl.text = r > 0 ? r.toInt().toString() : '';
    }

    void commitCurrentStepToMemory(int step) {
      final double w = double.tryParse(weightCtrl.text.replaceAll(',', '.').trim()) ?? 0.0;
      final double r = double.tryParse(revenueCtrl.text.replaceAll(RegExp(r'[^0-9]'), '').trim()) ?? 0.0;
      editableStages[step - 1]['weight'] = w;
      editableStages[step - 1]['revenue'] = r;
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
                            'Edit ${season['title']}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF064E3B),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'Pilih Petikan Daun yang Diedit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: List.generate(7, (idx) {
                        final step = idx + 1;
                        final bool isSelected = step == selectedStep;
                        final bool hasValue =
                            ((editableStages[idx]['weight'] as num?)?.toDouble() ?? 0.0) > 0;
                        return ChoiceChip(
                          label: Text('P$step'),
                          selected: isSelected,
                          selectedColor: const Color(0xFF064E3B),
                          backgroundColor:
                              hasValue ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : (hasValue
                                    ? const Color(0xFF166534)
                                    : const Color(0xFF64748B)),
                          ),
                          onSelected: (_) {
                            commitCurrentStepToMemory(selectedStep);
                            setModalState(() {
                              selectedStep = step;
                              syncInputsForStep(step);
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tahap: ${_stageLabels[selectedStep - 1]}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF047857),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Berat Tembakau P$selectedStep (kg)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: weightCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: 'kg',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Pendapatan Petikan P$selectedStep (Rp)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: revenueCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixText: 'Rp ',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Total Modal Biaya Musim Ini (Rp)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: modalCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixText: 'Rp ',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF064E3B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          commitCurrentStepToMemory(selectedStep);

                          double newTotalWeight = 0.0;
                          double newTotalRevenue = 0.0;
                          int completedCycles = 0;

                          for (final s in editableStages) {
                            final double w = (s['weight'] as num?)?.toDouble() ?? 0.0;
                            final double r = (s['revenue'] as num?)?.toDouble() ?? 0.0;
                            newTotalWeight += w;
                            newTotalRevenue += r;
                            if (w > 0) completedCycles++;
                          }

                          final double newModal = double.tryParse(
                                modalCtrl.text.replaceAll(RegExp(r'[^0-9]'), '').trim(),
                              ) ??
                              initialModal;
                          final double newProfit = newTotalRevenue - newModal;

                          setState(() {
                            _seasonHistory[seasonIndex] = {
                              ...season,
                              'stages': editableStages,
                              'stageDetails': _buildStageDetailsList(editableStages),
                              'cycles': '$completedCycles/7 Petikan Terisi',
                              'raw_weight': newTotalWeight,
                              'harvest': '${_formatNumber(newTotalWeight)} kg tembakau',
                              'weight': '${_formatNumber(newTotalWeight)} kg tembakau',
                              'raw_expenses': newModal,
                              'expenses': 'Rp ${_formatRupiah(newModal)}',
                              'raw_revenue': newTotalRevenue,
                              'revenue': 'Rp ${_formatRupiah(newTotalRevenue)}',
                              'raw_profit': newProfit,
                              'profit':
                                  '${newProfit >= 0 ? "+" : "-"}Rp ${_formatRupiah(newProfit.abs())}',
                            };
                            _recalculateTotals();
                          });

                          await _saveArchiveToHive();
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Perubahan pada ${season['title']} berhasil disimpan!'),
                              backgroundColor: const Color(0xFF064E3B),
                            ),
                          );
                        },
                        child: const Text(
                          'Simpan Perubahan Musim',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppHeader(
        showBack: true,
        title: 'Rekap Semua Musim Panen',
        backgroundColor: const Color(0xE6F4F7F5),
        showBottomBorder: true,
        trailing: AppHeaderActionButton(
          icon: _isLoading ? Icons.hourglass_top_rounded : Icons.sync_rounded,
          onTap: () async {
            await _loadClosedSeasons();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sinkronisasi data panen semua musim berhasil diperbarui!'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF064E3B),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccumulatedHeaderCard(),
              const SizedBox(height: 24),
              _buildSeasonHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Header Akumulasi Panen Semua Musim
  Widget _buildAccumulatedHeaderCard() {
    final bool hasData = _totalBobotKg > 0 || _totalRevenueRp > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasData ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: hasData ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.agriculture_rounded,
                      size: 12,
                      color: hasData ? const Color(0xFF064E3B) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'TOTAL AKUMULASI PANEN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: hasData ? const Color(0xFF064E3B) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '${_seasonHistory.length} Musim Selesai',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_formatNumber(_totalBobotKg)} kg',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: hasData ? const Color(0xFF064E3B) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Keuntungan Kotor Mentah: Rp ${_formatRupiah(_totalRevenueRp)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: hasData ? const Color(0xFF166534) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _seasonHistory.isNotEmpty
                ? 'Akumulasi dari siklus pemetikan daun tembakau (7 petikan per musim tanam).'
                : 'Belum ada musim tanam yang ditutup buku pada fitur Panen.',
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Riwayat Musim Panen Section
  Widget _buildSeasonHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat Musim Panen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Catatan 7 siklus petikan daun tembakau tiap musim',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Text(
                '7 Petikan / Musim',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF064E3B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
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
                  'Belum ada riwayat panen tersimpan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tekan tombol "Tutup Buku & Simpan Rekap" di bagian bawah halaman Monitoring Siklus Panen untuk mengarsipkan hasil panen musim ini.',
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
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            season['title'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF064E3B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF166534)),
                              const SizedBox(width: 4),
                              Text(
                                season['status'] as String,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      season['period'] as String,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          season['revenue'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF166534),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${season['weight']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            season['cycles'] as String,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
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
                          onTap: () => _openEditArchivedHarvestModal(index),
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

  Widget _buildMiniButton({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required Color border,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  void _showSeasonDetail(Map<String, dynamic> season) {
    final stages = (season['stageDetails'] as List<dynamic>?) ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
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
                      '7 Petikan Lengkap',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF047857)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(season['period'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const Divider(height: 24),
              _buildDetailRow('Total Hasil Bobot Panen', season['weight'] as String, isBold: true),
              const SizedBox(height: 8),
              _buildDetailRow('Total Pendapatan Kotor Mentah', season['revenue'] as String, isBold: true, valueColor: const Color(0xFF166534)),
              if (season['expenses'] != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Total Modal Biaya (Finansial)', season['expenses'] as String),
              ],
              if (season['profit'] != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Laba / Rugi Bersih', season['profit'] as String, isBold: true),
              ],
              const SizedBox(height: 8),
              _buildDetailRow('Siklus Tembakau', '7 Petikan Daun (P1 s/d P7)'),
              const Divider(height: 24),
              const Text(
                'Rincian 7 Tahap Siklus Petikan Daun:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              ...stages.map((stg) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          stg['stage'] as String,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF064E3B)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          stg['label'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            stg['weight'] as String,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF064E3B)),
                          ),
                          Text(
                            stg['revenue'] as String,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? (isBold ? const Color(0xFF064E3B) : const Color(0xFF1E293B)),
          ),
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
              'Hapus Arsip Panen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data panen "${season['title']}"? Seluruh riwayat timbangan 7 siklus petikan akan dihapus.',
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
                _recalculateTotals();
              });
              await _saveArchiveToHive();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data "$deletedTitle" berhasil dihapus!'),
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
}