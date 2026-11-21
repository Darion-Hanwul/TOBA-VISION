import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/auth_session.dart';
import '../../data/firestore_models.dart';
import '../../data/firestore_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/retro/blade_ornament.dart';
import '../../widgets/retro/micro_text.dart';
import '../../widgets/retro/retro_card.dart';
import '../../widgets/retro/retro_frame.dart';
import '../../widgets/retro/status_chip.dart';
import '../../widgets/retro/trapezoid_tab_button.dart';
import '../../widgets/retro/vu_meter_bar.dart';
import 'finance_all_musim_screen.dart';
import 'finance_screen_edit_upload.dart';

class FinanceScreen extends StatefulWidget {
  final bool showBack;
  final Map<String, dynamic>? initialSeasonData;
  const FinanceScreen({super.key, this.showBack = false, this.initialSeasonData});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  int _selectedPeriod = 0; // 0: Musim Ini, 1: Semua
  final List<String> _periods = ['Musim Ini', 'Semua'];

  String _currentSeasonTitle = FinanceDataStore.activeSeasonTitle;
  String _currentTotalExpense = 'Rp 0';
  late List<Map<String, dynamic>> _categories;

  StreamSubscription<List<BiayaOperasionalModel>>? _biayaSub;
  List<BiayaOperasionalModel> _firestoreBiayaList = [];

  @override
  void initState() {
    super.initState();
    _initCategories();
    if (widget.initialSeasonData != null) {
      _applySeasonData(widget.initialSeasonData!);
    }
    _listenToFirestore();
  }

  @override
  void dispose() {
    _biayaSub?.cancel();
    super.dispose();
  }

  void _listenToFirestore() {
    final idPetani = AuthSession.currentIdPetani;
    if (idPetani.isEmpty) {
      _applyFirestoreData([]);
      return;
    }

    FirestoreService.instance.getOrCreateMusimAktif(idPetani).then((musim) {
      if (!mounted) return;
      setState(() {
        _currentSeasonTitle = 'Biaya & Pengeluaran ${musim.judulMusim}';
        FinanceDataStore.activeSeasonTitle = _currentSeasonTitle;
      });
      AuthSession.setActiveMusim(musim.idMusim);
      _subscribeBiaya(idPetani, musim.idMusim);
    });

    final currentIdMusim = AuthSession.currentIdMusim;
    if (currentIdMusim.isNotEmpty) {
      _subscribeBiaya(idPetani, currentIdMusim);
    }
  }

  void _subscribeBiaya(String idPetani, String idMusim) {
    _biayaSub?.cancel();
    if (idPetani.isEmpty || idMusim.isEmpty) {
      _applyFirestoreData([]);
      return;
    }
    _biayaSub = FirestoreService.instance.streamDaftarBiaya(idPetani, idMusim).listen((list) {
      if (!mounted) return;
      _applyFirestoreData(list);
    }, onError: (_) {
      // Graceful offline fallback
    });
  }

  void _applyFirestoreData(List<BiayaOperasionalModel> list) {
    _historyItems.clear();
    if (list.isEmpty) {
      setState(() {
        _firestoreBiayaList = [];
        _currentTotalExpense = 'Rp 0';
        FinanceDataStore.activeTotalExpense = _currentTotalExpense;
        for (final cat in _categories) {
          cat['amount'] = 'Rp 0';
          cat['ratio'] = 0.0;
          cat['percentage'] = '0%';
        }
      });
      return;
    }

    double total = 0;
    double buruh = 0;
    double pupuk = 0;
    double bibit = 0;
    double lainnya = 0;

    for (final item in list) {
      total += item.jumlahBiaya;
      switch (item.kodeKategori) {
        case 'BURUH':
          buruh += item.jumlahBiaya;
          break;
        case 'PUPUK':
          pupuk += item.jumlahBiaya;
          break;
        case 'BIBIT':
          bibit += item.jumlahBiaya;
          break;
        case 'LAINNYA':
        default:
          lainnya += item.jumlahBiaya;
          break;
      }
    }

    setState(() {
      _firestoreBiayaList = list;
      _currentTotalExpense = _formatRupiah(total);
      FinanceDataStore.activeTotalExpense = _currentTotalExpense;

      _categories[0]['amount'] = _formatRupiahJt(buruh);
      _categories[0]['ratio'] = total > 0 ? (buruh / total).clamp(0.0, 1.0) : 0.0;
      _categories[0]['percentage'] = total > 0 ? '${((buruh / total) * 100).round()}%' : '0%';

      _categories[1]['amount'] = _formatRupiahJt(pupuk);
      _categories[1]['ratio'] = total > 0 ? (pupuk / total).clamp(0.0, 1.0) : 0.0;
      _categories[1]['percentage'] = total > 0 ? '${((pupuk / total) * 100).round()}%' : '0%';

      _categories[2]['amount'] = _formatRupiahJt(bibit);
      _categories[2]['ratio'] = total > 0 ? (bibit / total).clamp(0.0, 1.0) : 0.0;
      _categories[2]['percentage'] = total > 0 ? '${((bibit / total) * 100).round()}%' : '0%';

      _categories[3]['amount'] = _formatRupiahJt(lainnya);
      _categories[3]['ratio'] = total > 0 ? (lainnya / total).clamp(0.0, 1.0) : 0.0;
      _categories[3]['percentage'] = total > 0 ? '${((lainnya / total) * 100).round()}%' : '0%';
    });
  }

  String _formatRupiah(double val) {
    final intVal = val.round();
    final s = intVal.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = s.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  String _formatRupiahJt(double val) {
    if (val >= 1000000) {
      final jt = val / 1000000;
      final jtStr = jt.toStringAsFixed(1).replaceAll('.', ',');
      return 'Rp $jtStr jt';
    } else if (val >= 1000) {
      final rb = (val / 1000).round();
      return 'Rp $rb rb';
    }
    return 'Rp ${val.round()}';
  }

  String _formatAngka(double val) {
    final intVal = val.round();
    final s = intVal.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (Match m) => '${m[1]}.');
  }

  String _namaBulan(int m) {
    const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    if (m >= 1 && m <= 12) return bulan[m - 1];
    return '';
  }

  void _initCategories() {
    _categories = [
      {
        'name': 'Buruh Tani / Upah',
        'amount': 'Rp 0',
        'ratio': 0.0,
        'percentage': '0%',
        'icon': Icons.groups_rounded,
        'color': AppColors.forest,
      },
      {
        'name': 'Pupuk & Nutrisi',
        'amount': 'Rp 0',
        'ratio': 0.0,
        'percentage': '0%',
        'icon': Icons.science_outlined,
        'color': AppColors.limeDeep,
      },
      {
        'name': 'Bibit & Olah Lahan',
        'amount': 'Rp 0',
        'ratio': 0.0,
        'percentage': '0%',
        'icon': Icons.spa_outlined,
        'color': AppColors.orange,
      },
      {
        'name': 'Lainnya / Tambahan',
        'amount': 'Rp 0',
        'ratio': 0.0,
        'percentage': '0%',
        'icon': Icons.category_outlined,
        'color': AppColors.ink,
      },
    ];
  }

  double _parseRupiah(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  void _applySeasonData(Map<String, dynamic> season) {
    final idMusim = season['idMusim'] as String?;
    if (idMusim != null && idMusim.isNotEmpty) {
      AuthSession.setActiveMusim(idMusim);
      FirestoreService.instance.setMusimAktif(AuthSession.currentIdPetani, idMusim);
      _subscribeBiaya(AuthSession.currentIdPetani, idMusim);
    }

    final seasonNum = season['seasonNumber'] as int?;
    final rawTitle = season['title'] as String? ?? '';
    final lowerTitle = rawTitle.toLowerCase();

    if (seasonNum == 3 || lowerTitle.contains('ketiga') || lowerTitle.contains('musim 3')) {
      _currentSeasonTitle = 'Biaya & Pengeluaran Musim 3';
    } else if (seasonNum == 2 || lowerTitle.contains('kedua') || lowerTitle.contains('musim 2')) {
      _currentSeasonTitle = 'Biaya & Pengeluaran Musim 2';
    } else if (seasonNum == 1 || lowerTitle.contains('pertama') || lowerTitle.contains('kesatu') || lowerTitle.contains('musim 1')) {
      _currentSeasonTitle = 'Biaya & Pengeluaran Musim 1';
    } else if (rawTitle.isNotEmpty) {
      if (lowerTitle.startsWith('biaya & pengeluaran')) {
        _currentSeasonTitle = rawTitle;
      } else {
        _currentSeasonTitle = 'Biaya & Pengeluaran $rawTitle';
      }
    }

    if (season['expenses'] != null) {
      _currentTotalExpense = season['expenses'] as String;
    }

    if (season['labor'] != null) {
      _categories[0]['amount'] = season['labor'] as String;
    }
    if (season['fertilizer'] != null) {
      _categories[1]['amount'] = season['fertilizer'] as String;
    }
    if (season['seed'] != null) {
      _categories[2]['amount'] = season['seed'] as String;
    }
    if (season['other'] != null) {
      _categories[3]['amount'] = season['other'] as String;
    }

    final totalVal = _parseRupiah(_currentTotalExpense);
    if (totalVal > 0) {
      for (final cat in _categories) {
        final catVal = _parseRupiah(cat['amount'] as String);
        if (catVal > 0) {
          final ratio = (catVal / totalVal).clamp(0.0, 1.0);
          cat['ratio'] = ratio;
          cat['percentage'] = '${(ratio * 100).round()}%';
        }
      }
    }

    FinanceDataStore.activeSeasonData = season;
    FinanceDataStore.activeSeasonTitle = _currentSeasonTitle;
    FinanceDataStore.activeTotalExpense = _currentTotalExpense;

    _updateHistoryForSeason(season);
  }

  void _updateHistoryForSeason(Map<String, dynamic> season) {
    _historyItems.clear();
  }

  Future<void> _navigateToSelectSeason() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FinanceAllMusimScreen(),
      ),
    );
    if (mounted) {
      setState(() => _selectedPeriod = 0);
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _applySeasonData(result);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beralih ke: $_currentSeasonTitle'),
            backgroundColor: AppColors.ink,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _listenToFirestore();
      }
    }
  }

  Future<void> _showSeasonSelectionSheet() async {
    List<Map<String, dynamic>> seasons = [];
    try {
      final list = await FirestoreService.instance.getSemuaMusim(AuthSession.currentIdPetani);
      for (final m in list) {
        final biayaList = await FirestoreService.instance.getDaftarBiaya(AuthSession.currentIdPetani, m.idMusim);
        double mBuruh = 0.0;
        double mPupuk = 0.0;
        double mBibit = 0.0;
        double mLainnya = 0.0;
        double mTotal = 0.0;

        for (final b in biayaList) {
          mTotal += b.jumlahBiaya;
          switch (b.kodeKategori) {
            case 'BURUH':
              mBuruh += b.jumlahBiaya;
              break;
            case 'PUPUK':
              mPupuk += b.jumlahBiaya;
              break;
            case 'BIBIT':
              mBibit += b.jumlahBiaya;
              break;
            case 'LAINNYA':
            default:
              mLainnya += b.jumlahBiaya;
              break;
          }
        }

        final double seasonTotal = (biayaList.isNotEmpty || mTotal > 0) ? mTotal : m.totalPengeluaranCache;

        final bool isSelesai = m.status == 'SELESAI';
        seasons.add({
          'idMusim': m.idMusim,
          'seasonNumber': m.nomorMusim,
          'title': m.judulMusim,
          'short': 'Musim ${m.nomorMusim}',
          'period': 'Mulai ${m.tanggalMulai.day}/${m.tanggalMulai.month}/${m.tanggalMulai.year} • ${m.lokasiBlok}',
          'expenses': 'Rp ${_formatAngka(seasonTotal)}',
          'harvest': '${m.totalBobotPanenCache.toStringAsFixed(0)} kg tembakau',
          'status': isSelesai ? 'SELESAI' : 'BELUM SELESAI',
          'isSelesai': isSelesai,
          'labor': 'Rp ${_formatAngka(mBuruh)}',
          'fertilizer': 'Rp ${_formatAngka(mPupuk)}',
          'seed': 'Rp ${_formatAngka(mBibit)}',
          'other': 'Rp ${_formatAngka(mLainnya)}',
        });
      }
    } catch (_) {}

    if (!mounted) return;

    String activeFilter = 'SEMUA';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final int countBelum = seasons.where((s) => s['isSelesai'] != true).length;
          final int countSudah = seasons.where((s) => s['isSelesai'] == true).length;

          final List<Map<String, dynamic>> displayed = seasons.where((s) {
            if (activeFilter == 'BELUM') return s['isSelesai'] != true;
            if (activeFilter == 'SUDAH') return s['isSelesai'] == true;
            return true;
          }).toList();

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                top: BorderSide(color: AppColors.ink, width: 2),
                left: BorderSide(color: AppColors.ink, width: 2),
                right: BorderSide(color: AppColors.ink, width: 2),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PILIH PERIODE MUSIM', style: AppTypography.display(fontSize: 16, fontWeight: FontWeight.w900)),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close_rounded, size: 20, color: AppColors.ink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const MicroText('PILIH MUSIM UNTUK MENAMPILKAN BUKU KAS AKTIF', fontSize: 9, color: AppColors.muted),
                  const SizedBox(height: 12),

                  // Tab Filter Cepat (Semua, Belum Selesai, Sudah Selesai)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterTab(
                          label: 'SEMUA (${seasons.length})',
                          isSelected: activeFilter == 'SEMUA',
                          onTap: () => setSheetState(() => activeFilter = 'SEMUA'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTab(
                          label: 'BELUM SELESAI ($countBelum)',
                          isSelected: activeFilter == 'BELUM',
                          activeColor: AppColors.orange,
                          onTap: () => setSheetState(() => activeFilter = 'BELUM'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTab(
                          label: 'SUDAH SELESAI ($countSudah)',
                          isSelected: activeFilter == 'SUDAH',
                          activeColor: AppColors.ink,
                          onTap: () => setSheetState(() => activeFilter = 'SUDAH'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (displayed.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: MicroText(
                          activeFilter == 'BELUM'
                              ? 'TIDAK ADA MUSIM YANG BELUM SELESAI'
                              : activeFilter == 'SUDAH'
                                  ? 'TIDAK ADA MUSIM YANG SUDAH SELESAI'
                                  : 'BELUM ADA ARSIP MUSIM LAINNYA',
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: displayed.map((s) {
                            final isCurrent = AuthSession.currentIdMusim == s['idMusim'] ||
                                _currentSeasonTitle.contains(s['short'] as String);
                            final bool isSelesai = s['isSelesai'] == true;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  final idMusim = s['idMusim'] as String? ?? '';
                                  if (idMusim.isNotEmpty) {
                                    AuthSession.setActiveMusim(idMusim);
                                    FirestoreService.instance.setMusimAktif(AuthSession.currentIdPetani, idMusim);
                                    _subscribeBiaya(AuthSession.currentIdPetani, idMusim);
                                  }
                                  setState(() {
                                    final rawTitle = s['title'] as String? ?? 'Musim ${s['seasonNumber']}';
                                    _currentSeasonTitle = rawTitle.startsWith('Biaya & Pengeluaran')
                                        ? rawTitle
                                        : 'Biaya & Pengeluaran $rawTitle';
                                    FinanceDataStore.activeSeasonTitle = _currentSeasonTitle;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Beralih ke: $_currentSeasonTitle'),
                                      backgroundColor: AppColors.ink,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isCurrent ? AppColors.mint : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCurrent ? AppColors.forest : AppColors.ink,
                                      width: isCurrent ? 2 : 1.5,
                                    ),
                                    boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(2, 2))],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              s['title'] as String,
                                              style: AppTypography.display(fontSize: 14, fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusChip(
                                            label: isSelesai ? 'SUDAH SELESAI' : 'BELUM SELESAI',
                                            variant: isSelesai ? StatusChipVariant.dark : StatusChipVariant.orange,
                                            fontSize: 8.5,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      MicroText(s['period'] as String, fontSize: 9.5, color: AppColors.muted),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            s['expenses'] as String,
                                            style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w900),
                                          ),
                                          if (isCurrent)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.lime,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.ink, width: 1.2),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.check_rounded, size: 12, color: AppColors.ink),
                                                  const SizedBox(width: 3),
                                                  MicroText('SEDANG DIBUKA', fontSize: 8.5, fontWeight: FontWeight.w900, color: AppColors.ink),
                                                ],
                                              ),
                                            )
                                          else
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.touch_app_outlined, size: 12, color: AppColors.muted),
                                                const SizedBox(width: 3),
                                                MicroText('PILIH', fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.muted),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  TrapezoidTabButton(
                    label: 'SEMUA ARSIP MUSIM',
                    icon: Icons.folder_open_outlined,
                    onPressed: () {
                      Navigator.pop(ctx);
                      _navigateToSelectSeason();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final bg = isSelected ? (activeColor ?? AppColors.ink) : Colors.white;
    final fg = isSelected ? (activeColor == AppColors.lime ? AppColors.ink : Colors.white) : AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.ink, width: 1.3),
          boxShadow: isSelected
              ? const [BoxShadow(color: AppColors.ink, offset: Offset(1.5, 1.5))]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.mono(fontSize: 10, fontWeight: FontWeight.w900, color: fg),
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> _historyItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFE9),
      body: SafeArea(
        child: RetroFrame(
          backgroundColor: AppColors.sage,
          margin: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header dengan Sync Action
                AppHeader(
                  showBack: widget.showBack,
                  title: 'BUKU KAS BIAYA',
                  subtitle: 'KEUANGAN TANI // TEMANGGUNG',
                  padding: EdgeInsets.zero,
                  height: null,
                  logoSize: 40,
                  logoIcon: Icons.account_balance_wallet_rounded,
                  trailing: AppHeaderActionButton(
                    icon: Icons.sync_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data kas operasional berhasil diperbarui!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Judul & Deskripsi dengan Fitur Edit / Ganti Musim
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentSeasonTitle,
                            style: AppTypography.display(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Catat dan pantau seluruh modal pengeluaran musim tanam aktif.',
                            style: AppTypography.body(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showSeasonSelectionSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.ink, width: 1.5),
                          boxShadow: const [
                            BoxShadow(color: AppColors.ink, offset: Offset(2, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.ink),
                            SizedBox(width: 4),
                            MicroText('PILIH MUSIM', fontSize: 10, color: AppColors.ink, fontWeight: FontWeight.w900),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 2. Chip Filter Periode Musim
                _buildPeriodSelector(),
                const SizedBox(height: 14),

                // 3. Kartu Total Biaya dengan RingProgress Donut Chart
                _buildTotalExpenseCard(),
                const SizedBox(height: 16),

                // 4. Rincian 4 Pos Biaya Operasional (VuMeterBar)
                _buildCategoryBreakdown(),
                const SizedBox(height: 16),

                // 5. Riwayat Pengeluaran (Gaya Struk/Tiket)
                _buildHistorySection(),
                const SizedBox(height: 20),

                // 6. Tombol Tambah Catatan Biaya (Trapezoid CTA)
                TrapezoidTabButton(
                  label: 'TAMBAH CATATAN BIAYA',
                  icon: Icons.add_rounded,
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FinanceScreenEditUpload(),
                      ),
                    );
                    if (res == true && mounted) {
                      _listenToFirestore();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MicroText('PILIH PERIODE // FILTER', fontSize: 9.5),
        const SizedBox(height: 8),
        Row(
          children: List.generate(_periods.length, (index) {
            final isSelected = _selectedPeriod == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  if (index == 1) {
                    _navigateToSelectSeason();
                  } else {
                    setState(() => _selectedPeriod = index);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.ink : AppColors.paper,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.ink, width: 1.5),
                    boxShadow: isSelected
                        ? const [
                            BoxShadow(color: AppColors.lime, offset: Offset(2, 2)),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(Icons.check_rounded, color: AppColors.lime, size: 14),
                        const SizedBox(width: 4),
                      ],
                      MicroText(
                        _periods[index],
                        fontSize: 10,
                        color: isSelected ? AppColors.paper : AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTotalExpenseCard() {
    final allCatsZero = _categories.every((c) =>
        c['amount'] == 'Rp 0' ||
        c['amount'] == 'Rp 0 jt' ||
        c['amount'] == 'Rp 0 rb');
    final displayTotal = (_firestoreBiayaList.isEmpty && allCatsZero)
        ? 'Rp 0'
        : _currentTotalExpense;

    return RetroCard(
      tapeTag: 'TOTAL BIAYA // ESTIMASI MUSIM TANAM',
      rightTag: '4 POS BIAYA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MicroText('TOTAL PENGELUARAN TERCATAT', fontSize: 9, color: AppColors.muted),
          const SizedBox(height: 4),
          Text(
            displayTotal,
            style: AppTypography.display(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tercatat dari 4 kategori pengeluaran operasional.',
            style: AppTypography.body(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TaperedDivider(centerLabel: 'RINCIAN 4 POS BIAYA'),
        const SizedBox(height: 6),
        ..._categories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RetroCard(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(cat['icon'] as IconData, size: 16, color: AppColors.ink),
                          const SizedBox(width: 6),
                          Text(
                            cat['name'] as String,
                            style: AppTypography.display(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      Text(
                        cat['amount'] as String,
                        style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  VuMeterBar(
                    value: cat['ratio'] as double,
                    height: 8,
                    totalSegments: 16,
                    label: 'ALOKASI',
                    valueText: cat['percentage'] as String,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHistorySection() {
    final hasFirestore = _firestoreBiayaList.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TaperedDivider(centerLabel: 'RIWAYAT PENGELUARAN TERBARU'),
        const SizedBox(height: 6),
        if (hasFirestore)
          ..._firestoreBiayaList.map((item) {
            IconData icon;
            switch (item.kodeKategori) {
              case 'BURUH':
                icon = Icons.groups_rounded;
                break;
              case 'PUPUK':
                icon = Icons.science_outlined;
                break;
              case 'BIBIT':
                icon = Icons.spa_outlined;
                break;
              default:
                icon = Icons.category_outlined;
            }
            final dateStr = '${item.tanggal.day} ${_namaBulan(item.tanggal.month)} ${item.tanggal.year}';
            final amountStr = '-Rp ${_formatAngka(item.jumlahBiaya)}';

            return RetroCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: AppColors.lime, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.namaPengeluaran,
                          style: AppTypography.display(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '$dateStr • ${item.namaKategoriDisplay}',
                          style: AppTypography.mono(fontSize: 9.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amountStr,
                        style: AppTypography.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FinanceScreenEditUpload(
                                    initialData: {
                                      'idBiaya': item.idBiaya,
                                      'title': item.namaPengeluaran,
                                      'amount': item.jumlahBiaya.round().toString(),
                                      'category': item.namaKategoriDisplay,
                                      'notes': item.catatan,
                                    },
                                  ),
                                ),
                              );
                              if (res == true && mounted) {
                                _listenToFirestore();
                              }
                            },
                            child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.ink),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _confirmDeleteExpense(item.namaPengeluaran, idBiaya: item.idBiaya),
                            child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          })
        else
          RetroCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ink, width: 1.5),
                  ),
                  child: const Icon(Icons.receipt_long_outlined, color: AppColors.muted, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  'BELUM ADA PENGELUARAN',
                  style: AppTypography.display(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const MicroText(
                  'Belum ada catatan biaya operasional di musim ini.\nTekan tombol di bawah untuk menambah catatan biaya.',
                  fontSize: 9.5,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _confirmDeleteExpense(String title, {String? idBiaya}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text('HAPUS PENGELUARAN', style: AppTypography.display(fontSize: 15, fontWeight: FontWeight.w900)),
        content: Text('Apakah Anda yakin ingin menghapus catatan "$title"? Tindakan ini tidak dapat dibatalkan.',
            style: AppTypography.body(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('BATAL', style: AppTypography.mono(fontSize: 11, color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              if (idBiaya != null) {
                try {
                  await FirestoreService.instance.hapusBiayaSoft(
                    idPetani: AuthSession.currentIdPetani,
                    idMusim: AuthSession.currentIdMusim,
                    idBiaya: idBiaya,
                  );
                } catch (_) {}
              }
              setState(() {
                _historyItems.removeWhere((i) => i['title'] == title);
                _firestoreBiayaList.removeWhere((i) => i.idBiaya == idBiaya);
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Catatan "$title" berhasil dihapus!')),
                );
              }
            },
            child: Text('YA, HAPUS', style: AppTypography.mono(fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
