import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/retro/blade_ornament.dart';
import '../../widgets/retro/micro_text.dart';
import '../../widgets/retro/retro_card.dart';
import '../../widgets/retro/retro_frame.dart';
import '../../widgets/retro/status_chip.dart';
import '../../widgets/retro/trapezoid_tab_button.dart';
import 'harvest_screen.dart';

class HarvestAllMusimScreen extends StatefulWidget {
  const HarvestAllMusimScreen({super.key});

  @override
  State<HarvestAllMusimScreen> createState() => _HarvestAllMusimScreenState();
}

class _HarvestAllMusimScreenState extends State<HarvestAllMusimScreen> {
  // Data Riwayat Semua Musim Panen Tembakau (Keuntungan Mentah & Siklus 7 Petikan Daun)
  final List<Map<String, dynamic>> _seasonHistory = [
    {
      'title': 'Musim Ketiga (2024)',
      'period': 'Mei - Okt 2024 • Lahan Blok A & B',
      'weight': '3.200 kg tembakau',
      'revenue': 'Rp 88.500.000',
      'cycles': '7/7 Petikan Selesai',
      'status': 'Selesai',
      'stageDetails': [
        {'stage': 'P1', 'label': 'Daun Pasir (Bawah 1)', 'weight': '450 kg', 'revenue': 'Rp 11.250.000'},
        {'stage': 'P2', 'label': 'Daun Bawah 2', 'weight': '510 kg', 'revenue': 'Rp 12.750.000'},
        {'stage': 'P3', 'label': 'Daun Tengah Utama (Prima)', 'weight': '860 kg', 'revenue': 'Rp 27.520.000'},
        {'stage': 'P4', 'label': 'Daun Tengah 2', 'weight': '620 kg', 'revenue': 'Rp 18.600.000'},
        {'stage': 'P5', 'label': 'Daun Atas', 'weight': '420 kg', 'revenue': 'Rp 10.920.000'},
        {'stage': 'P6', 'label': 'Pucuk Daun', 'weight': '230 kg', 'revenue': 'Rp 5.290.000'},
        {'stage': 'P7', 'label': 'Pemetikan Akhir', 'weight': '110 kg', 'revenue': 'Rp 2.170.000'},
      ],
    },
    {
      'title': 'Musim Kedua (2023)',
      'period': 'Mei - Sep 2023 • Lahan Blok A',
      'weight': '2.850 kg tembakau',
      'revenue': 'Rp 78.000.000',
      'cycles': '7/7 Petikan Selesai',
      'status': 'Selesai',
      'stageDetails': [
        {'stage': 'P1', 'label': 'Daun Pasir (Bawah 1)', 'weight': '400 kg', 'revenue': 'Rp 9.600.000'},
        {'stage': 'P2', 'label': 'Daun Bawah 2', 'weight': '460 kg', 'revenue': 'Rp 11.500.000'},
        {'stage': 'P3', 'label': 'Daun Tengah Utama (Prima)', 'weight': '780 kg', 'revenue': 'Rp 24.180.000'},
        {'stage': 'P4', 'label': 'Daun Tengah 2', 'weight': '550 kg', 'revenue': 'Rp 16.500.000'},
        {'stage': 'P5', 'label': 'Daun Atas', 'weight': '380 kg', 'revenue': 'Rp 9.880.000'},
        {'stage': 'P6', 'label': 'Pucuk Daun', 'weight': '190 kg', 'revenue': 'Rp 4.370.000'},
        {'stage': 'P7', 'label': 'Pemetikan Akhir', 'weight': '90 kg', 'revenue': 'Rp 1.970.000'},
      ],
    },
    {
      'title': 'Musim Pertama (2022)',
      'period': 'Jun - Okt 2022 • Lahan Blok A',
      'weight': '2.600 kg tembakau',
      'revenue': 'Rp 68.600.000',
      'cycles': '7/7 Petikan Selesai',
      'status': 'Selesai',
      'stageDetails': [
        {'stage': 'P1', 'label': 'Daun Pasir (Bawah 1)', 'weight': '380 kg', 'revenue': 'Rp 8.740.000'},
        {'stage': 'P2', 'label': 'Daun Bawah 2', 'weight': '420 kg', 'revenue': 'Rp 10.080.000'},
        {'stage': 'P3', 'label': 'Daun Tengah Utama (Prima)', 'weight': '710 kg', 'revenue': 'Rp 21.300.000'},
        {'stage': 'P4', 'label': 'Daun Tengah 2', 'weight': '500 kg', 'revenue': 'Rp 14.500.000'},
        {'stage': 'P5', 'label': 'Daun Atas', 'weight': '350 kg', 'revenue': 'Rp 8.750.000'},
        {'stage': 'P6', 'label': 'Pucuk Daun', 'weight': '160 kg', 'revenue': 'Rp 3.520.000'},
        {'stage': 'P7', 'label': 'Pemetikan Akhir', 'weight': '80 kg', 'revenue': 'Rp 1.710.000'},
      ],
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
                  subtitle: 'SIKLUS PANEN // TEMBAKAU',
                  padding: EdgeInsets.zero,
                  height: null,
                  trailing: AppHeaderActionButton(
                    icon: Icons.sync_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sinkronisasi data panen semua musim berhasil diperbarui!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Header Akumulasi Panen Semua Musim
                _buildAccumulatedHeaderCard(),
                const SizedBox(height: 16),

                // 2. Daftar Riwayat Arsip Musim Panen
                _buildSeasonHistorySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Header Akumulasi Panen Semua Musim
  Widget _buildAccumulatedHeaderCard() {
    return RetroCard(
      tapeTag: 'TOTAL AKUMULASI // REKAP PANEN',
      rightTag: '3 MUSIM SELESAI',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.ink, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.agriculture_rounded, size: 12, color: AppColors.ink),
                      const SizedBox(width: 4),
                      Flexible(
                        child: MicroText.bold(
                          'TOTAL AKUMULASI PANEN',
                          color: AppColors.ink,
                          size: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip.dark('3 MUSIM SELESAI'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '8.650 kg',
            style: AppTypography.display(
              size: 34,
              weight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lime.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.ink, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_outlined, size: 16, color: AppColors.ink),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Total Keuntungan Kotor Mentah: Rp 235.100.000',
                    style: AppTypography.mono(
                      size: 11.5,
                      weight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          MicroText.regular(
            'Akumulasi dari 21 kali siklus pemetikan daun tembakau (7 petikan per musim tanam).',
            color: AppColors.ink.withValues(alpha: 0.7),
            size: 10.5,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat Musim Panen',
                    style: AppTypography.display(
                      size: 16,
                      weight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  MicroText.regular(
                    'Catatan 7 siklus petikan daun tembakau tiap musim',
                    color: AppColors.ink.withValues(alpha: 0.65),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip.lime('7 PETIKAN / MUSIM'),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _seasonHistory.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final season = _seasonHistory[index];
            return RetroCard(
              tapeTag: season['title'] as String,
              rightTag: season['status'] as String,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          season['title'] as String,
                          style: AppTypography.display(
                            size: 15,
                            weight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.lime,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.ink, width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.ink),
                            const SizedBox(width: 4),
                            MicroText.bold(
                              season['status'] as String,
                              size: 9.5,
                              color: AppColors.ink,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  MicroText.regular(
                    season['period'] as String,
                    color: AppColors.ink.withValues(alpha: 0.65),
                    size: 10.5,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(
                              season['revenue'] as String,
                              style: AppTypography.mono(
                                size: 14,
                                weight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              '• ${season['weight']}',
                              style: AppTypography.mono(
                                size: 12,
                                weight: FontWeight.w700,
                                color: AppColors.ink.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip.dark(season['cycles'] as String),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const TaperedDivider(),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildMiniActionBtn(
                          'DETAIL',
                          Icons.visibility_outlined,
                          AppColors.paper,
                          () => _showSeasonDetail(season),
                        ),
                        _buildMiniActionBtn(
                          'EDIT',
                          Icons.edit_outlined,
                          AppColors.lime,
                          () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const HarvestScreen()),
                              );
                            }
                          },
                        ),
                        _buildMiniActionBtn(
                          'HAPUS',
                          Icons.delete_outline_rounded,
                          const Color(0xFFFED7AA),
                          () => _confirmDeleteSeason(index, season),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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

  void _showSeasonDetail(Map<String, dynamic> season) {
    final stages = (season['stageDetails'] as List<dynamic>?) ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                // Top Grab Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        season['title'] as String,
                        style: AppTypography.display(
                          size: 18,
                          weight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip.lime('7 PETIKAN LENGKAP'),
                  ],
                ),
                const SizedBox(height: 4),
                MicroText.regular(
                  season['period'] as String,
                  color: AppColors.ink.withValues(alpha: 0.65),
                ),
                const SizedBox(height: 14),
                const TaperedDivider(),
                const SizedBox(height: 14),
                _buildDetailRow('Total Hasil Bobot Panen', season['weight'] as String, isBold: true),
                const SizedBox(height: 8),
                _buildDetailRow('Total Pendapatan Kotor Mentah', season['revenue'] as String, isBold: true, valueColor: AppColors.limeDeep),
                const SizedBox(height: 8),
                _buildDetailRow('Siklus Tembakau', '7 Petikan Daun (P1 s/d P7) Selesai'),
                const SizedBox(height: 14),
                const TaperedDivider(),
                const SizedBox(height: 14),
                Text(
                  'Rincian 7 Tahap Siklus Petikan Daun:',
                  style: AppTypography.display(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                ...stages.map((stg) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.ink, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: AppColors.ink, offset: Offset(1.5, 1.5)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.ink, width: 1),
                          ),
                          child: Text(
                            stg['stage'] as String,
                            style: AppTypography.mono(
                              size: 11,
                              weight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            stg['label'] as String,
                            style: AppTypography.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              stg['weight'] as String,
                              style: AppTypography.mono(
                                size: 12,
                                weight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              stg['revenue'] as String,
                              style: AppTypography.mono(
                                size: 10,
                                color: AppColors.ink.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 18),
                TrapezoidTabButton(
                  label: '----TUTUP DETAIL----',
                  color: AppColors.ink,
                  textColor: Colors.white,
                  height: 44,
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTypography.mono(
              size: 12,
              color: AppColors.ink.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          textAlign: TextAlign.right,
          style: AppTypography.mono(
            size: 12.5,
            weight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.ink,
          ),
        ),
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
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.red),
            const SizedBox(width: 8),
            Text(
              'Hapus Arsip Panen',
              style: AppTypography.display(
                size: 17,
                weight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus data panen "${season['title']}"? Seluruh riwayat timbangan 7 siklus petikan akan dihapus.',
          style: AppTypography.body(
            size: 13,
            color: AppColors.ink,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: AppTypography.mono(
                size: 12,
                weight: FontWeight.w700,
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: AppColors.ink, width: 1.5),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final deletedTitle = season['title'];
              setState(() => _seasonHistory.removeAt(index));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Data "$deletedTitle" berhasil dihapus!',
                    style: AppTypography.mono(size: 12, color: Colors.white),
                  ),
                  backgroundColor: AppColors.ink,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Ya, Hapus',
              style: AppTypography.mono(size: 12, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
