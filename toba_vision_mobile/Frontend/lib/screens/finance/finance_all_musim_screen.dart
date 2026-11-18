import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/retro/blade_ornament.dart';
import '../../widgets/retro/micro_text.dart';
import '../../widgets/retro/retro_card.dart';
import '../../widgets/retro/retro_frame.dart';
import '../../widgets/retro/status_chip.dart';
import '../../widgets/retro/trapezoid_tab_button.dart';
import 'finance_screen.dart';

class FinanceAllMusimScreen extends StatefulWidget {
  const FinanceAllMusimScreen({super.key});

  @override
  State<FinanceAllMusimScreen> createState() => _FinanceAllMusimScreenState();
}

class _FinanceAllMusimScreenState extends State<FinanceAllMusimScreen> {
  final List<Map<String, dynamic>> _seasonHistory = [
    {
      'seasonNumber': 3,
      'title': 'Musim Ketiga (2024)',
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
                // Header dengan tombol Sinkronisasi
                AppHeader(
                  showBack: true,
                  title: 'REKAP SEMUA MUSIM',
                  subtitle: 'ARSIP KEUANGAN // PERKEBUNAN',
                  padding: EdgeInsets.zero,
                  height: null,
                  trailing: AppHeaderActionButton(
                    icon: Icons.sync_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sinkronisasi data semua musim berhasil diperbarui!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Kartu Akumulasi Biaya Semua Musim
                _buildAccumulatedHeaderCard(),
                const SizedBox(height: 16),

                // 2. Daftar Riwayat Arsip Musim Tanam
                _buildSeasonHistorySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccumulatedHeaderCard() {
    return RetroCard(
      tapeTag: 'TOTAL AKUMULASI // 3 MUSIM TANAM',
      rightTag: 'ARSIP KAS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MicroText('TOTAL AKUMULASI BIAYA', fontSize: 9.5, color: AppColors.muted),
          const SizedBox(height: 4),
          Text(
            'Rp 38.500.000',
            style: AppTypography.display(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          const TaperedDivider(centerLabel: 'KATEGORI AKUMULASI'),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildSmallCategoryPill('Buruh & Petik', 'Rp 18.500.000', AppColors.forest),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSmallCategoryPill('Pupuk & Nutrisi', 'Rp 10.400.000', AppColors.limeDeep),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSmallCategoryPill('Bibit & Olah', 'Rp 6.500.000', AppColors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSmallCategoryPill('Lainnya/Alat', 'Rp 3.100.000', AppColors.ink),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCategoryPill(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MicroText(title, fontSize: 8.5, color: color, fontWeight: FontWeight.w800),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.mono(fontSize: 9.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildSeasonHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TaperedDivider(centerLabel: 'RIWAYAT MUSIM TANAM // ARSIP'),
        const SizedBox(height: 6),

        ..._seasonHistory.asMap().entries.map((entry) {
          final index = entry.key;
          final season = entry.value;

          return RetroCard(
            tapeTag: 'ARSIP TAHUNAN // REKAP',
            rightTag: season['status'] as String,
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      season['title'] as String,
                      style: AppTypography.display(fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                    const StatusChip(label: 'SELESAI', variant: StatusChipVariant.lime, fontSize: 8),
                  ],
                ),
                const SizedBox(height: 2),
                MicroText(season['period'] as String, fontSize: 9.5, color: AppColors.muted),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      season['expenses'] as String,
                      style: AppTypography.mono(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.red),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  ${season['harvest']}',
                      style: AppTypography.mono(fontSize: 11, color: AppColors.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: AppColors.ink, height: 1, thickness: 1),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildMiniActionBtn('DETAIL', Icons.visibility_outlined, AppColors.paper, () => _showSeasonDetail(season)),
                    const SizedBox(width: 6),
                    _buildMiniActionBtn('EDIT', Icons.edit_outlined, AppColors.lime, () => _applyAndReturnSeason(season)),
                    const SizedBox(width: 6),
                    _buildMiniActionBtn('HAPUS', Icons.delete_outline_rounded, const Color(0xFFFED7AA), () => _confirmDeleteSeason(index, season)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMiniActionBtn(String label, IconData icon, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.ink, width: 1.2),
          boxShadow: const [
            BoxShadow(color: AppColors.ink, offset: Offset(1.5, 1.5)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.ink),
            const SizedBox(width: 4),
            MicroText(label, fontSize: 8.5, color: AppColors.ink, fontWeight: FontWeight.w900),
          ],
        ),
      ),
    );
  }

  void _applyAndReturnSeason(Map<String, dynamic> season) {
    FinanceDataStore.activeSeasonData = season;
    final seasonNum = season['seasonNumber'] as int?;
    final rawTitle = season['title'] as String? ?? '';
    final lowerTitle = rawTitle.toLowerCase();

    if (seasonNum == 3 || lowerTitle.contains('ketiga') || lowerTitle.contains('musim 3')) {
      FinanceDataStore.activeSeasonTitle = 'Biaya & Pengeluaran Musim 3';
    } else if (seasonNum == 2 || lowerTitle.contains('kedua') || lowerTitle.contains('musim 2')) {
      FinanceDataStore.activeSeasonTitle = 'Biaya & Pengeluaran Musim 2';
    } else if (seasonNum == 1 || lowerTitle.contains('pertama') || lowerTitle.contains('kesatu') || lowerTitle.contains('musim 1')) {
      FinanceDataStore.activeSeasonTitle = 'Biaya & Pengeluaran Musim 1';
    } else if (rawTitle.isNotEmpty) {
      if (lowerTitle.startsWith('biaya & pengeluaran')) {
        FinanceDataStore.activeSeasonTitle = rawTitle;
      } else {
        FinanceDataStore.activeSeasonTitle = 'Biaya & Pengeluaran $rawTitle';
      }
    }
    if (season['expenses'] != null) {
      FinanceDataStore.activeTotalExpense = season['expenses'] as String;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context, season);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FinanceScreen(initialSeasonData: season),
        ),
      );
    }
  }

  void _showSeasonDetail(Map<String, dynamic> season) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      season['title'] as String,
                      style: AppTypography.display(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const StatusChip(label: 'ARSIP RESMI', variant: StatusChipVariant.lime),
                  ],
                ),
                const SizedBox(height: 4),
                MicroText(season['period'] as String, fontSize: 9.5, color: AppColors.muted),
                const SizedBox(height: 14),

                // 4 Kategori Rincian Biaya Musim (Format Baris Tanpa Persen)
                _buildDetailRow('Buruh & Petik:', (season['labor'] ?? 'Rp 6.840.000') as String),
                const SizedBox(height: 8),
                _buildDetailRow('Pupuk & Nutrisi:', (season['fertilizer'] ?? 'Rp 3.847.500') as String),
                const SizedBox(height: 8),
                _buildDetailRow('Bibit & Olah Lahan:', (season['seed'] ?? 'Rp 2.422.500') as String),
                const SizedBox(height: 8),
                _buildDetailRow('Lainnya / Tambahan:', (season['other'] ?? 'Rp 1.140.000') as String),
                const SizedBox(height: 10),
                Container(
                  height: 1.5,
                  color: AppColors.ink.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Total Pengeluaran:', season['expenses'] as String),
                const SizedBox(height: 18),
                TrapezoidTabButton(
                  label: 'TUTUP',
                  height: 42,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body(fontSize: 12)),
        Text(value, style: AppTypography.mono(fontSize: 12, fontWeight: FontWeight.w900)),
      ],
    );
  }

  void _confirmDeleteSeason(int index, Map<String, dynamic> season) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text('HAPUS ARSIP MUSIM', style: AppTypography.display(fontSize: 15, fontWeight: FontWeight.w900)),
        content: Text(
          'Apakah Anda yakin ingin menghapus data "${season['title']}"? Data riwayat musim ini akan dihapus permanen.',
          style: AppTypography.body(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('BATAL', style: AppTypography.mono(fontSize: 11, color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              final deletedTitle = season['title'];
              setState(() => _seasonHistory.removeAt(index));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Arsip "$deletedTitle" berhasil dihapus!')),
              );
            },
            child: Text('YA, HAPUS', style: AppTypography.mono(fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
