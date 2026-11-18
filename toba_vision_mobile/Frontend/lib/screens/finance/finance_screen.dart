import 'package:flutter/material.dart';
import '../../core/theme.dart';
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

class FinanceDataStore {
  static String activeSeasonTitle = 'Biaya & Pengeluaran Musim 3';
  static String activeTotalExpense = 'Rp 14.250.000';
  static Map<String, dynamic>? activeSeasonData;
}

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
  String _currentTotalExpense = FinanceDataStore.activeTotalExpense;
  late List<Map<String, dynamic>> _categories;

  @override
  void initState() {
    super.initState();
    _initCategories();
    if (widget.initialSeasonData != null) {
      _applySeasonData(widget.initialSeasonData!);
    } else if (FinanceDataStore.activeSeasonData != null) {
      _applySeasonData(FinanceDataStore.activeSeasonData!);
    }
  }

  void _initCategories() {
    _categories = [
      {
        'name': 'Buruh Tani / Upah',
        'amount': 'Rp 6,8 jt',
        'ratio': 0.48,
        'percentage': '48%',
        'icon': Icons.groups_rounded,
        'color': AppColors.forest,
      },
      {
        'name': 'Pupuk & Nutrisi',
        'amount': 'Rp 3,8 jt',
        'ratio': 0.27,
        'percentage': '27%',
        'icon': Icons.science_outlined,
        'color': AppColors.limeDeep,
      },
      {
        'name': 'Bibit & Olah Lahan',
        'amount': 'Rp 2,4 jt',
        'ratio': 0.17,
        'percentage': '17%',
        'icon': Icons.spa_outlined,
        'color': AppColors.orange,
      },
      {
        'name': 'Lainnya / Tambahan',
        'amount': 'Rp 1,25 jt',
        'ratio': 0.08,
        'percentage': '8%',
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
    final seasonNum = season['seasonNumber'] as int?;
    final rawTitle = season['title'] as String? ?? '';
    final lower = rawTitle.toLowerCase();

    if (seasonNum == 2 || lower.contains('kedua') || lower.contains('musim 2')) {
      _historyItems
        ..clear()
        ..addAll([
          {
            'title': 'Upah Petik Daun Bawah',
            'date': '12 Sep 2023 • 8 Pekerja',
            'amount': '-Rp 1.100.000',
            'icon': Icons.groups_rounded,
          },
          {
            'title': 'Pupuk ZA & NPK Daun',
            'date': '18 Agu 2023 • Toko Tani Maju',
            'amount': '-Rp 780.000',
            'icon': Icons.science_outlined,
          },
          {
            'title': 'Sewa Traktor Lahan Blok A',
            'date': '02 Jul 2023 • Olah Tanah',
            'amount': '-Rp 550.000',
            'icon': Icons.agriculture_rounded,
          },
          {
            'title': 'Bibit Unggul Temanggung',
            'date': '20 Mei 2023 • 4500 Batang',
            'amount': '-Rp 1.350.000',
            'icon': Icons.spa_outlined,
          },
        ]);
    } else if (seasonNum == 1 || lower.contains('pertama') || lower.contains('kesatu') || lower.contains('musim 1')) {
      _historyItems
        ..clear()
        ..addAll([
          {
            'title': 'Upah Petik Daun Bawah',
            'date': '15 Sep 2022 • 7 Pekerja',
            'amount': '-Rp 950.000',
            'icon': Icons.groups_rounded,
          },
          {
            'title': 'Pupuk ZA & NPK Daun',
            'date': '22 Jul 2022 • Toko Tani Maju',
            'amount': '-Rp 700.000',
            'icon': Icons.science_outlined,
          },
          {
            'title': 'Sewa Traktor Lahan Blok A',
            'date': '10 Jun 2022 • Olah Tanah',
            'amount': '-Rp 500.000',
            'icon': Icons.agriculture_rounded,
          },
          {
            'title': 'Bibit Unggul Temanggung',
            'date': '05 Jun 2022 • 4000 Batang',
            'amount': '-Rp 1.200.000',
            'icon': Icons.spa_outlined,
          },
        ]);
    } else {
      _historyItems
        ..clear()
        ..addAll([
          {
            'title': 'Upah Petik Daun Bawah',
            'date': '12 Okt 2024 • 8 Pekerja',
            'amount': '-Rp 1.200.000',
            'icon': Icons.groups_rounded,
          },
          {
            'title': 'Pupuk ZA & NPK Daun',
            'date': '08 Okt 2024 • Toko Tani Maju',
            'amount': '-Rp 850.000',
            'icon': Icons.science_outlined,
          },
          {
            'title': 'Sewa Traktor Lahan Blok A',
            'date': '24 Sep 2024 • Olah Tanah',
            'amount': '-Rp 600.000',
            'icon': Icons.agriculture_rounded,
          },
          {
            'title': 'Bibit Unggul Temanggung',
            'date': '18 Sep 2024 • 5000 Batang',
            'amount': '-Rp 1.500.000',
            'icon': Icons.spa_outlined,
          },
        ]);
    }
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
      }
    }
  }

  void _showSeasonSelectionSheet() {
    final seasons = [
      {
        'seasonNumber': 3,
        'title': 'Musim Ketiga (2024)',
        'short': 'Musim 3',
        'period': 'Mei - Okt 2024 • Lahan Blok A & B',
        'expenses': 'Rp 14.250.000',
        'harvest': '3.200 kg tembakau',
        'status': 'Selesai',
        'labor': 'Rp 6.840.000',
        'fertilizer': 'Rp 3.847.500',
        'seed': 'Rp 2.422.500',
        'other': 'Rp 1.140.000',
      },
      {
        'seasonNumber': 2,
        'title': 'Musim Kedua (2023)',
        'short': 'Musim 2',
        'period': 'Mei - Sep 2023 • Lahan Blok A',
        'expenses': 'Rp 12.800.000',
        'harvest': '2.850 kg tembakau',
        'status': 'Selesai',
        'labor': 'Rp 6.144.000',
        'fertilizer': 'Rp 3.456.000',
        'seed': 'Rp 2.176.000',
        'other': 'Rp 1.024.000',
      },
      {
        'seasonNumber': 1,
        'title': 'Musim Pertama (2022)',
        'short': 'Musim 1',
        'period': 'Jun - Okt 2022 • Lahan Blok A',
        'expenses': 'Rp 11.450.000',
        'harvest': '2.600 kg tembakau',
        'status': 'Selesai',
        'labor': 'Rp 5.496.000',
        'fertilizer': 'Rp 3.091.500',
        'seed': 'Rp 1.946.500',
        'other': 'Rp 916.000',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
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
              const SizedBox(height: 14),
              ...seasons.map((s) {
                final isCurrent = _currentSeasonTitle.contains(s['short'] as String);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _applySeasonData(s);
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
                          color: isCurrent ? AppColors.limeDeep : AppColors.ink,
                          width: isCurrent ? 2 : 1.5,
                        ),
                        boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(2, 2))],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['title'] as String,
                                  style: AppTypography.display(fontSize: 14, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                MicroText(s['period'] as String, fontSize: 9.5, color: AppColors.muted),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                s['expenses'] as String,
                                style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              if (isCurrent)
                                const StatusChip(label: 'AKTIF', variant: StatusChipVariant.lime)
                              else
                                const MicroText('PILIH', fontSize: 9, color: AppColors.muted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
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
      ),
    );
  }

  final List<Map<String, dynamic>> _historyItems = [
    {
      'title': 'Upah Petik Daun Bawah',
      'date': '12 Okt 2026 • 8 Pekerja',
      'amount': '-Rp 1.200.000',
      'icon': Icons.groups_rounded,
    },
    {
      'title': 'Pupuk ZA & NPK Daun',
      'date': '08 Okt 2026 • Toko Tani Maju',
      'amount': '-Rp 850.000',
      'icon': Icons.science_outlined,
    },
    {
      'title': 'Sewa Traktor Lahan Blok A',
      'date': '24 Sep 2026 • Olah Tanah',
      'amount': '-Rp 600.000',
      'icon': Icons.agriculture_rounded,
    },
    {
      'title': 'Bibit Unggul Temanggung',
      'date': '18 Sep 2026 • 5000 Batang',
      'amount': '-Rp 1.500.000',
      'icon': Icons.spa_outlined,
    },
  ];

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
                          children: [
                            const Icon(Icons.edit_outlined, size: 14, color: AppColors.ink),
                            const SizedBox(width: 4),
                            MicroText('EDIT', fontSize: 10, color: AppColors.ink, fontWeight: FontWeight.w900),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FinanceScreenEditUpload(),
                      ),
                    );
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
    return RetroCard(
      tapeTag: 'TOTAL BIAYA // ESTIMASI MUSIM TANAM',
      rightTag: '4 POS BIAYA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MicroText('TOTAL PENGELUARAN TERCATAT', fontSize: 9, color: AppColors.muted),
          const SizedBox(height: 4),
          Text(
            _currentTotalExpense,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TaperedDivider(centerLabel: 'RIWAYAT PENGELUARAN TERBARU'),
        const SizedBox(height: 6),
        ..._historyItems.map((item) {
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
                  child: Icon(item['icon'] as IconData, color: AppColors.lime, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: AppTypography.display(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        item['date'] as String,
                        style: AppTypography.mono(fontSize: 9.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item['amount'] as String,
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FinanceScreenEditUpload(
                                  initialData: {
                                    'title': item['title'],
                                    'amount': item['amount'].toString().replaceAll('-Rp ', '').replaceAll('.', ''),
                                  },
                                ),
                              ),
                            );
                          },
                          child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.ink),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _confirmDeleteExpense(item['title'] as String),
                          child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _confirmDeleteExpense(String title) {
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
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _historyItems.removeWhere((i) => i['title'] == title));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Catatan "$title" berhasil dihapus!')),
              );
            },
            child: Text('YA, HAPUS', style: AppTypography.mono(fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
