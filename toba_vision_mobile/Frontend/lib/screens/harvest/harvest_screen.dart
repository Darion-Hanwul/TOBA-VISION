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
import 'harvest_all_musim_screen.dart';
import 'harvest_edit_screen.dart';

class HarvestScreen extends StatefulWidget {
  final bool showBack;
  const HarvestScreen({super.key, this.showBack = false});

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  int _selectedPeriod = 0; // 0: Musim Ini, 1: Semua
  final List<String> _periods = ['Musim Ini', 'Semua'];

  int _activeStep = 1; // Tahap Petikan ke-1 (P1) aktif
  int _unlockedStep = 1; // Batas tertinggi petikan yang sudah terbuka
  Map<String, PetikanPanenModel> _firestorePanenMap = {};
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _revenueController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  StreamSubscription<List<PetikanPanenModel>>? _panenSub;
  StreamSubscription<List<BiayaOperasionalModel>>? _biayaSub;
  bool _isSavingPetikan = false;
  double _totalOmzetPanen = 0.0;
  double _totalBobotKg = 0.0;
  double _totalBiayaKeuangan = 0.0;
  String _currentSeasonTitle = 'Musim Tanam Aktif';

  final List<String> _stages = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7'];

  final List<Map<String, dynamic>> _chartData = [
    {'stage': 'P1', 'weight': '-', 'height': 24.0, 'isActive': true},
    {'stage': 'P2', 'weight': '-', 'height': 15.0, 'isUpcoming': true},
    {'stage': 'P3', 'weight': '-', 'height': 15.0, 'isUpcoming': true},
    {'stage': 'P4', 'weight': '-', 'height': 15.0, 'isUpcoming': true},
    {'stage': 'P5', 'weight': '-', 'height': 15.0, 'isUpcoming': true},
    {'stage': 'P6', 'weight': '-', 'height': 15.0, 'isUpcoming': true},
    {'stage': 'P7', 'weight': '-', 'height': 15.0, 'isUpcoming': true},
  ];

  @override
  void initState() {
    super.initState();
    _listenToHarvestFirestore();
  }

  @override
  void dispose() {
    _panenSub?.cancel();
    _biayaSub?.cancel();
    _weightController.dispose();
    _revenueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _listenToHarvestFirestore() {
    final idPetani = AuthSession.currentIdPetani;
    if (idPetani.isEmpty) {
      _applyFirestorePanenData([]);
      if (mounted) setState(() => _totalBiayaKeuangan = 0.0);
      return;
    }

    FirestoreService.instance.getOrCreateMusimAktif(idPetani).then((musim) {
      if (!mounted) return;
      AuthSession.setActiveMusim(musim.idMusim);
      setState(() {
        _currentSeasonTitle = musim.judulMusim;
      });
      _subscribePanen(idPetani, musim.idMusim);
      _subscribeBiaya(idPetani, musim.idMusim);
    });

    final currentIdMusim = AuthSession.currentIdMusim;
    if (currentIdMusim.isNotEmpty) {
      _subscribePanen(idPetani, currentIdMusim);
      _subscribeBiaya(idPetani, currentIdMusim);
    }
  }

  void _subscribePanen(String idPetani, String idMusim) {
    _panenSub?.cancel();
    if (idPetani.isEmpty || idMusim.isEmpty) {
      _applyFirestorePanenData([]);
      return;
    }
    _panenSub = FirestoreService.instance.streamDaftarPetikan(idPetani, idMusim).listen((list) {
      if (!mounted) return;
      _applyFirestorePanenData(list);
    }, onError: (_) {
      // Graceful offline fallback
    });
  }

  void _subscribeBiaya(String idPetani, String idMusim) {
    _biayaSub?.cancel();
    if (idPetani.isEmpty || idMusim.isEmpty) {
      if (mounted) setState(() => _totalBiayaKeuangan = 0.0);
      return;
    }
    _biayaSub = FirestoreService.instance.streamDaftarBiaya(idPetani, idMusim).listen((list) {
      if (!mounted) return;
      double total = 0.0;
      for (final item in list) {
        total += item.jumlahBiaya;
      }
      setState(() {
        _totalBiayaKeuangan = total;
      });
    }, onError: (_) {
      // Graceful offline fallback
    });
  }

  String _formatRupiah(double val) {
    final intVal = val.round();
    final s = intVal.abs().toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = s.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  void _applyFirestorePanenData(List<PetikanPanenModel> list) {
    if (list.isEmpty) {
      setState(() {
        _totalBobotKg = 0.0;
        _totalOmzetPanen = 0.0;
        _unlockedStep = 1;
        _activeStep = 1;
        _firestorePanenMap = {};
        _weightController.clear();
        _revenueController.clear();
        _noteController.clear();

        for (int i = 0; i < _stages.length; i++) {
          final stageCode = _stages[i];
          if (i == 0) {
            _chartData[i] = {
              'stage': stageCode,
              'weight': '-',
              'height': 24.0,
              'isActive': true,
            };
          } else {
            _chartData[i] = {
              'stage': stageCode,
              'weight': '-',
              'height': 15.0,
              'isUpcoming': true,
            };
          }
        }
      });
      return;
    }

    double totalKg = 0;
    double totalRev = 0;
    final Map<String, PetikanPanenModel> map = {
      for (final p in list) p.kodeSiklus: p
    };

    for (final p in list) {
      totalKg += p.beratKg;
      totalRev += p.estimasiPendapatan;
    }

    int highestSaved = 0;
    for (int i = 0; i < _stages.length; i++) {
      if (map.containsKey(_stages[i])) {
        highestSaved = i + 1;
      }
    }
    final nextStep = (highestSaved + 1).clamp(1, 7);

    setState(() {
      _totalBobotKg = totalKg;
      _totalOmzetPanen = totalRev;
      _unlockedStep = nextStep;
      _activeStep = nextStep;
      _firestorePanenMap = map;

      _weightController.clear();
      _revenueController.clear();
      _noteController.clear();
      _selectedDate = DateTime.now();

      for (int i = 0; i < _stages.length; i++) {
        final stageCode = _stages[i];
        final stepNum = i + 1;
        final petikan = map[stageCode];

        if (petikan != null) {
          _chartData[i] = {
            'stage': stageCode,
            'weight': '${petikan.beratKg.round()} kg',
            'height': (petikan.beratKg / 15).clamp(18.0, 75.0),
            'isDone': true,
          };
        } else if (stepNum == nextStep) {
          _chartData[i] = {
            'stage': stageCode,
            'weight': '-',
            'height': 24.0,
            'isActive': true,
          };
        } else {
          _chartData[i] = {
            'stage': stageCode,
            'weight': '-',
            'height': 15.0,
            'isUpcoming': true,
          };
        }
      }
    });
  }

  void _setActiveStep(int stepNum) {
    if (stepNum > _unlockedStep) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Petikan P$stepNum masih terkunci! Selesaikan petikan P$_unlockedStep terlebih dahulu.',
                  style: AppTypography.mono(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.ink,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _activeStep = stepNum;
      final stageCode = _stages[stepNum - 1];
      final existing = _firestorePanenMap[stageCode];
      if (existing != null) {
        _weightController.text = existing.beratKg.round().toString();
        _revenueController.text = existing.estimasiPendapatan.round().toString();
        _noteController.text = existing.kondisiDaun ?? '';
        _selectedDate = existing.tanggalPetik;
      } else {
        _weightController.clear();
        _revenueController.clear();
        _noteController.clear();
        _selectedDate = DateTime.now();
      }
    });
  }

  Future<void> _saveCurrentPetikan() async {
    final weight = double.tryParse(_weightController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final rev = double.tryParse(_revenueController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final note = _noteController.text.trim();
    final stageCode = _stages[_activeStep - 1];

    if (_activeStep > _unlockedStep) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Petikan P$_activeStep masih terkunci! Selesaikan petikan P$_unlockedStep terlebih dahulu.'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan berat tembakau (kg) terlebih dahulu!'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _isSavingPetikan = true);

    try {
      await FirestoreService.instance.simpanPetikanPanen(
        idPetani: AuthSession.currentIdPetani,
        idMusim: AuthSession.currentIdMusim,
        kodeSiklus: stageCode,
        petikanKe: _activeStep,
        beratKg: weight,
        estimasiPendapatan: rev,
        tanggalPetik: _selectedDate,
        kondisiDaun: note.isNotEmpty ? note : null,
      );

      if (mounted) {
        _weightController.clear();
        _revenueController.clear();
        _noteController.clear();
        _listenToHarvestFirestore();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Petikan $stageCode ($weight kg) berhasil dicatat ke database!'),
            backgroundColor: AppColors.ink,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tersimpan offline/lokal: $e'),
            backgroundColor: AppColors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingPetikan = false);
      }
    }
  }

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
                // 1. Header
                AppHeader(
                  showBack: widget.showBack,
                  title: 'PANEN & HASIL PETIK',
                  subtitle: 'LAHAN BLOK A • TEMANGGUNG',
                  padding: EdgeInsets.zero,
                  height: null,
                  logoSize: 40,
                  logoIcon: Icons.agriculture_rounded,
                  trailing: AppHeaderActionButton(
                    icon: Icons.sync_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sinkronisasi data panen petani berhasil diperbarui!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Judul & Deskripsi dengan Fitur Ganti / Buat Musim
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
                            'Pantau pemetikan tembakau (${_totalBobotKg.round()} kg tercatat musim ini).',
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

                // 2. Filter Periode Musim
                _buildPeriodSelector(),
                const SizedBox(height: 14),

                // 3. Stepper 7 Tahapan Siklus Petikan Daun (P1 s/d P7)
                _buildStepTrackerCard(),
                const SizedBox(height: 16),

                // 4. Milestone BEP & Target Keuntungan (VuMeterBar & Equalizer)
                _buildMilestoneProfitCard(),
                const SizedBox(height: 16),

                // 5. Timbangan Hari Ini Input Card
                _buildWeighingInputCard(),
                const SizedBox(height: 20),

                // 6. Tombol Aksi Simpan & Tutup Buku Siklus
                _buildCtaButtonSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSeasonSelectionSheet() async {
    List<Map<String, dynamic>> seasons = [];
    try {
      final list = await FirestoreService.instance.getSemuaMusim(AuthSession.currentIdPetani);
      for (final m in list) {
        final bool isSelesai = m.status == 'SELESAI';
        seasons.add({
          'idMusim': m.idMusim,
          'seasonNumber': m.nomorMusim,
          'title': m.judulMusim,
          'short': 'Musim ${m.nomorMusim}',
          'period': 'Mulai ${m.tanggalMulai.day}/${m.tanggalMulai.month}/${m.tanggalMulai.year} • ${m.lokasiBlok}',
          'harvest': '${m.totalBobotPanenCache.toStringAsFixed(0)} kg tembakau',
          'revenue': _formatRupiah(m.totalPendapatanCache),
          'status': isSelesai ? 'SELESAI' : 'BELUM SELESAI',
          'isSelesai': isSelesai,
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
                  const MicroText('PILIH MUSIM UNTUK MENAMPILKAN SIKLUS PANEN', fontSize: 9, color: AppColors.muted),
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
                                    _subscribePanen(AuthSession.currentIdPetani, idMusim);
                                    _subscribeBiaya(AuthSession.currentIdPetani, idMusim);
                                  }
                                  setState(() {
                                    _currentSeasonTitle = s['title'] as String? ?? 'Musim ${s['seasonNumber']}';
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
                                            s['harvest'] as String,
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
                    label: 'SEMUA ARSIP PANEN',
                    icon: Icons.folder_open_outlined,
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HarvestAllMusimScreen(),
                        ),
                      ).then((_) {
                        if (mounted) {
                          setState(() => _selectedPeriod = 0);
                          _listenToHarvestFirestore();
                        }
                      });
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

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MicroText('PILIH PERIODE // SIKLUS', fontSize: 9.5),
        const SizedBox(height: 8),
        Row(
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
                        builder: (context) => const HarvestAllMusimScreen(),
                      ),
                    ).then((_) {
                      if (mounted) {
                        setState(() => _selectedPeriod = 0);
                        _listenToHarvestFirestore();
                      }
                    });
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
                        ? const [BoxShadow(color: AppColors.lime, offset: Offset(2, 2))]
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

  Widget _buildStepTrackerCard() {
    return RetroCard(
      tapeTag: 'SIKLUS PETIKAN // 7 TAHAP',
      rightTag: 'P$_activeStep AKTIF',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Siklus Petikan Daun',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(label: 'P$_activeStep AKTIF', variant: StatusChipVariant.lime),
            ],
          ),
          const SizedBox(height: 14),

          // 7-Step Button Bar Ala Tape-Deck Track Select
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_stages.length, (index) {
                final stepNum = index + 1;
                final isDone = stepNum < _unlockedStep;
                final isActive = stepNum == _activeStep;
                final isLocked = stepNum > _unlockedStep;

                return GestureDetector(
                  onTap: () async {
                    if (isLocked) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.lock_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Petikan P$stepNum masih terkunci! Selesaikan petikan P$_unlockedStep terlebih dahulu.',
                                  style: AppTypography.mono(fontSize: 11, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.ink,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    if (isActive) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HarvestEditScreen(
                            initialStep: stepNum,
                            stageName: _stages[index],
                            maxUnlockedStep: _unlockedStep,
                            initialWeight: _weightController.text,
                            initialRevenue: _revenueController.text,
                            initialNote: _noteController.text,
                          ),
                        ),
                      );

                      if (result != null && mounted) {
                        setState(() {
                          _weightController.text = result['weight'] ?? _weightController.text;
                          _revenueController.text = result['revenue'] ?? _revenueController.text;
                          if (result['note'] != null) {
                            _noteController.text = result['note'];
                          }
                        });
                        _listenToHarvestFirestore();
                      }
                    } else {
                      _setActiveStep(stepNum);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.orange
                          : isDone
                              ? AppColors.lime
                              : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isLocked ? AppColors.muted.withValues(alpha: 0.35) : AppColors.ink,
                        width: 1.5,
                      ),
                      boxShadow: isActive
                          ? const [BoxShadow(color: AppColors.ink, offset: Offset(2, 2))]
                          : (isDone ? const [BoxShadow(color: AppColors.ink, offset: Offset(1, 1))] : null),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$stepNum',
                          style: AppTypography.mono(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isActive
                                ? Colors.white
                                : (isDone ? AppColors.ink : AppColors.muted),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLocked) ...[
                              Icon(Icons.lock_outline_rounded, size: 8, color: AppColors.muted.withValues(alpha: 0.8)),
                              const SizedBox(width: 2),
                            ],
                            MicroText(
                              _stages[index],
                              fontSize: 9,
                              color: isActive
                                  ? Colors.white
                                  : (isDone ? AppColors.ink : AppColors.muted),
                              fontWeight: FontWeight.w800,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneProfitCard() {
    final targetModal = _totalBiayaKeuangan;
    final omzet = _totalOmzetPanen;
    final hasHarvest = _totalBobotKg > 0 || omzet > 0;

    // Apakah omzet panen sudah mencapai target modal atau impas
    final bool isTargetReached = targetModal > 0
        ? (omzet >= targetModal)
        : hasHarvest;

    final double netProfit = omzet - targetModal;
    final double sisaTarget = (targetModal - omzet).clamp(0.0, double.infinity);

    final double ratio = targetModal > 0
        ? (omzet / targetModal).clamp(0.0, 1.0)
        : (hasHarvest ? 1.0 : 0.0);
    final int percent = (ratio * 100).round();

    final String cardHeaderTitle;
    final String amountText;
    final Color amountColor;
    final String statusLabel;
    final StatusChipVariant statusVariant;

    if (targetModal == 0 && !hasHarvest) {
      cardHeaderTitle = 'TARGET MODAL & KEUNTUNGAN';
      amountText = 'Rp 0';
      amountColor = AppColors.ink;
      statusLabel = 'BELUM ADA BIAYA';
      statusVariant = StatusChipVariant.dark;
    } else if (isTargetReached) {
      // Panen >= Modal: Profit Tercapai (Warna Hijau)
      cardHeaderTitle = 'KEUNTUNGAN BERSIH // PROFIT';
      amountText = '+${_formatRupiah(netProfit)}';
      amountColor = AppColors.green;
      statusLabel = 'BEP TERCAPAI';
      statusVariant = StatusChipVariant.lime;
    } else {
      // Panen < Modal: Target belum tercapai (Warna Merah)
      if (!hasHarvest) {
        cardHeaderTitle = 'TARGET MODAL HARUS DIKEJAR';
        amountText = _formatRupiah(targetModal);
      } else {
        cardHeaderTitle = 'SISA TARGET HARUS DIKEJAR';
        amountText = _formatRupiah(sisaTarget);
      }
      amountColor = AppColors.red;
      statusLabel = 'PROSES BEP';
      statusVariant = StatusChipVariant.danger;
    }

    return RetroCard(
      tapeTag: 'MILESTONE // PROFIT & BEP',
      rightTag: targetModal > 0 ? 'TARGET: ${_formatRupiah(targetModal)}' : 'TARGET BEP',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MicroText(cardHeaderTitle, fontSize: 9, color: AppColors.muted),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        amountText,
                        style: AppTypography.display(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: amountColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: statusLabel,
                variant: statusVariant,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Equalizer VuMeterBar
          VuMeterBar(
            value: ratio,
            height: 10,
            totalSegments: 16,
            label: targetModal > 0 ? 'TARGET BEP ${_formatRupiah(targetModal)}' : 'TARGET LABA',
            valueText: '$percent% TERCAPAI',
          ),
          const SizedBox(height: 12),

          // Info Box Modal Lunas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.ink, width: 1.5),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTargetReached ? Icons.check_circle_rounded : Icons.flag_rounded,
                      size: 16,
                      color: isTargetReached ? AppColors.green : AppColors.amber,
                    ),
                    const SizedBox(width: 6),
                    MicroText(
                      isTargetReached
                          ? 'MODAL ${_formatRupiah(targetModal)} LUNAS'
                          : 'MODAL ${_formatRupiah(targetModal)}',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ],
                ),
                MicroText(
                  !hasHarvest
                      ? (targetModal > 0 ? 'BELUM PANEN' : 'SIAP MULAI PETIKAN P1')
                      : (isTargetReached
                          ? 'UNTUNG +${_formatRupiah(netProfit)}'
                          : 'KURANG ${_formatRupiah(sisaTarget)} (HASIL ${_formatRupiah(omzet)})'),
                  fontSize: 9.5,
                  color: isTargetReached ? AppColors.green : AppColors.red,
                  fontWeight: FontWeight.w900,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Equalizer Bar Chart Distribusi Hasil Petikan
          const TaperedDivider(centerLabel: 'DISTRIBUSI PETIKAN (KG)'),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.ink, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _chartData.map((data) {
                final isActive = data['isActive'] == true;
                final isDone = data['isDone'] == true;
                final height = data['height'] as double;

                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          data['weight'] as String,
                          style: AppTypography.mono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: isActive ? AppColors.orange : AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 16,
                        height: height,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.orange
                              : isDone
                                  ? AppColors.lime
                                  : const Color(0xFFE2E8F0),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          border: Border.all(color: AppColors.ink, width: 1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: MicroText(
                          data['stage'] as String,
                          fontSize: 9,
                          fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                          color: isActive ? AppColors.orange : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeighingInputCard() {
    return RetroCard(
      tapeTag: 'TIMBANGAN // PETIKAN P$_activeStep',
      rightTag: 'HARI INI',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Timbangan Petikan P$_activeStep',
                  style: AppTypography.display(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              const StatusChip(label: 'HARI INI', variant: StatusChipVariant.dark, fontSize: 8),
            ],
          ),
          const SizedBox(height: 10),

          // Field Berat Tembakau (kg)
          const MicroText('BERAT TEMBAKAU (KG)', fontSize: 9.5),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.mono(fontSize: 16, fontWeight: FontWeight.w900),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text('KG', style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Field Total Pendapatan (Rp)
          const MicroText('TOTAL ESTIMASI PENDAPATAN KOTOR (RP)', fontSize: 9.5),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('Rp', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                ),
                Expanded(
                  child: TextField(
                    controller: _revenueController,
                    keyboardType: TextInputType.number,
                    style: AppTypography.mono(fontSize: 16, fontWeight: FontWeight.w900),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Field Tanggal Penimbangan / Petikan
          const MicroText('TANGGAL PENIMBANGAN / PETIKAN', fontSize: 9.5),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                    style: AppTypography.mono(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.ink),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Field Keterangan / Kondisi Daun
          const MicroText('KETERANGAN / KONDISI DAUN', fontSize: 9.5),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 3,
              style: AppTypography.mono(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Misal: Petikan pucuk daun, warna kuning merata',
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButtonSection() {
    return Column(
      children: [
        // Tombol Simpan CTA Trapesium Oranye
        TrapezoidTabButton(
          label: _isSavingPetikan ? 'MENYIMPAN DATA...' : 'SIMPAN PETIKAN P$_activeStep',
          isLoading: _isSavingPetikan,
          icon: Icons.check_circle_outline_rounded,
          onPressed: _isSavingPetikan ? null : _saveCurrentPetikan,
        ),
        const SizedBox(height: 16),

        // Bagian Tutup Buku Musim
        _buildCloseBookBanner(),
      ],
    );
  }

  Widget _buildCloseBookBanner() {
    return RetroCard(
      tapeTag: 'TUTUP BUKU // AKHIR MUSIM',
      rightTag: 'FINAL REKAP',
      backgroundColor: const Color(0xFFFFF1F2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tutup Buku & Arsipkan Musim Ini',
            style: AppTypography.display(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.red),
          ),
          const SizedBox(height: 4),
          Text(
            'Tutup buku pengeluaran dan simpan rekap akhir musim ini ke arsip laporan perkebunan.',
            style: AppTypography.body(fontSize: 11.5, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          TrapezoidTabButton(
            label: 'TUTUP BUKU & SIMPAN REKAP',
            backgroundColor: AppColors.red,
            textColor: Colors.white,
            height: 40,
            onPressed: _showCloseCycleDialog,
          ),
        ],
      ),
    );
  }

  void _showCloseCycleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text('TUTUP BUKU SIKLUS', style: AppTypography.display(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.red)),
        content: Text(
          'Apakah Anda yakin ingin menutup buku siklus panen musim ini? Rekap akhir akan diarsipkan dan musim tanam baru akan otomatis dibuka.',
          style: AppTypography.body(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('BATAL', style: AppTypography.mono(fontSize: 11, color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final musimBaru = await FirestoreService.instance.tutupBukuMusimAtomik(
                  idPetani: AuthSession.currentIdPetani,
                  idMusimLama: AuthSession.currentIdMusim,
                  judulMusimBaru: '',
                );
                AuthSession.setActiveMusim(musimBaru.idMusim);
                _listenToHarvestFirestore();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Buku siklus ditutup! ${musimBaru.judulMusim} resmi dimulai.'),
                      backgroundColor: AppColors.forestGreen,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Siklus ditutup: $e'),
                      backgroundColor: AppColors.ink,
                    ),
                  );
                }
              }
            },
            child: Text('YA, TUTUP BUKU', style: AppTypography.mono(fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
